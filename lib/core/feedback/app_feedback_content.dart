import 'package:quran_offline/core/constants/app_version.dart';
import 'package:quran_offline/core/database/importer.dart';
import 'package:quran_offline/core/feedback/feedback_context.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Builds metadata blocks and email fallback content for in-app feedback.
class AppFeedbackContent {
  AppFeedbackContent._();

  static String quranComUrl(int surahId, int ayahNo) =>
      'https://quran.com/$surahId/$ayahNo';

  static Map<String, dynamic> buildMetadata({
    required String language,
    FeedbackContext? context,
  }) {
    return {
      'appVersion': AppVersion.display,
      'dataVersion': DataImporter.currentVersion,
      'language': language,
      if (context?.surahId != null) 'surahId': context!.surahId,
      if (context?.ayahNo != null) 'ayahNo': context!.ayahNo,
      if (context?.arabicSnippet != null &&
          context!.arabicSnippet!.trim().isNotEmpty)
        'arabicSnippet': context.arabicSnippet!.trim(),
    };
  }

  static String buildDescriptionWithContext({
    required String language,
    required String userDescription,
    FeedbackContext? context,
  }) {
    final blocks = <String>[userDescription.trim()];

    if (context?.hasVerse == true) {
      blocks.add('');
      blocks.add(
        AppLocalizations.getSettingsText('feedback_body_verse', language)
            .replaceAll('{surah}', '${context!.surahId}')
            .replaceAll('{ayah}', '${context.ayahNo}'),
      );
      blocks.add(
        AppLocalizations.getSettingsText('feedback_body_reference', language)
            .replaceAll(
              '{url}',
              quranComUrl(context.surahId!, context.ayahNo!),
            ),
      );
      final arabic = context.arabicSnippet?.trim();
      if (arabic != null && arabic.isNotEmpty) {
        blocks.add('');
        blocks.add(
          AppLocalizations.getSettingsText('feedback_body_arabic', language),
        );
        blocks.add(arabic);
      }
    }

    blocks.add('');
    blocks.add(
      AppLocalizations.getSettingsText('feedback_body_meta', language)
          .replaceAll('{version}', AppVersion.display)
          .replaceAll('{dataVersion}', DataImporter.currentVersion),
    );

    return blocks.join('\n');
  }

  static String buildEmailSubject(
    FeedbackType type,
    String language, {
    int? surahId,
    int? ayahNo,
  }) {
    if (type == FeedbackType.bug && surahId != null && ayahNo != null) {
      return AppLocalizations.getSettingsText(
        'feedback_email_subject_bug_verse',
        language,
      )
          .replaceAll('{surah}', '$surahId')
          .replaceAll('{ayah}', '$ayahNo');
    }
    return switch (type) {
      FeedbackType.feature => AppLocalizations.getSettingsText(
          'feedback_email_subject_feature',
          language,
        ),
      FeedbackType.bug => AppLocalizations.getSettingsText(
          'feedback_email_subject_bug',
          language,
        ),
    };
  }

  static String buildEmailBody({
    required FeedbackType type,
    required String language,
    required String title,
    required String description,
    FeedbackContext? context,
  }) {
    final header = switch (type) {
      FeedbackType.feature => AppLocalizations.getSettingsText(
          'feedback_email_header_feature',
          language,
        ),
      FeedbackType.bug => AppLocalizations.getSettingsText(
          'feedback_email_header_bug',
          language,
        ),
    };

    final lines = <String>[
      header,
      '',
      '${AppLocalizations.getSettingsText('feedback_title_label', language)}: $title',
      '',
      description.trim(),
    ];

    if (context?.hasVerse == true) {
      lines.add('');
      lines.add(
        AppLocalizations.getSettingsText('feedback_body_verse', language)
            .replaceAll('{surah}', '${context!.surahId}')
            .replaceAll('{ayah}', '${context.ayahNo}'),
      );
      lines.add(
        AppLocalizations.getSettingsText('feedback_body_reference', language)
            .replaceAll(
              '{url}',
              quranComUrl(context.surahId!, context.ayahNo!),
            ),
      );
      final arabic = context.arabicSnippet?.trim();
      if (arabic != null && arabic.isNotEmpty) {
        lines.add('');
        lines.add(
          AppLocalizations.getSettingsText('feedback_body_arabic', language),
        );
        lines.add(arabic);
      }
    }

    lines.add('');
    lines.add(
      AppLocalizations.getSettingsText('feedback_body_meta', language)
          .replaceAll('{version}', AppVersion.display)
          .replaceAll('{dataVersion}', DataImporter.currentVersion),
    );

    return lines.join('\n');
  }
}
