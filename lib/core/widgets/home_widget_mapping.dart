import 'package:quran_offline/core/models/dua_entry.dart';

/// One ayah of the current reflection, as the home widget shows it.
class WidgetReflectionAyah {
  const WidgetReflectionAyah({
    required this.surah,
    required this.ayah,
    required this.index,
    required this.total,
  });

  final int surah;
  final int ayah;

  /// 1-based position inside the reflection ("1 dari N ayat").
  final int index;
  final int total;
}

/// Arabic text longer than this (plain Uthmani characters) does not fit the
/// medium widget at a readable size, so a shorter ayah of the reflection wins.
const kWidgetAyahMaxArabicLength = 160;

/// Every ayah the reflection covers, in reading order.
List<({int surah, int ayah})> flattenReflectionAyahs(List<DuaAyahRef> refs) {
  return [
    for (final ref in refs)
      for (var a = ref.from; a <= ref.to; a++) (surah: ref.surah, ayah: a),
  ];
}

/// Picks the ayah the widget shows: the first one when it fits, otherwise
/// the shortest. [arabicLengthOf] returns null when the text is unknown.
WidgetReflectionAyah? pickWidgetReflectionAyah(
  List<DuaAyahRef> refs,
  int? Function(int surah, int ayah) arabicLengthOf,
) {
  final ayahs = flattenReflectionAyahs(refs);
  if (ayahs.isEmpty) return null;

  var best = 0;
  var bestLength = arabicLengthOf(ayahs.first.surah, ayahs.first.ayah);
  if (bestLength != null && bestLength > kWidgetAyahMaxArabicLength) {
    for (var i = 1; i < ayahs.length; i++) {
      final length = arabicLengthOf(ayahs[i].surah, ayahs[i].ayah);
      if (length != null && length < bestLength!) {
        best = i;
        bestLength = length;
      }
    }
  }

  return WidgetReflectionAyah(
    surah: ayahs[best].surah,
    ayah: ayahs[best].ayah,
    index: best + 1,
    total: ayahs.length,
  );
}

/// Position through the 604-page Mushaf for the progress ring, 0–100.
int widgetQuranPagePercent(int page) {
  if (page <= 0) return 0;
  return ((page / 604) * 100).round().clamp(1, 100);
}

/// "Hal. 297 · Juz 15" line under the surah name.
String widgetContinueMeta({
  required String pageLabel,
  required String? juzLabel,
}) {
  return [pageLabel, if (juzLabel != null) juzLabel].join(' · ');
}

/// Deep link for the continue action. `resume=1` makes the app reopen the
/// saved last-read source (page, juz, or surah); surah/ayah are the fallback
/// while last-read is still loading on a cold start.
String widgetContinueDeepLink(int surahId, int ayahNo) =>
    'quranoffline://read?resume=1&surah=$surahId&ayah=$ayahNo';

String widgetAyahDeepLink(int surahId, int ayahNo) =>
    'quranoffline://read?surah=$surahId&ayah=$ayahNo';
