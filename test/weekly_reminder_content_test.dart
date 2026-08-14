import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/notifications/notification_payload.dart';
import 'package:quran_offline/core/notifications/weekly_reminder_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('buildWeeklyReminderContent', () {
    test('uses continue-reading copy regardless of weekly reading state', () {
      final unread = buildWeeklyReminderContent(language: 'id');
      final read = buildWeeklyReminderContent(language: 'id');
      expect(unread.payload, NotificationPayload.continueReading);
      expect(read.payload, NotificationPayload.continueReading);
      expect(unread.title, read.title);
      expect(unread.body, read.body);
      expect(unread.title, isNotEmpty);
      expect(unread.body, isNotEmpty);
    });

    test('english copy is the continue prompt not the already-read Friday copy', () {
      final content = buildWeeklyReminderContent(language: 'en');
      expect(content.payload, NotificationPayload.continueReading);
      expect(content.title, contains('read the Qur\'an this week'));
      expect(content.body, contains('continue from where you left off'));
    });
  });

  group('readWeeklyReminderSchedule', () {
    test('reads enabled schedule from prefs for post-upgrade reschedule', () async {
      SharedPreferences.setMockInitialValues({
        'weeklyReminderEnabled': true,
        'weeklyReminderHour': 16,
        'weeklyReminderMinute': 0,
        'appLanguage': 'id',
      });
      final prefs = await SharedPreferences.getInstance();
      final schedule = readWeeklyReminderSchedule(prefs);
      expect(schedule.enabled, isTrue);
      expect(schedule.hour, 16);
      expect(schedule.minute, 0);
      expect(schedule.language, 'id');
    });

    test('defaults to disabled when prefs are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final schedule = readWeeklyReminderSchedule(prefs);
      expect(schedule.enabled, isFalse);
      expect(schedule.hour, 15);
      expect(schedule.minute, 30);
      expect(schedule.language, 'en');
    });
  });

  group('nextFridayAt', () {
    test('returns same day if from is before Friday slot', () {
      final from = DateTime(2026, 7, 3, 10, 0);
      final next = nextFridayAt(from: from, hour: 15, minute: 30);
      expect(next.weekday, DateTime.friday);
      expect(next.hour, 15);
      expect(next.minute, 30);
      expect(next.day, 3);
    });

    test('skips to next Friday if slot already passed', () {
      final from = DateTime(2026, 7, 3, 16, 0);
      final next = nextFridayAt(from: from, hour: 15, minute: 30);
      expect(next.weekday, DateTime.friday);
      expect(next.day, 10);
    });
  });
}
