/// Bundled QUL tafsir SQLite files (read-only at runtime).
abstract final class TafsirConfig {
  static const bundleVersion = 1;

  static const assetByLanguage = <String, String>{
    'id': 'assets/tafsir/id_as_saadi.sqlite',
    'en': 'assets/tafsir/en_ibn_kathir.sqlite',
    'zh': 'assets/tafsir/zh_mokhtasar.sqlite',
    'ja': 'assets/tafsir/ja_mokhtasar.sqlite',
  };

  static String? assetPathForLanguage(String translationLanguage) {
    return assetByLanguage[translationLanguage];
  }

  static String fileNameForLanguage(String translationLanguage) {
    final path = assetPathForLanguage(translationLanguage);
    if (path == null) return '';
    return path.split('/').last;
  }
}
