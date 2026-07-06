import 'package:quran_offline/core/utils/coachmark_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key set for a coachmark context (e.g. support, Ramadan).
class CoachmarkStorageKeys {
  const CoachmarkStorageKeys({required this.prefix});

  final String prefix;

  String get showCount => '${prefix}_show_count';
  String get lastShownAt => '${prefix}_last_shown_at';
  String get hasTappedCta => '${prefix}_has_tapped_cta';
}

/// Default keys for the Beranda support / Ko-fi coachmark.
class SupportCoachmarkKeys {
  SupportCoachmarkKeys._();

  static const storage = CoachmarkStorageKeys(prefix: 'support_coachmark');
  static const legacySeenKey = 'has_seen_support_coachmark';
}

/// Staged reminder logic for the support coachmark.
class SupportCoachmarkService {
  SupportCoachmarkService({
    this.keys = SupportCoachmarkKeys.storage,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CoachmarkStorageKeys keys;
  final DateTime Function() _now;

  static const int firstShowMinOpens = CoachmarkPrefs.supportCoachmarkMinOpens;
  static const int maxShowCount = 3;
  static const Duration reminder2AfterFirst = Duration(days: 7);
  static const Duration reminder3AfterSecond = Duration(days: 14);

  /// Pure predicate — used by [shouldShow] and unit tests.
  static bool shouldShowCoachmark({
    required bool hasTappedSupportCta,
    required int coachmarkShowCount,
    required int appOpenCount,
    required int? lastCoachmarkShownAtMs,
    required DateTime now,
  }) {
    if (hasTappedSupportCta) return false;
    if (coachmarkShowCount >= maxShowCount) return false;

    switch (coachmarkShowCount) {
      case 0:
        return appOpenCount >= firstShowMinOpens;
      case 1:
        if (lastCoachmarkShownAtMs == null) return false;
        final lastShown = DateTime.fromMillisecondsSinceEpoch(
          lastCoachmarkShownAtMs,
        );
        return now.difference(lastShown) >= reminder2AfterFirst;
      case 2:
        if (lastCoachmarkShownAtMs == null) return false;
        final lastShown = DateTime.fromMillisecondsSinceEpoch(
          lastCoachmarkShownAtMs,
        );
        return now.difference(lastShown) >= reminder3AfterSecond;
      default:
        return false;
    }
  }

  Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);

    final state = _readState(prefs);
    final appOpenCount = await CoachmarkPrefs.getAppOpenCount();

    return shouldShowCoachmark(
      hasTappedSupportCta: state.hasTappedSupportCta,
      coachmarkShowCount: state.coachmarkShowCount,
      appOpenCount: appOpenCount,
      lastCoachmarkShownAtMs: state.lastCoachmarkShownAtMs,
      now: _now(),
    );
  }

  /// Call when the tooltip is displayed to the user.
  Future<void> recordShown() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);

    final current = prefs.getInt(keys.showCount) ?? 0;
    await prefs.setInt(keys.showCount, current + 1);
    await prefs.setInt(keys.lastShownAt, _now().millisecondsSinceEpoch);
  }

  /// Call when the user taps the CTA ("Lihat →") — stops all future reminders.
  Future<void> recordCtaTapped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keys.hasTappedCta, true);
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    if (!prefs.containsKey(SupportCoachmarkKeys.legacySeenKey)) return;

    final seen = prefs.getBool(SupportCoachmarkKeys.legacySeenKey) ?? false;
    if (seen && (prefs.getInt(keys.showCount) ?? 0) == 0) {
      await prefs.setInt(keys.showCount, maxShowCount);
    }
    await prefs.remove(SupportCoachmarkKeys.legacySeenKey);
  }

  _CoachmarkState _readState(SharedPreferences prefs) {
    return _CoachmarkState(
      coachmarkShowCount: prefs.getInt(keys.showCount) ?? 0,
      lastCoachmarkShownAtMs: prefs.getInt(keys.lastShownAt),
      hasTappedSupportCta: prefs.getBool(keys.hasTappedCta) ?? false,
    );
  }
}

class _CoachmarkState {
  const _CoachmarkState({
    required this.coachmarkShowCount,
    required this.lastCoachmarkShownAtMs,
    required this.hasTappedSupportCta,
  });

  final int coachmarkShowCount;
  final int? lastCoachmarkShownAtMs;
  final bool hasTappedSupportCta;
}
