import 'package:flutter/material.dart';

import 'coachmark_overlay.dart';
import 'coachmark_storage_keys.dart';
import 'staged_coachmark_service.dart';

// =============================================================================
// COPY THIS FILE per feature, then rename class + config + strings.
// Example names: SupportCoachmark, RamadanCoachmark, OnboardingTipCoachmark
// =============================================================================

/// Default staged coachmark for a header action (donate, settings tip, etc.).
class FeatureCoachmarkTemplate {
  FeatureCoachmarkTemplate._();

  /// Change [prefix] so each feature has isolated SharedPreferences state.
  static const _config = CoachmarkConfig(
    keys: CoachmarkStorageKeys(prefix: 'YOUR_FEATURE_coachmark'),
    firstShowMinAppOpens: 3,
    maxShowCount: 3,
    reminderDelays: [
      Duration(days: 7),
      Duration(days: 14),
    ],
  );

  static final _service = StagedCoachmarkService(config: _config);

  /// Call from home screen postFrameCallback when target widget has a GlobalKey.
  static Future<void> maybeShow({
    required BuildContext context,
    required GlobalKey targetKey,
    required VoidCallback onCta,
    String title = 'Enjoying the app?',
    String body = 'Tap here to learn more.',
    String dismissLabel = 'Later',
    String ctaLabel = 'View',
    StagedCoachmarkService? service,
  }) async {
    final coachmarkService = service ?? _service;
    if (!await coachmarkService.shouldShow()) return;
    if (!context.mounted) return;

    await coachmarkService.recordShown();
    if (!context.mounted) return;

    CoachmarkOverlay.show(
      context: context,
      targetKey: targetKey,
      title: title,
      body: body,
      dismissLabel: dismissLabel,
      ctaLabel: ctaLabel,
      onDismiss: () {},
      onCta: () async {
        await coachmarkService.recordCtaTapped();
        onCta();
      },
    );
  }
}
