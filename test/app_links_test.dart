import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_links.dart';

void main() {
  group('AppLinks.shareAppMessage', () {
    test('includes Play Store URL for Indonesian', () {
      final message = AppLinks.shareAppMessage('id');
      expect(message, contains('Quran Offline'));
      expect(message, contains('play.google.com'));
      expect(message, contains('hl=id'));
    });

    test('uses English copy for en locale', () {
      final message = AppLinks.shareAppMessage('en');
      expect(message, contains('Quran Offline'));
      expect(message, contains('hl=en'));
    });
  });
}
