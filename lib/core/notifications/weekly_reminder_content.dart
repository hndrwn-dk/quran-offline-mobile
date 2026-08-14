import 'package:quran_offline/core/notifications/notification_payload.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeeklyReminderNotificationContent {
  const WeeklyReminderNotificationContent({
    required this.title,
    required this.body,
    required this.payload,
  });

  final String title;
  final String body;
  final String payload;
}

WeeklyReminderNotificationContent buildWeeklyReminderContent({
  required String language,
}) {
  return WeeklyReminderNotificationContent(
    title: AppLocalizations.getWeeklyReminderNotifTitleNotRead(language),
    body: AppLocalizations.getWeeklyReminderNotifBodyNotRead(language),
    payload: NotificationPayload.continueReading,
  );
}

({bool enabled, int hour, int minute, String language}) readWeeklyReminderSchedule(
  SharedPreferences prefs,
) {
  return (
    enabled: prefs.getBool('weeklyReminderEnabled') ?? false,
    hour: prefs.getInt('weeklyReminderHour') ?? 15,
    minute: prefs.getInt('weeklyReminderMinute') ?? 30,
    language: prefs.getString('appLanguage') ?? prefs.getString('language') ?? 'en',
  );
}

/// Next Friday at [hour]:[minute] local time strictly after [from].
DateTime nextFridayAt({
  required DateTime from,
  required int hour,
  required int minute,
}) {
  final today = DateTime(from.year, from.month, from.day);
  final daysUntilFriday = (DateTime.friday - today.weekday + 7) % 7;
  var candidate = DateTime(
    today.year,
    today.month,
    today.day + daysUntilFriday,
    hour,
    minute,
  );
  if (!candidate.isAfter(from)) {
    candidate = candidate.add(const Duration(days: 7));
  }
  return candidate;
}
