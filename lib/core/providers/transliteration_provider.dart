import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/transliteration/transliteration_repository.dart';

final transliterationRepositoryProvider =
    Provider<TransliterationRepository>((ref) {
  final repo = TransliterationRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final ayahTransliterationProvider =
    FutureProvider.family<String?, ({int surahId, int ayahNo})>(
  (ref, args) async {
    final repo = ref.watch(transliterationRepositoryProvider);
    return repo.getForAyah(args.surahId, args.ayahNo);
  },
);
