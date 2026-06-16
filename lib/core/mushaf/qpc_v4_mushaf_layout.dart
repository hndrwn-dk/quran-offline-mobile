import 'package:quran_offline/core/mushaf/qpc_v4_font_loader.dart';
import 'package:quran_offline/core/mushaf/qpc_v4_models.dart';
import 'package:quran_offline/core/mushaf/qpc_v4_repository.dart';
import 'package:quran_offline/core/utils/bismillah.dart';

/// High-level QPC V4 Mushaf page loader (layout + glyphs + per-page font).
class QpcV4MushafLayout {
  QpcV4MushafLayout(this._repository);

  final QpcV4Repository _repository;

  static QpcV4Repository? _sharedRepository;

  static QpcV4Repository sharedRepository() {
    return _sharedRepository ??= QpcV4Repository();
  }

  static Future<bool> isAvailable() => QpcV4Repository.assetsAvailable();

  Future<QpcV4PageContent> getPageContent(int pageNumber) async {
    final fontFamily = await QpcV4FontLoader.ensurePageFontLoaded(pageNumber);
    return _repository.getPageContent(
      pageNumber,
      fontFamily: fontFamily,
    );
  }

  Future<void> prewarm(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    await getPageContent(pageNumber);
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
