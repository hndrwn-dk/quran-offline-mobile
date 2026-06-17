import 'dart:async';

import 'package:quran_offline/core/mushaf/qpc_v2_font_loader.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_repository.dart';
import 'package:quran_offline/core/utils/bismillah.dart';

/// High-level QPC V2 Mushaf page loader (layout + glyphs + per-page font).
class QpcV2MushafLayout {
  QpcV2MushafLayout(this._repository);

  final QpcV2Repository _repository;

  static QpcV2Repository? _sharedRepository;
  static String? _basmallahFontFamily;

  static QpcV2Repository sharedRepository() {
    return _sharedRepository ??= QpcV2Repository();
  }

  static Future<bool> isAvailable() => QpcV2Repository.assetsAvailable();

  Future<QpcV2PageContent> getPageContent(int pageNumber) async {
    final fontFamily = await QpcV2FontLoader.ensurePageFontLoaded(pageNumber);
    _basmallahFontFamily ??=
        await QpcV2FontLoader.ensurePageFontLoaded(1);
    final lines = await _repository.getPageLines(pageNumber);
    final bismillahGlyphText = await _repository.bismillahGlyphText();
    return QpcV2PageContent(
      pageNumber: pageNumber,
      lines: lines,
      fontFamily: fontFamily,
      basmallahFontFamily: _basmallahFontFamily!,
      bismillahGlyphText: bismillahGlyphText,
    );
  }

  Future<void> prewarm(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    await getPageContent(pageNumber);
  }

  /// Load one page (font + layout) before opening Mushaf or jumping from lists.
  static Future<void> prewarmPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    await sharedRepository().ensureReady();
    final layout = QpcV2MushafLayout(sharedRepository());
    await layout.prewarm(pageNumber);
    QpcV2FontLoader.prefetchPages({
      pageNumber - 1,
      pageNumber,
      pageNumber + 1,
      1,
    });
  }

  /// Prefetch fonts and load nearby page content in the background.
  static void prewarmNeighbors(int centerPage) {
    if (centerPage < 1 || centerPage > 604) return;
    final neighbors = <int>{
      centerPage - 2,
      centerPage - 1,
      centerPage,
      centerPage + 1,
      centerPage + 2,
    }.where((p) => p >= 1 && p <= 604);
    QpcV2FontLoader.prefetchPages({
      ...neighbors,
      1,
    });
    unawaited(_prewarmContent(neighbors, priorityPage: centerPage));
  }

  static Future<void> _prewarmContent(
    Iterable<int> pages, {
    required int priorityPage,
  }) async {
    final layout = QpcV2MushafLayout(sharedRepository());
    final ordered = pages.toList()
      ..sort(
        (a, b) => (a - priorityPage).abs().compareTo((b - priorityPage).abs()),
      );

    for (final page in ordered) {
      if (page == priorityPage) continue;
      if ((page - priorityPage).abs() <= 1) {
        await layout.prewarm(page);
      } else {
        unawaited(layout.prewarm(page));
      }
    }
  }

  Future<bool> pageContainsRecitation(
    int pageNumber,
    int surahId,
    int ayahNo,
  ) async {
    if (ayahNo == Bismillah.audioAyahNo) {
      if (await _repository.pageContainsRecitation(pageNumber, surahId, 1)) {
        return true;
      }
      return _repository.pageHasBasmallahForSurah(pageNumber, surahId);
    }
    return _repository.pageContainsRecitation(pageNumber, surahId, ayahNo);
  }

  Future<List<int>> getSurahIdsForPage(int pageNumber) {
    return _repository.getSurahIdsForPage(pageNumber);
  }

  Future<bool> pageHasBasmallahForSurah(int pageNumber, int surahId) {
    return _repository.pageHasBasmallahForSurah(pageNumber, surahId);
  }
}
