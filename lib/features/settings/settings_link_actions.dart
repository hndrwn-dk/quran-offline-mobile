import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:quran_offline/core/constants/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsLinkActions {
  SettingsLinkActions._();

  static const String privacyUrl = 'https://www.tursinalabs.com/privacy';
  static const String termsUrl = 'https://www.tursinalabs.com/terms';

  static Future<void> openPrivacy(BuildContext context) =>
      _openUrl(context, Uri.parse(privacyUrl));

  static Future<void> openTerms(BuildContext context) =>
      _openUrl(context, Uri.parse(termsUrl));

  /// Opens the Play Store listing through the in-app review plugin.
  ///
  /// No appStoreId is needed on Android; failures are silent (no Play Store,
  /// offline, etc.).
  static Future<void> openRateAppInStore() async {
    try {
      await InAppReview.instance.openStoreListing();
    } catch (_) {
      // Silent by design.
    }
  }

  static Future<void> shareApp(String appLanguage) async {
    await SharePlus.instance.share(
      ShareParams(text: AppLinks.shareAppMessage(appLanguage)),
    );
  }

  static Future<void> _openUrl(
    BuildContext context,
    Uri uri, {
    bool external = false,
  }) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: external
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
