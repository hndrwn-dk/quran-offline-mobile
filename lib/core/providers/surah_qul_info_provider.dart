import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/surah_qul_info.dart';
import 'package:quran_offline/core/surah_info/surah_info_repository.dart';

final surahInfoRepositoryProvider = Provider<SurahInfoRepository>((ref) {
  final repo = SurahInfoRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final surahQulInfoForSurahProvider =
    FutureProvider.family<SurahQulInfoEntry?, ({int surahId, String lang})>(
  (ref, args) async {
    final repo = ref.watch(surahInfoRepositoryProvider);
    return repo.getForSurah(args.lang, args.surahId);
  },
);
