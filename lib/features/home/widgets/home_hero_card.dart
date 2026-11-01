import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Compact home greeting: Hijri eyebrow + salam, typography only.
class HomeHeroCard extends ConsumerWidget {
  const HomeHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = ref.watch(reflectionNowProvider);
    final pickAsync = ref.watch(reflectionPickProvider);
    final day = ref.watch(islamicDayProvider);
    final isLatin = lang == 'id' || lang == 'en';
    final occasionBadgeKey = pickAsync.maybeWhen(
      data: (pick) {
        final type = pick.entry.trigger?.type;
        if (type == 'hijri_day' || type == 'hijri_month') {
          return pick.entry.badgeKey;
        }
        return null;
      },
      orElse: () => null,
    );
    final eyebrow = AppLocalizations.getHomeGreetingEyebrow(
      language: lang,
      weekday: day.weekday,
      hijri: day.hijri,
      clockHour: now.hour,
      occasionBadgeKey: occasionBadgeKey,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            eyebrow,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: isLatin ? 1.2 : 0,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.getHomeWelcomeTransliteration(lang),
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
