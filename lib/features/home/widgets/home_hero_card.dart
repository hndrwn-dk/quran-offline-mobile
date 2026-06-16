import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/day_period.dart';

/// Unified home hero (layout C): section label, time-of-day salam, tagline.
class HomeHeroCard extends ConsumerWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final period = homeDayPeriodFromTime(DateTime.now());
    final periodColor = homeDayPeriodIconColor(period, colorScheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
          color: colorScheme.surface.withValues(alpha: 0.94),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.getMenuText('home', lang).toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DayPeriodBadge(period: period, color: periodColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.getHomeWelcomeTransliteration(lang),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        height: 1.2,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      AppLocalizations.homeWelcomeArabic,
                      style: textTheme.titleMedium?.copyWith(
                        fontFamily: 'UthmanicHafsV22',
                        fontFamilyFallback: const ['UthmanicHafs'],
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.getHomeTagline(lang),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPeriodBadge extends StatelessWidget {
  const _DayPeriodBadge({
    required this.period,
    required this.color,
  });

  final HomeDayPeriod period;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        homeDayPeriodIcon(period),
        size: 16,
        color: color,
      ),
    );
  }
}
