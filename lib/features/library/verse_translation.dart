import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';

String verseTranslation(Verse? verse, String language) {
  if (verse == null) return '';
  final raw = switch (language) {
    'en' => verse.trEn ?? '',
    'id' => verse.trId ?? '',
    'zh' => verse.trZh ?? '',
    'ja' => verse.trJa ?? '',
    _ => verse.trId ?? verse.trEn ?? '',
  };
  return TranslationCleaner.clean(raw);
}
