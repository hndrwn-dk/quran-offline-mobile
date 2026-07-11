/// Public URLs for Quran Offline (share, marketing).
class AppLinks {
  AppLinks._();

  static const String _playStorePackageId = 'com.tursinalabs.quranoffline';

  /// Sister app — must match Play Store / installed package on device.
  static const String ramadanTrackerPackageId = 'com.tursinalabs.ramadan.tracker';

  static const String ramadanTrackerDeepLink = 'ramadantracker://open';

  static const String productPage =
      'https://www.tursinalabs.com/products/quranoffline';

  static const String donateUrl = 'https://ko-fi.com/hendrawandaryonokarso';

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

  /// Ramadan Tracker sister app — Play Store listing with locale hint.
  static String ramadanTrackerPlayStoreForLocale(String locale) {
    final hl = _playStoreHl(locale);
    return 'https://play.google.com/store/apps/details?id=$ramadanTrackerPackageId&hl=$hl';
  }

  /// Play Store app deep link (Android); falls back to [ramadanTrackerPlayStoreForLocale].
  static String ramadanTrackerMarketUrl() =>
      'market://details?id=$ramadanTrackerPackageId';

  static String _playStoreHl(String locale) {
    return switch (locale) {
      'id' => 'id',
      'en' => 'en',
      'ja' => 'ja',
      'zh' => 'zh',
      _ => 'en',
    };
  }

  /// Localized one-line invite + Play Store URL for [Share.share].
  static String shareAppMessage(String appLanguage) {
    final url = playStoreForLocale(appLanguage);
    return switch (appLanguage) {
      'id' =>
        'Coba Quran Offline — Al-Qur\'an offline, gratis, tanpa iklan.\n$url',
      'zh' => '试试 Quran Offline — 离线古兰经，免费、无广告。\n$url',
      'ja' => 'Quran Offline を試してみてください — オフライン、無料、広告なし。\n$url',
      _ => 'Try Quran Offline — offline Qur\'an, free, no ads.\n$url',
    };
  }
}
