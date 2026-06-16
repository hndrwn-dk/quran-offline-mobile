import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/mushaf_hints_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// One-time dismissible hint for tap / long-press gestures on Mushaf ayat.
class MushafGestureHintBanner extends ConsumerWidget {
  const MushafGestureHintBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleAsync = ref.watch(mushafGestureHintVisibleProvider);
    final visible = visibleAsync.valueOrNull;
    if (visible != true) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final lang = ref.watch(settingsProvider).appLanguage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.getMushafGestureHint(lang),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.35,
                        fontSize: 12,
                      ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                tooltip: AppLocalizations.getActionTooltip('close', lang),
                onPressed: () => dismissMushafGestureHint(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
