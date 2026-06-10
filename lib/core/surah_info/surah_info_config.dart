/// Bundled QUL surah info SQLite files (read-only at runtime).
abstract final class SurahInfoConfig {
  static const bundleVersion = 1;

  static const assetByLanguage = <String, String>{
    'en': 'assets/quran/surah_info/en_surah_info.sqlite',
    'id': 'assets/quran/surah_info/id_surah_info.sqlite',
  };

  static String? assetPathForLanguage(String qulLanguage) {
    return assetByLanguage[qulLanguage];
  }

  static String fileNameForLanguage(String qulLanguage) {
    final path = assetPathForLanguage(qulLanguage);
    if (path == null) return '';
    return path.split('/').last;
  }
}
