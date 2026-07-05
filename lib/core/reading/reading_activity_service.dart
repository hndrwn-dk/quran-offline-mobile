import 'package:quran_offline/core/reading/reading_activity_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists scroll-based reading days for weekly reminder logic.
class ReadingActivityService {
  ReadingActivityService(this._prefs);

  static const _storageKey = 'reading_activity_dates';

  final SharedPreferences _prefs;

  static Future<ReadingActivityService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ReadingActivityService(prefs);
  }

  List<String> get activityDates {
    return _prefs.getStringList(_storageKey) ?? const [];
  }

  bool hasReadThisWeek({DateTime? reference}) {
    return hasReadInIsoWeek(activityDates, reference ?? DateTime.now());
  }

  Future<void> logReadingDay([DateTime? when]) async {
    final updated = addActivityDate(activityDates, when ?? DateTime.now());
    await _prefs.setStringList(_storageKey, updated);
  }
}

/// Logs a reading day without blocking the caller.
Future<void> logReadingActivityDay() async {
  try {
    final service = await ReadingActivityService.create();
    await service.logReadingDay();
    await WeeklyReminderCoordinator.rescheduleFromActivity?.call();
  } catch (_) {
    // Non-critical; reading position still saved elsewhere.
  }
}

// Forward declaration resolved when weekly_reminder_service is loaded.
abstract final class WeeklyReminderCoordinator {
  static Future<void> Function()? rescheduleFromActivity;
}
