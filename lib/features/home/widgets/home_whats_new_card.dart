import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/providers/app_version_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/whats_new.dart';

/// "Yang baru di <major.minor>": shown once on Beranda after a feature
/// update (see [whatsNewDue]) until the reader closes it. A flat card like
/// the other home cards. Not tappable; only the close button acts.
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 6, 18),
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
                        color: colorScheme.primary,
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
                padding: const EdgeInsets.only(right: 12),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
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
