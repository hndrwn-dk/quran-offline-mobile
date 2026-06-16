import 'package:flutter/services.dart';
import 'package:quran_offline/core/mushaf/qpc_v4_assets.dart';

/// Loads per-page QPC V4 Tajweed TTF assets at runtime.
class QpcV4FontLoader {
  QpcV4FontLoader._();

  static final Map<int, String> _loadedFamilies = {};
  static final Map<int, Future<String>> _loading = {};

  static String familyForPage(int pageNumber) =>
      '${QpcV4Assets.pageFontFamilyPrefix}$pageNumber';

  static Future<String> ensurePageFontLoaded(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604, 'pageNumber');
    }
    final cached = _loadedFamilies[pageNumber];
    if (cached != null) return Future.value(cached);

    return _loading.putIfAbsent(pageNumber, () async {
      final family = familyForPage(pageNumber);
      final data = await rootBundle.load(
        QpcV4Assets.pageFontAssetPath(pageNumber),
      );
      final loader = FontLoader(family);
      loader.addFont(Future.value(data));
      await loader.load();
      _loadedFamilies[pageNumber] = family;
      _loading.remove(pageNumber);
      return family;
    });
  }
}
