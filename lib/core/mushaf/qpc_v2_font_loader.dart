import 'package:flutter/services.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_assets.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';

/// Loads per-page QPC V2 TTF assets at runtime.
class QpcV2FontLoader {
  QpcV2FontLoader._();

  static const _maxCachedFonts = 24;

  static final Map<int, String> _loadedFamilies = {};
  static final Map<int, Future<String>> _loading = {};
  static final List<int> _lruOrder = [];

  static String familyForPage(int pageNumber) =>
      '${QpcV2Assets.pageFontFamilyPrefix}$pageNumber';

  static Future<String> ensurePageFontLoaded(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604, 'pageNumber');
    }
    final cached = _loadedFamilies[pageNumber];
    if (cached != null) {
      _touchLru(pageNumber);
      return Future.value(cached);
    }

    return _loading.putIfAbsent(pageNumber, () async {
      final family = familyForPage(pageNumber);
      final data = await rootBundle.load(
        QpcV2Assets.pageFontAssetPath(pageNumber),
      );
      final loader = FontLoader(family);
      loader.addFont(Future.value(data));
      await loader.load();
      _loadedFamilies[pageNumber] = family;
      _loading.remove(pageNumber);
      _touchLru(pageNumber);
      return family;
    });
  }

  /// Prefetch fonts for nearby pages without blocking the visible page.
  static void prefetchPages(Iterable<int> pageNumbers) {
    for (final page in pageNumbers) {
      if (page < 1 || page > 604) continue;
      if (_loadedFamilies.containsKey(page) || _loading.containsKey(page)) {
        continue;
      }
      ensurePageFontLoaded(page);
    }
  }

  static void _touchLru(int pageNumber) {
    _lruOrder.remove(pageNumber);
    _lruOrder.add(pageNumber);
    while (_lruOrder.length > _maxCachedFonts) {
      final evict = _lruOrder.removeAt(0);
      _loadedFamilies.remove(evict);
      clearQpcV2GlyphFitCache();
    }
  }
}
