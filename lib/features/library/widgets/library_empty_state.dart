import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';

class LibraryEmptyState extends ConsumerWidget {
  const LibraryEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.collections_bookmark_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = ref.watch(settingsProvider.select((s) => s.appLanguage));

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBadge(icon: icon, size: 64),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tint,
                foregroundColor: colorScheme.onTint,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              onPressed: () {
                ref.read(currentTabProvider.notifier).state = AppTab.read;
              },
              child: Text(AppLocalizations.getMenuText('read', lang)),
            ),
          ],
        ),
      ),
    );
  }
}
