import 'package:quran_offline/core/constants/app_links.dart';
import 'package:flutter/material.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/core/widgets/quran_arabic_text.dart';

/// Layout constants for share-card eligibility (two-path share).
const double kVerseShareCardWidth = 340;
const double kVerseShareCardInnerWidth = 276;
const double kVerseShareCardArabicFontSize = 22;
const int kVerseShareMaxCardLines = 5;

class VerseShareContent {
  const VerseShareContent({
    required this.verse,
    required this.surahName,
    required this.appLanguage,
    required this.contentLanguage,
    required this.transliterationText,
  });

  final Verse verse;
  final String surahName;
  final String appLanguage;
  final String contentLanguage;
  final String transliterationText;

  factory VerseShareContent.from({
    required Verse verse,
    required String surahName,
    required AppSettings settings,
    String? transliterationText,
  }) {
    return VerseShareContent(
      verse: verse,
      surahName: surahName,
      appLanguage: settings.appLanguage,
      contentLanguage: settings.language,
      transliterationText: transliterationText?.trim() ?? '',
    );
  }

  String? get translation {
    final raw = switch (contentLanguage) {
      'en' => verse.trEn,
      'id' => verse.trId,
      'zh' => verse.trZh,
      'ja' => verse.trJa,
      _ => verse.trId,
    };
    return raw != null ? TranslationCleaner.clean(raw) : null;
  }

  String get transliteration => transliterationText;

  String get plainArabic => verse.arabic;

  String get referenceLine {
    final ayahLabel = AppLocalizations.getAyahLabel(appLanguage);
    return '(QS. $surahName ${verse.surahId}: $ayahLabel ${verse.ayahNo})';
  }

  /// Estimates how many lines the Arabic will occupy on the share card.
  int estimateArabicLineCount() {
    return _estimateLineCount(
      plainArabic,
      kVerseShareCardArabicFontSize,
      kVerseShareCardInnerWidth,
    );
  }

  bool get fitsShareCard => estimateArabicLineCount() <= kVerseShareMaxCardLines;

  /// Play Store URL localized to the user's translation language (`hl=`).
  String get playStoreUrl => AppLinks.playStoreForLocale(contentLanguage);

  String get playStoreDisplay => AppLinks.playStoreDisplayForLocale(contentLanguage);

  /// Text shared to WhatsApp and others. Always includes Arabic so the
  /// Play Store URL stays a tap-able line of text (PNG cannot carry links).
  String buildShareCaption() {
    final buffer = StringBuffer();
    buffer.writeln(AppLocalizations.getShareHeader(appLanguage));
    buffer.writeln('');

    buffer.writeln(plainArabic);
    buffer.writeln('');

    final translit = transliteration;
    if (translit.isNotEmpty) {
      buffer.writeln(translit);
      buffer.writeln('');
    }

    final tr = translation;
    if (tr != null) {
      buffer.writeln('"$tr"');
      buffer.writeln('');
    }

    buffer.writeln(referenceLine);
    buffer.writeln('');
    buffer.writeln(playStoreUrl);
    return buffer.toString();
  }

  static int _estimateLineCount(
    String text,
    double fontSize,
    double maxWidth,
  ) {
    if (text.trim().isEmpty) return 0;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: QuranArabicText.arabicDisplayStyle(
          fontSize: fontSize,
          color: Colors.black,
          isLightTheme: true,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    )..layout(maxWidth: maxWidth);

    return painter.computeLineMetrics().length;
  }
}
