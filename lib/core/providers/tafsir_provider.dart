import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/tafsir_entry.dart';
import 'package:quran_offline/core/tafsir/tafsir_repository.dart';

final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) {
  final repo = TafsirRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final ayahTafsirProvider = FutureProvider.family<
    TafsirEntry?,
    ({int surahId, int ayahNo, String translationLanguage})>(
  (ref, args) async {
    final repo = ref.watch(tafsirRepositoryProvider);
    return repo.getForAyah(
      args.translationLanguage,
      args.surahId,
      args.ayahNo,
    );
  },
);
