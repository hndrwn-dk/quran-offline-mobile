import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/constants/app_links.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsLinkActions {
  SettingsLinkActions._();

  static const String donateUrl = AppLinks.donateUrl;
  static const String privacyUrl = 'https://www.tursinalabs.com/privacy';
  static const String termsUrl = 'https://www.tursinalabs.com/terms';

  static Future<void> openDonate(BuildContext context) =>
      _openUrl(context, Uri.parse(donateUrl), external: true);

  static Future<void> openPrivacy(BuildContext context) =>
      _openUrl(context, Uri.parse(privacyUrl));

  static Future<void> openTerms(BuildContext context) =>
      _openUrl(context, Uri.parse(termsUrl));

  static Future<void> openRateApp(BuildContext context, String appLanguage) =>
      _openUrl(context, Uri.parse(AppLinks.playStoreForLocale(appLanguage)));

  static Future<void> shareApp(String appLanguage) async {
    await Share.share(AppLinks.shareAppMessage(appLanguage));
  }

  static void showSupportInfo(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.read(settingsProvider).appLanguage;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.getSettingsText('support_dialog_title', appLanguage),
        ),
        content: Text(
          AppLocalizations.getSettingsText('support_dialog_content', appLanguage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
          mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
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
