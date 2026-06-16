import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';

void main() {
  test('containsArabic detects Arabic script', () {
    expect(ArabicSearchNormalizer.containsArabic('الرحمن'), isTrue);
    expect(ArabicSearchNormalizer.containsArabic('sabar'), isFalse);
  });

  test('normalizeForSearch strips diacritics and matches plain input', () {
    const withHarakat = 'بِسْمِ اللَّهِ الرَّحْمَنِ';
    const query = 'الرحمن';
    expect(
      ArabicSearchNormalizer.normalizeForSearch(withHarakat),
      contains(ArabicSearchNormalizer.normalizeForSearch(query)),
    );
  });

  test('normalizeForSearch unifies alef variants', () {
    expect(
      ArabicSearchNormalizer.normalizeForSearch('ٱلله'),
      contains('الله'),
    );
  });
}
