import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/reading/reading_scope.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Text + progress shown on the Continue card, already scoped to the mode the
/// user last read in. Never mixes a surah ayah number with a juz total.
class ContinueCardView {
  const ContinueCardView({
    required this.title,
    required this.detail,
    this.percent,
    this.fraction,
  });

  final String title;
  final String detail;
  final int? percent;
  final double? fraction;
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
}) {
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
      return _withProgress(title, detail, total > 0 ? current / total : null);

    case 'juz':
      final juzNo = lastRead.id;
      final title = '${AppLocalizations.getMenuText('juz', language)} $juzNo';
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
      );

    case 'page':
      final pageNo = lastRead.id;
      final title = AppLocalizations.getPageText(pageNo, language);
      final detail = AppLocalizations.formatContinueMushafLine(
        language: language,
        surahName: surahName,
        juzNo: location?.juzNo,
      );
      final range = JuzPageRange.tryCreate(
        location?.juzStartPage,
        location?.juzEndPage,
      );
      return _withProgress(title, detail, range?.progressForPage(pageNo));

    default:
      final title =
          surahName ?? AppLocalizations.getMenuText('surah', language);
      return ContinueCardView(title: title, detail: '');
  }
}

ContinueCardView _withProgress(
  String title,
  String detail,
  double? fraction,
) {
  return ContinueCardView(
    title: title,
    detail: detail,
    fraction: fraction,
    percent: fraction == null ? null : continueProgressPercent(fraction),
  );
}
