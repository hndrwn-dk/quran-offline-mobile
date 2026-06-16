/// Bundled QPC V4 Tajweed Mushaf assets (QUL #240 font, #47 script, V4 layout).
class QpcV4Assets {
  QpcV4Assets._();

  static const layoutSqlite =
      'assets/mushaf/layout/qpc_v4_tajweed_15_lines.sqlite';

  static const wordsSqlite =
      'assets/mushaf/script/qpc_v4_tajweed_words.sqlite';

  /// Per-page glyph font, e.g. [pageFontAssetPath](50) → `.../p50.ttf`.
  static String pageFontAssetPath(int pageNumber) =>
      'assets/fonts/qpc_v4_tajweed/p$pageNumber.ttf';

  static const pageFontFamilyPrefix = 'QpcV4Page';
}
