import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quran_offline/core/constants/app_version.dart';
import 'package:quran_offline/core/database/importer.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Opens a pre-filled email to report tajweed coloring issues.
class TajweedReport {
  TajweedReport._();

  static const String supportEmail = 'support@tursinalabs.com';

  /// Resolves surah:ayah from last-read when the position is verse-specific.
  static ({int surahId, int ayahNo})? ayahFromLastRead(LastReadPosition? pos) {
    if (pos == null || pos.ayahNo == null) return null;
    return switch (pos.type) {
      'surah' => (surahId: pos.id, ayahNo: pos.ayahNo!),
      'surah_in_juz' => (surahId: pos.id, ayahNo: pos.ayahNo!),
      'page' when pos.surahId != null =>
        (surahId: pos.surahId!, ayahNo: pos.ayahNo!),
      _ => null,
    };
  }

  static String quranComUrl(int surahId, int ayahNo) =>
      'https://quran.com/$surahId/$ayahNo';

  static String buildSubject(String language, {int? surahId, int? ayahNo}) {
    if (surahId != null && ayahNo != null) {
      return AppLocalizations.getSettingsText(
        'report_tajweed_email_subject',
        language,
      )
          .replaceAll('{surah}', '$surahId')
          .replaceAll('{ayah}', '$ayahNo');
    }
    return AppLocalizations.getSettingsText(
      'report_tajweed_email_subject_generic',
      language,
    );
  }

  static String buildBody({
    required String language,
    int? surahId,
    int? ayahNo,
    String? arabicSnippet,
  }) {
    final verseLine = surahId != null && ayahNo != null
        ? AppLocalizations.getSettingsText(
            'report_tajweed_body_verse',
            language,
          )
            .replaceAll('{surah}', '$surahId')
            .replaceAll('{ayah}', '$ayahNo')
        : AppLocalizations.getSettingsText(
            'report_tajweed_body_verse_unknown',
            language,
          );

    final referenceLine = surahId != null && ayahNo != null
        ? AppLocalizations.getSettingsText(
            'report_tajweed_body_reference',
            language,
          ).replaceAll('{url}', quranComUrl(surahId, ayahNo))
        : '';

    final arabicBlock = arabicSnippet != null && arabicSnippet.trim().isNotEmpty
        ? '${AppLocalizations.getSettingsText('report_tajweed_body_arabic', language)}\n${arabicSnippet.trim()}\n'
        : '';

    final prompt = AppLocalizations.getSettingsText(
      'report_tajweed_body_prompt',
      language,
    );

    final meta = AppLocalizations.getSettingsText(
      'report_tajweed_body_meta',
      language,
    )
        .replaceAll('{version}', AppVersion.display)
        .replaceAll('{dataVersion}', DataImporter.currentVersion);

    return [
      AppLocalizations.getSettingsText('report_tajweed_body_header', language),
      '',
      verseLine,
      if (referenceLine.isNotEmpty) referenceLine,
      if (arabicBlock.isNotEmpty) arabicBlock,
      meta,
      '',
      prompt,
      '',
    ].join('\n');
  }

  static Uri buildMailtoUri({
    required String language,
    int? surahId,
    int? ayahNo,
    String? arabicSnippet,
  }) {
    return Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': buildSubject(language, surahId: surahId, ayahNo: ayahNo),
        'body': buildBody(
          language: language,
          surahId: surahId,
          ayahNo: ayahNo,
          arabicSnippet: arabicSnippet,
        ),
      },
    );
  }

  static Future<void> launch({
    required BuildContext context,
    required String language,
    int? surahId,
    int? ayahNo,
    String? arabicSnippet,
  }) async {
    final uri = buildMailtoUri(
      language: language,
      surahId: surahId,
      ayahNo: ayahNo,
      arabicSnippet: arabicSnippet,
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened && context.mounted) {
        _showFailure(context, language);
      }
    } catch (_) {
      if (context.mounted) {
        _showFailure(context, language);
      }
    }
  }

  static void _showFailure(BuildContext context, String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.getSettingsText(
            'report_tajweed_launch_failed',
            language,
          ),
        ),
      ),
    );
  }
}
