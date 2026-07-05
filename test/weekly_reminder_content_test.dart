import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/notifications/notification_payload.dart';
import 'package:quran_offline/core/notifications/weekly_reminder_content.dart';

void main() {
  group('buildWeeklyReminderContent', () {
    test('not read uses continue reading payload', () {
      final content = buildWeeklyReminderContent(
        language: 'id',
        hasReadThisWeek: false,
      );
      expect(content.payload, NotificationPayload.continueReading);
      expect(content.title, isNotEmpty);
      expect(content.body, isNotEmpty);
    });

    test('read uses beranda payload', () {
      final content = buildWeeklyReminderContent(
        language: 'en',
        hasReadThisWeek: true,
      );
      expect(content.payload, NotificationPayload.beranda);
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
