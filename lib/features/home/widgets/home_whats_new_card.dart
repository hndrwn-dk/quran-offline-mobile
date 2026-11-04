import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/app_version_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/whats_new.dart';

/// "Yang baru di <major.minor>": shown once on Beranda after a feature
/// update (see [whatsNewDue]) until the reader closes it. Same shape as the
/// home Renungan card, in the scheme's tertiary tint so it reads apart from
/// the green Lanjutkan baca card and the beige Renungan card. Not tappable;
/// only the close button acts.
class HomeWhatsNewCard extends ConsumerWidget {
  const HomeWhatsNewCard({super.key});

  /// Keeps "Lanjutkan baca" on the first screen.
  static const int maxNotes = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(whatsNewDueProvider)) return const SizedBox.shrink();

    final version = ref.watch(appVersionProvider);
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final closeLabel = AppLocalizations.getWhatsNewClose(lang);
    final notes =
        AppLocalizations.getWhatsNewNotes(lang).take(maxNotes).toList();
    final noteStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      height: 1.4,
    );

    return Padding(
      key: const Key('home_whats_new_card'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DecoratedBox(
        decoration: _whatsNewDecoration(colorScheme),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.getWhatsNewLabel(lang),
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('home_whats_new_close'),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    color: colorScheme.onSurfaceVariant,
                    tooltip: closeLabel,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => ref
                        .read(settingsProvider.notifier)
                        .markWhatsNewSeen(version),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        AppLocalizations.getWhatsNewTitle(
                          featureVersion(version),
                          lang,
                        ),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final note in notes)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExcludeSemantics(
                              child: Text('•', style: noteStyle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                note,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: noteStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors the home Renungan decoration (radius 20, primary hairline and
/// shadow, diagonal wash) with the scheme's tertiary container as the tint.
BoxDecoration _whatsNewDecoration(ColorScheme colorScheme) {
  final isDark = colorScheme.brightness == Brightness.dark;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
    ),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              colorScheme.tertiaryContainer.withValues(alpha: 0.38),
              colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
            ]
          : [
              colorScheme.surfaceContainerLow,
              colorScheme.tertiaryContainer.withValues(alpha: 0.45),
            ],
    ),
    boxShadow: [
      BoxShadow(
        color: colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.06),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
