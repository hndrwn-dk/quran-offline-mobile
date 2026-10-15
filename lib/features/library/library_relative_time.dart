import 'package:quran_offline/core/utils/app_localizations.dart';

String formatLibraryRelativeTime(
  DateTime time,
  DateTime now,
  String language,
) {
  final localTime = time.toLocal();
  final localNow = now.toLocal();
  if (!localTime.isBefore(localNow)) {
    return AppLocalizations.libraryJustNow(language);
  }
  final startNow = DateTime(localNow.year, localNow.month, localNow.day);
  final startThen = DateTime(localTime.year, localTime.month, localTime.day);
  final dayGap = startNow.difference(startThen).inDays;
  final diff = localNow.difference(localTime);
  if (dayGap <= 0) {
    if (diff.inMinutes < 1) return AppLocalizations.libraryJustNow(language);
    if (diff.inHours < 1) {
      return AppLocalizations.libraryMinutesAgo(diff.inMinutes, language);
    }
    return AppLocalizations.libraryHoursAgo(diff.inHours, language);
  }
  if (dayGap == 1) return AppLocalizations.libraryYesterday(language);
  return AppLocalizations.libraryDaysAgo(dayGap, language);
}
