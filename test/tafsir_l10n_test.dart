import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

void main() {
  test('getTafsirRevelationLabel localizes Makkiyah and Madaniyah', () {
    expect(
      AppLocalizations.getTafsirRevelationLabel('id', 'Makkiyah'),
      'Makkiyah',
    );
    expect(
      AppLocalizations.getTafsirRevelationLabel('zh', 'Madaniyah'),
      '麦地那章',
    );
    expect(
      AppLocalizations.getTafsirRevelationLabel('ja', 'Makkiyah'),
      'マッカ啓示',
    );
  });
}
