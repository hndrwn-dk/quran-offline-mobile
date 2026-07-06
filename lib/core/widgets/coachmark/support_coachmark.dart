import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/coachmark/support_coachmark_service.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/coachmark/coachmark_overlay.dart';
import 'package:quran_offline/features/settings/settings_link_actions.dart';

/// Staged coachmark directing users to the support / Ko-fi icon.
class SupportCoachmark {
  SupportCoachmark._();

  static final SupportCoachmarkService _service = SupportCoachmarkService();

  static Future<void> maybeShow({
    required BuildContext context,
    required WidgetRef ref,
    required GlobalKey supportIconKey,
    SupportCoachmarkService? service,
  }) async {
    final coachmarkService = service ?? _service;
    if (!await coachmarkService.shouldShow()) return;
    if (!context.mounted) return;

    await coachmarkService.recordShown();
    if (!context.mounted) return;

    final lang = ref.read(settingsProvider).appLanguage;

    CoachmarkOverlay.show(
      context: context,
      targetKey: supportIconKey,
      title: AppLocalizations.getSupportCoachmarkTitle(lang),
      body: AppLocalizations.getSupportCoachmarkBody(lang),
      dismissLabel: AppLocalizations.getSupportCoachmarkDismiss(lang),
      ctaLabel: AppLocalizations.getSupportCoachmarkCta(lang),
      onDismiss: () {},
      onCta: () async {
        await coachmarkService.recordCtaTapped();
        if (context.mounted) {
          await SettingsLinkActions.openDonate(context);
        }
      },
    );
  }
}
