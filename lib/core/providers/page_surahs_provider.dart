import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';

class PageSurahsInfo {
  final int pageNo;
  final List<int> surahIds;

  PageSurahsInfo({
    required this.pageNo,
    required this.surahIds,
  });
}

final pageSurahsProvider = FutureProvider.family<PageSurahsInfo, int>((ref, pageNo) async {
  final surahIds = await MushafLayout.getSurahIdsForPage(pageNo);
  
  return PageSurahsInfo(
    pageNo: pageNo,
    surahIds: surahIds,
  );
});

