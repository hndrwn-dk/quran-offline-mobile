/// Bundled QPC V2 Mushaf assets (QUL #249 font, #61 script, V2 15-line layout).
class QpcV2Assets {
  QpcV2Assets._();

  static const layoutSqlite = 'assets/mushaf/layout/qpc_v2_15_lines.sqlite';

  static const wordsSqlite = 'assets/mushaf/script/qpc_v2_words.sqlite';

  /// Word IDs 1–4 are Bismillah glyphs (standalone, no ayah marker).
  static const bismillahFirstWordId = 1;
  static const bismillahStandaloneLastWordId = 4;

  static String pageFontAssetPath(int pageNumber) =>
      'assets/fonts/qpc_v2/p$pageNumber.ttf';

  static const pageFontFamilyPrefix = 'QpcV2Page';
}
