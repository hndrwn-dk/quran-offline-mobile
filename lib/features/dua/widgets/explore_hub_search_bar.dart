import 'package:flutter/material.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Pill-shaped search field for the Jelajahi hub (mockup phase 4).
class ExploreHubSearchBar extends StatelessWidget {
  const ExploreHubSearchBar({
    super.key,
    required this.lang,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final String lang;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasText = controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: AppLocalizations.getExploreSearchHint(lang),
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
            ),
            filled: true,
            fillColor: colorScheme.surface.withValues(alpha: 0.94),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.65),
              ),
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClear,
                    tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.search,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
            suffixIconConstraints: const BoxConstraints(
              minHeight: 40,
              minWidth: 40,
            ),
          ),
        ),
      ),
    );
  }
}
