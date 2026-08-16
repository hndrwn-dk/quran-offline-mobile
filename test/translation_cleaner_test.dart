import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';

void main() {
  test('strips Quran.com API v4 unquoted foot_note superscript tags', () {
    const dirty =
        'In the name of Allāh,<sup foot_note=195932>1</sup> the Entirely Merciful, the Especially Merciful.<sup foot_note=195931>2</sup>';

    final cleaned = TranslationCleaner.clean(dirty);

    expect(cleaned, isNot(contains('<sup')));
    expect(cleaned, isNot(contains('foot_note')));
    expect(cleaned, isNot(contains('</sup>')));
    expect(
      cleaned,
      'In the name of Allāh, the Entirely Merciful, the Especially Merciful.',
    );
  });

  test('strips quoted foot_note attributes', () {
    const dirty =
        'Sovereign of the Day of Recompense.<sup foot_note="195934">1</sup>';

    expect(
      TranslationCleaner.clean(dirty),
      'Sovereign of the Day of Recompense.',
    );
  });

  test('strips footnote attribute spelling and leftover spaces', () {
    const dirty = 'Lord<sup footnote=195933>1</sup> of the worlds';

    expect(TranslationCleaner.clean(dirty), 'Lord of the worlds');
  });
}
