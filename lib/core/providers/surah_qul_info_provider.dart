import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/surah_qul_info.dart';

final surahQulInfoProvider = FutureProvider<SurahQulInfoBundle>((ref) async {
  final raw = await rootBundle.loadString('assets/quran/surah_info_qul.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return SurahQulInfoBundle.fromJson(json);
});

final surahQulInfoForSurahProvider =
    FutureProvider.family<SurahQulInfoEntry?, ({int surahId, String lang})>(
  (ref, args) async {
    final bundle = await ref.watch(surahQulInfoProvider.future);
    return bundle.forSurah(args.surahId, args.lang);
  },
);
