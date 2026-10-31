import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/reading/reading_completion.dart';
import 'package:quran_offline/core/reading/reading_scope.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Text + progress shown on the Continue card, already scoped to the mode the
/// user last read in. Never mixes a surah ayah number with a juz total.
class ContinueCardView {
  const ContinueCardView({
    required this.title,
    required this.detail,
    required this.scope,
    this.percent,
    this.fraction,
    this.completed = false,
    this.khatam = false,
  });

  final String title;
  final String detail;

  /// 'surah', 'juz', or 'page' — the unit the progress refers to.
  final String scope;
  final int? percent;
  final double? fraction;

  /// True when the unit is finished; the ring shows a check instead of a %.
  final bool completed;
  final bool khatam;
}

/// Floor the percentage, but show at least 1% once anything was read and
/// 100% only when the unit is actually complete.
int continueProgressPercent(double? fraction) {
  if (fraction == null || fraction <= 0) return 0;
  if (fraction >= 1) return 100;
  final percent = (fraction * 100).floor();
  return percent < 1 ? 1 : percent;
}

ContinueCardView buildContinueCardView({
  required String language,
  required LastReadPosition lastRead,
  required LastReadLocation? location,
  required LastReadProgress? progress,
  required String? surahName,
  ReadingCompletion? completion,
  String? nextSurahName,
}) {
  if (completion != null) {
    final title = completion.khatam
        ? AppLocalizations.getContinueKhatamTitle(language)
        : AppLocalizations.formatContinueCompletedTitle(
            language: language,
            kind: completion.kind == 'page' ? 'juz' : completion.kind,
            surahName: surahName,
            juzNo: completion.finishedJuzNo,
          );
    final detail = completion.khatam
        ? AppLocalizations.getContinueKhatamNext(language)
        : AppLocalizations.formatContinueNextUnit(
            language: language,
            kind: completion.kind,
            surahName: nextSurahName,
            juzNo: completion.nextJuzNo,
            pageNo: completion.nextPageNo,
          );
    return ContinueCardView(
      title: title,
      detail: detail,
      scope: completion.kind,
      completed: true,
      khatam: completion.khatam,
    );
  }

  switch (lastRead.type) {
    case 'surah':
    case 'surah_in_juz':
      final title =
          surahName ?? AppLocalizations.getMenuText('surah', language);
      final total = progress?.total ?? 0;
      final current = progress?.current ?? lastRead.ayahNo ?? 1;
      final juzNo = location?.juzNo;
      final detail = total > 0
          ? AppLocalizations.formatContinueProgressLine(
              language: language,
              scope: 'surah',
              current: current,
              total: total,
              juzNo: juzNo,
            )
          : AppLocalizations.formatContinuePosition(
              language: language,
              ayahNo: current,
              juzNo: juzNo,
            );
      return _withProgress(
        title,
        detail,
        total > 0 ? current / total : null,
        scope: 'surah',
      );

    case 'juz':
      final juzNo = lastRead.id;
      final title = AppLocalizations.formatJuzTitle(
        language: language,
        juzNo: juzNo,
      );
      final ayahNo = lastRead.ayahNo ?? location?.ayahNo;
      final index = progress?.current;
      final total = progress?.total;
      final detail = (surahName != null &&
              ayahNo != null &&
              index != null &&
              total != null &&
              total > 0)
          ? AppLocalizations.formatContinueJuzLine(
              language: language,
              surahName: surahName,
              ayahNo: ayahNo,
              indexInJuz: index,
              juzTotal: total,
            )
          : AppLocalizations.formatContinuePosition(
              language: language,
              ayahNo: ayahNo,
              juzNo: juzNo,
            );
      return _withProgress(
        title,
        detail,
        (index != null && total != null && total > 0) ? index / total : null,
        scope: 'juz',
      );

    case 'page':
      final pageNo = lastRead.id;
      final title = AppLocalizations.getPageText(pageNo, language);
      final range = JuzPageRange.tryCreate(
        location?.juzStartPage,
        location?.juzEndPage,
      );
      final detail = AppLocalizations.formatContinueMushafLine(
        language: language,
        surahName: surahName,
        juzNo: location?.juzNo,
        pageInJuz: range == null ? null : pageNo - range.startPage + 1,
        juzPages: range?.totalPages,
      );
      return _withProgress(
        title,
        detail,
        range?.progressForPage(pageNo),
        scope: 'page',
      );

    default:
      final title =
          surahName ?? AppLocalizations.getMenuText('surah', language);
      return ContinueCardView(title: title, detail: '', scope: 'surah');
  }
}

ContinueCardView _withProgress(
  String title,
  String detail,
  double? fraction, {
  required String scope,
}) {
  return ContinueCardView(
    title: title,
    detail: detail,
    scope: scope,
    fraction: fraction,
    percent: fraction == null ? null : continueProgressPercent(fraction),
  );
}
