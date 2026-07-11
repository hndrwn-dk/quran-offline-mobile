import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_links.dart';

void main() {
  group('AppLinks.shareAppMessage', () {    test('includes Play Store URL for Indonesian', () {
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

  test('donateUrl points to Ko-fi profile', () {
    expect(AppLinks.donateUrl, 'https://ko-fi.com/hendrawandaryonokarso');
    expect(AppLinks.donateUrl, isNot(contains('buymeacoffee')));
  });

  group('AppLinks.ramadanTrackerPlayStoreForLocale', () {
    test('includes Ramadan Tracker package id', () {
      final url = AppLinks.ramadanTrackerPlayStoreForLocale('id');
      expect(url, contains(AppLinks.ramadanTrackerPackageId));
      expect(url, contains('hl=id'));
    });

    test('uses English locale hint for en', () {
      final url = AppLinks.ramadanTrackerPlayStoreForLocale('en');
      expect(url, contains('hl=en'));
    });
  });

  group('AppLinks.ramadanTrackerMarketUrl', () {
    test('uses market scheme with package id', () {
      final url = AppLinks.ramadanTrackerMarketUrl();
      expect(url, startsWith('market://'));
      expect(url, contains(AppLinks.ramadanTrackerPackageId));
    });
  });
}
