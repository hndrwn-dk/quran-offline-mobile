import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/search/tanya_result_layout.dart';
import 'package:quran_offline/features/search/widgets/ai_result_card.dart';

typedef TanyaCardBuilder = Widget Function(AiSearchHit hit, String lang);

final tanyaCardBuilderProvider = Provider<TanyaCardBuilder>((ref) {
  return (hit, lang) => AiSearchHitCard(hit: hit, lang: lang);
});

class TanyaSearchResults extends StatefulWidget {
  const TanyaSearchResults({
    super.key,
    required this.groups,
    required this.lang,
    required this.translationCount,
    required this.cardBuilder,
    this.onJumpToTranslation,
    this.loading = false,
  });

  final List<AiSearchTypeGroup> groups;
  final String lang;
  final int translationCount;
  final TanyaCardBuilder cardBuilder;
  final VoidCallback? onJumpToTranslation;
  final bool loading;

  @override
  State<TanyaSearchResults> createState() => _TanyaSearchResultsState();
}

class _TanyaSearchResultsState extends State<TanyaSearchResults> {
  final Set<String> _expandedTypes = {};

  @override
  Widget build(BuildContext context) {
    final laid = layoutTanyaGroups(widget.groups);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.loading && laid.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        if (laid.isEmpty)
          Padding(
            key: const Key('tanya_empty'),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 56,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.getAiSearchEmpty(widget.lang),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.translationCount > 0 &&
                    widget.onJumpToTranslation != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    key: const Key('tanya_see_translations'),
                    onPressed: widget.onJumpToTranslation,
                    child: Text(
                      AppLocalizations.getAiSearchSeeTranslations(widget.lang),
                    ),
                  ),
                ],
              ],
            ),
          ),
        for (final group in laid) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              AppLocalizations.getAiSearchTypeLabel(group.type, widget.lang),
              key: Key('ai_search_group_${group.type}'),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final hit in tanyaVisibleHits(
            group,
            expanded: _expandedTypes.contains(group.type),
          ))
            widget.cardBuilder(hit, widget.lang),
          if (tanyaNeedsSeeAll(group) && !_expandedTypes.contains(group.type))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('tanya_see_all_${group.type}'),
                onPressed: () {
                  setState(() => _expandedTypes.add(group.type));
                },
                child: Text(AppLocalizations.getAiSearchSeeAll(widget.lang)),
              ),
            ),
        ],
        if (laid.isNotEmpty && widget.translationCount > 0)
          _buildTranslationJump(context),
        ],
      ),
    );
  }

  Widget _buildTranslationJump(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = AppLocalizations.getAiSearchTranslationJump(
      widget.lang,
      widget.translationCount,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Card(
        child: ListTile(
          key: const Key('tanya_translation_jump'),
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(Icons.translate, color: colorScheme.primary),
          ),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: widget.onJumpToTranslation,
        ),
      ),
    );
  }
}
