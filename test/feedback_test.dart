import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/feedback/app_feedback_content.dart';
import 'package:quran_offline/core/feedback/feedback_context.dart';
import 'package:quran_offline/core/feedback/feedback_email_fallback.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';

void main() {
  group('AppFeedbackContent', () {
    test('buildMetadata includes verse context when provided', () {
      final metadata = AppFeedbackContent.buildMetadata(
        language: 'en',
        context: const FeedbackContext(
          surahId: 56,
          ayahNo: 91,
          arabicSnippet: 'test arabic',
        ),
      );

      expect(metadata['language'], 'en');
      expect(metadata['surahId'], 56);
      expect(metadata['ayahNo'], 91);
      expect(metadata['arabicSnippet'], 'test arabic');
      expect(metadata['appVersion'], isNotEmpty);
      expect(metadata['dataVersion'], isNotEmpty);
    });

    test('buildDescriptionWithContext includes quran.com reference', () {
      final body = AppFeedbackContent.buildDescriptionWithContext(
        language: 'en',
        userDescription: 'Wrong color on this verse',
        context: const FeedbackContext(surahId: 56, ayahNo: 91),
      );

      expect(body, contains('Wrong color on this verse'));
      expect(body, contains('QS 56:91'));
      expect(body, contains('https://quran.com/56/91'));
    });
  });

  group('FeedbackEmailFallback', () {
    test('buildMailtoUri includes verse subject for bug reports', () {
      final uri = FeedbackEmailFallback.buildMailtoUri(
        type: FeedbackType.bug,
        language: 'en',
        title: 'Tajweed color wrong',
        description: 'Letter alif is red instead of green',
        context: const FeedbackContext(surahId: 56, ayahNo: 91),
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, FeedbackEmailFallback.supportEmail);
      expect(uri.queryParameters['subject'], contains('56'));
      expect(uri.queryParameters['subject'], contains('91'));
      expect(uri.queryParameters['body'], contains('Tajweed color wrong'));
      expect(uri.queryParameters['body'], contains('https://quran.com/56/91'));
    });

    test('buildMailtoUri works for feature requests without verse', () {
      final uri = FeedbackEmailFallback.buildMailtoUri(
        type: FeedbackType.feature,
        language: 'id',
        title: 'Mode malam Mushaf',
        description: 'Mohon tambahkan mode gelap khusus Mushaf',
      );

      expect(uri.queryParameters['subject'], contains('Usulan fitur'));
      expect(uri.queryParameters['body'], contains('Mode malam Mushaf'));
    });

    test('ayahFromLastRead resolves surah positions', () {
      final pos = LastReadPosition(
        type: 'surah',
        id: 2,
        ayahNo: 255,
        timestamp: DateTime.utc(2026, 1, 1),
      );

      final ayah = FeedbackEmailFallback.ayahFromLastRead(pos);
      expect(ayah?.surahId, 2);
      expect(ayah?.ayahNo, 255);
    });
  });
}
