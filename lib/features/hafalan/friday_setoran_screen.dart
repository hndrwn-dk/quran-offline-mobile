import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/juz_amma_hafalan_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/hafalan/setoran_session_screen.dart';

class FridaySetoranScreen extends ConsumerWidget {
  const FridaySetoranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final queueAsync = ref.watch(fridaySetoranQueueProvider);
    final surahsAsync = ref.watch(surahNamesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.getFridaySetoranScreenTitle(lang)),
      ),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppLocalizations.getFridaySetoranQueueEmpty(lang),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          return surahsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (surahs) {
              final doneCount = items.where((e) => e.isDone).length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    AppLocalizations.getFridaySetoranProgressTitle(lang),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.getFridaySetoranQueueHint(lang),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$doneCount / ${items.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.getSetoranTeacherNote(lang),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...items.map((entry) {
                    final surah = surahs.firstWhere(
                      (s) => s.id == entry.unit.surah,
                      orElse: () => surahs.first,
                    );
                    final refText = AppLocalizations.formatJuzAmmaAyahRef(
                      entry.unit.surah,
                      entry.unit.from,
                      entry.unit.to,
                      lang,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: entry.isDone
                            ? colorScheme.secondaryContainer
                                .withValues(alpha: 0.35)
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          title: Text(
                            surah.englishName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(refText),
                          trailing: entry.isDone
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => SetoranSessionScreen(
                                  unit: entry.unit,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
