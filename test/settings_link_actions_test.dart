import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/features/settings/settings_link_actions.dart';

void main() {
  test('Privacy and Terms point to the Quran Offline pages', () {
    expect(
      SettingsLinkActions.privacyUrl,
      'https://www.tursinalabs.com/quranoffline/privacy',
    );
    expect(
      SettingsLinkActions.termsUrl,
      'https://www.tursinalabs.com/quranoffline/terms',
    );
  });
}
