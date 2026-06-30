import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quran_offline/core/feedback/app_feedback_content.dart';
import 'package:quran_offline/core/feedback/feedback_context.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Email fallback when the GitHub feedback API is unavailable.
class FeedbackEmailFallback {
  FeedbackEmailFallback._();

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

  static Uri buildMailtoUri({
    required FeedbackType type,
    required String language,
    required String title,
    required String description,
    FeedbackContext? context,
  }) {
    return Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': AppFeedbackContent.buildEmailSubject(
          type,
          language,
          surahId: context?.surahId,
          ayahNo: context?.ayahNo,
        ),
        'body': AppFeedbackContent.buildEmailBody(
          type: type,
          language: language,
          title: title,
          description: description,
          context: context,
        ),
      },
    );
  }

  static Future<bool> launch({
    required FeedbackType type,
    required String language,
    required String title,
    required String description,
    FeedbackContext? context,
  }) async {
    final uri = buildMailtoUri(
      type: type,
      language: language,
      title: title,
      description: description,
      context: context,
    );
    try {
      return launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  static void showLaunchFailed(BuildContext context, String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.getSettingsText('feedback_email_failed', language),
        ),
      ),
    );
  }
}
