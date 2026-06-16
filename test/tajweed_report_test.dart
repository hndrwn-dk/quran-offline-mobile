import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_report.dart';

void main() {
  group('TajweedReport', () {
    test('buildMailtoUri includes verse and quran.com reference', () {
      final uri = TajweedReport.buildMailtoUri(
        language: 'en',
        surahId: 56,
        ayahNo: 91,
        arabicSnippet: 'test arabic',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, TajweedReport.supportEmail);
      expect(uri.queryParameters['subject'], contains('56'));
      expect(uri.queryParameters['subject'], contains('91'));
      expect(uri.queryParameters['body'], contains('https://quran.com/56/91'));
      expect(uri.queryParameters['body'], contains('test arabic'));
    });

    test('buildMailtoUri works without verse context', () {
      final uri = TajweedReport.buildMailtoUri(language: 'id');

      expect(uri.queryParameters['subject'], contains('Quran Offline'));
      expect(uri.queryParameters['body'], contains('56:91'));
    });
  });
}
