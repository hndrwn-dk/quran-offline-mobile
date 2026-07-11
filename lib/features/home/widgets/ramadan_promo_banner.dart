import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/constants/app_links.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/ramadan_promo_schedule.dart';
import 'package:url_launcher/url_launcher.dart';

/// Method channel to Android PackageManager — package_info_plus only reads this app.
const _appCheckChannel = MethodChannel('com.tursinalabs.quran_offline/app_check');

/// Session cache so we do not query PackageManager on every rebuild.
bool? _sessionRamadanTrackerInstalled;

/// Returns true when Ramadan Tracker is installed; false on any error (fail-safe).
Future<bool> isRamadanTrackerInstalled() async {
  if (_sessionRamadanTrackerInstalled != null) {
    return _sessionRamadanTrackerInstalled!;
  }
  try {
    final installed = await _appCheckChannel.invokeMethod<bool>(
      'isPackageInstalled',
      {'packageName': AppLinks.ramadanTrackerPackageId},
    );
    _sessionRamadanTrackerInstalled = installed ?? false;
    return _sessionRamadanTrackerInstalled!;
  } catch (_) {
    _sessionRamadanTrackerInstalled = false;
    return false;
  }
}

/// Clears session install cache (tests only).
@visibleForTesting
void resetRamadanTrackerInstallCacheForTest() {
  _sessionRamadanTrackerInstalled = null;
}

typedef RamadanPromoAnalyticsEvent = void Function(String eventName);

/// Beranda promo card for Ramadan Tracker with smart deep-link vs Play Store fallback.
class RamadanPromoBanner extends ConsumerStatefulWidget {
  const RamadanPromoBanner({
    super.key,
    this.onTapTryApp,
    this.onAnalyticsEvent,
    this.onDismiss,
  });

  /// Optional override for tests or custom navigation.
  final VoidCallback? onTapTryApp;

  /// Fires `promo_tap_deeplink` or `promo_tap_store` after install check.
  final RamadanPromoAnalyticsEvent? onAnalyticsEvent;

  /// Called when user taps close; parent may hide the banner.
  final VoidCallback? onDismiss;

  @override
  ConsumerState<RamadanPromoBanner> createState() => _RamadanPromoBannerState();
}

class _RamadanPromoBannerState extends ConsumerState<RamadanPromoBanner> {
  bool? _installed;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _primeInstallCheck();
  }

  Future<void> _primeInstallCheck() async {
    final installed = await isRamadanTrackerInstalled();
    if (mounted) {
      setState(() => _installed = installed);
    }
  }

  Future<void> _handleTryAppTap() async {
    if (widget.onTapTryApp != null) {
      widget.onTapTryApp!();
      return;
    }

    final installed = _installed ?? await isRamadanTrackerInstalled();
    if (mounted) {
      setState(() => _installed = installed);
    }

    if (installed) {
      widget.onAnalyticsEvent?.call('promo_tap_deeplink');
      await _openRamadanTrackerDeepLink();
    } else {
      widget.onAnalyticsEvent?.call('promo_tap_store');
      await _openRamadanTrackerStore();
    }
  }

  Future<void> _openRamadanTrackerDeepLink() async {
    final deepLink = Uri.parse(AppLinks.ramadanTrackerDeepLink);
    try {
      if (await canLaunchUrl(deepLink)) {
        final launched = await launchUrl(
          deepLink,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
    } catch (_) {}

    widget.onAnalyticsEvent?.call('promo_tap_store');
    await _openRamadanTrackerStore();
  }

  Future<void> _openRamadanTrackerStore() async {
    final marketUri = Uri.parse(AppLinks.ramadanTrackerMarketUrl());
    final httpsUri = Uri.parse(
      AppLinks.ramadanTrackerPlayStoreForLocale(
        ref.read(settingsProvider).appLanguage,
      ),
    );

    try {
      if (await canLaunchUrl(marketUri)) {
        final launched = await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(httpsUri)) {
        await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final lang = ref.watch(settingsProvider).appLanguage;
    final schedule = RamadanPromoSchedule.fromDateTime(DateTime.now());
    if (!schedule.shouldShowPromo) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final badge = AppLocalizations.getRamadanPromoBadge(
      lang,
      schedule.daysUntilRamadan,
      schedule.inRamadan,
    );
    final ctaKey = (_installed ?? false)
        ? 'ramadan_promo_cta_open'
        : 'ramadan_promo_cta_try';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.45),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.nightlight_round,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.getSettingsText('ramadan_promo_title', lang),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.getSettingsText('ramadan_promo_body', lang),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonal(
                          onPressed: _handleTryAppTap,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppLocalizations.getSettingsText(ctaKey, lang)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () {
                  widget.onDismiss?.call();
                  setState(() => _dismissed = true);
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
