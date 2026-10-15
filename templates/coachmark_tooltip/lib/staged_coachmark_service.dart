import 'package:shared_preferences/shared_preferences.dart';

import 'app_open_counter.dart';
import 'coachmark_storage_keys.dart';

/// Thresholds for a staged coachmark (first show + timed reminders + hard stop).
class CoachmarkConfig {
  const CoachmarkConfig({
    required this.keys,
    required this.firstShowMinAppOpens,
    required this.maxShowCount,
    required this.reminderDelays,
  });

  final CoachmarkStorageKeys keys;

  /// First display requires at least this many cold starts (e.g. 3 = not first launch).
  final int firstShowMinAppOpens;

  /// Stop forever after this many displays (e.g. 3 = show at most 3 times).
  final int maxShowCount;

  /// Delays after each prior show before the next reminder.
  /// Length is typically `maxShowCount - 1`.
  /// Example: [7 days, 14 days] → 2nd show after 7d, 3rd after 14d.
  final List<Duration> reminderDelays;
}

/// Decides when to show a staged coachmark and persists show / CTA state.
class StagedCoachmarkService {
  StagedCoachmarkService({
    required this.config,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CoachmarkConfig config;
  final DateTime Function() _now;

  /// Pure predicate — easy to unit test without SharedPreferences.
  static bool shouldShowCoachmark({
    required CoachmarkConfig config,
    required bool hasTappedCta,
    required int showCount,
    required int appOpenCount,
    required int? lastShownAtMs,
    required DateTime now,
  }) {
    if (hasTappedCta) return false;
    if (showCount >= config.maxShowCount) return false;

    if (showCount == 0) {
      return appOpenCount >= config.firstShowMinAppOpens;
    }

    final delayIndex = showCount - 1;
    if (delayIndex >= config.reminderDelays.length) return false;
    if (lastShownAtMs == null) return false;

    final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownAtMs);
    return now.difference(lastShown) >= config.reminderDelays[delayIndex];
  }

  Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final state = _readState(prefs);
    final appOpenCount = await AppOpenCounter.get();

    return shouldShowCoachmark(
      config: config,
      hasTappedCta: state.hasTappedCta,
      showCount: state.showCount,
      appOpenCount: appOpenCount,
      lastShownAtMs: state.lastShownAtMs,
      now: _now(),
    );
  }

  /// Call when the tooltip is actually displayed (before or as overlay opens).
  Future<void> recordShown() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(config.keys.showCount) ?? 0;
    await prefs.setInt(config.keys.showCount, current + 1);
    await prefs.setInt(config.keys.lastShownAt, _now().millisecondsSinceEpoch);
  }

  /// Call when user taps the primary CTA — stops all future reminders.
  Future<void> recordCtaTapped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(config.keys.hasTappedCta, true);
  }

  _CoachmarkState _readState(SharedPreferences prefs) {
    return _CoachmarkState(
      showCount: prefs.getInt(config.keys.showCount) ?? 0,
      lastShownAtMs: prefs.getInt(config.keys.lastShownAt),
      hasTappedCta: prefs.getBool(config.keys.hasTappedCta) ?? false,
    );
  }
}

class _CoachmarkState {
  const _CoachmarkState({
    required this.showCount,
    required this.lastShownAtMs,
    required this.hasTappedCta,
  });

  final int showCount;
  final int? lastShownAtMs;
  final bool hasTappedCta;
}
