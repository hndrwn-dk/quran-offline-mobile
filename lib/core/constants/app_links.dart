/// Public URLs for Quran Offline (share, marketing).
class AppLinks {
  AppLinks._();

  static const String _playStorePackageId = 'com.tursinalabs.quranoffline';

  static const String productPage =
      'https://www.tursinalabs.com/products/quranoffline';

  /// Play Store listing with store UI language from app/translation locale.
  /// Note: `id=` is the Android package name, not Indonesian — use `hl=` for locale.
  static String playStoreForLocale(String locale) {
    final hl = _playStoreHl(locale);
    return 'https://play.google.com/store/apps/details?id=$_playStorePackageId&hl=$hl';
  }

  /// Compact URL line printed on share PNG footers.
  static String playStoreDisplayForLocale(String locale) {
    final hl = _playStoreHl(locale);
    return 'play.google.com/store/apps/details?id=$_playStorePackageId&hl=$hl';
  }

  static String _playStoreHl(String locale) {
    return switch (locale) {
      'id' => 'id',
      'en' => 'en',
      'ja' => 'ja',
      'zh' => 'zh',
      _ => 'en',
    };
  }
}
