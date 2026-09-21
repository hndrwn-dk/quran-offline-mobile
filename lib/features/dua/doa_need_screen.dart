import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/ai_search/doa_need_resolver.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/quran_dua_ayat_catalog_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/search/widgets/ai_result_card.dart';

class DoaNeedScreen extends ConsumerStatefulWidget {
  const DoaNeedScreen({
    super.key,
    this.previewResult,
    this.onOpenDoaNabiList,
  });

  /// Test seam: skip the index and render this result.
  final DoaNeedResult? previewResult;
  final VoidCallback? onOpenDoaNabiList;

  @override
  ConsumerState<DoaNeedScreen> createState() => _DoaNeedScreenState();
}

class _DoaNeedScreenState extends ConsumerState<DoaNeedScreen> {
  late final TextEditingController _controller;
  DoaNeedResult? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _result = widget.previewResult;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolve(String raw) async {
    if (widget.previewResult != null) return;
    final query = raw.trim();
    if (query.isEmpty) {
      setState(() => _result = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final lang = ref.read(settingsProvider).language;
      final duas = await ref.read(duaCatalogProvider.future);
      final quranDua = await ref.read(quranDuaAyatCatalogProvider.future);
      final resolver = DoaNeedResolver(
        index: ref.read(searchIndexRepositoryProvider),
        quranDuaEntries: quranDua.entries,
        duaEntries: duas.entries,
      );
      final result = await resolver.resolve(query, lang: lang);
      if (!mounted) return;
      setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.getDoaNeedTitle(lang)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
        children: [
          AppSearchFieldInset(
            child: AppSearchField(
              textFieldKey: const Key('doa_need_field'),
              controller: _controller,
              hintText: AppLocalizations.getDoaNeedPrompt(lang),
              onSubmitted: _resolve,
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && result != null && result.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.getDoaNeedEmpty(lang),
                    key: const Key('doa_need_header_tier4'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const Key('doa_need_empty_link'),
                    onPressed: widget.onOpenDoaNabiList,
                    child: Text(AppLocalizations.getDoaNeedEmptyLink(lang)),
                  ),
                ],
              ),
            ),
          if (result != null && result.tier1.isNotEmpty)
            _tierBlock(
              key: const Key('doa_need_header_tier1'),
              header: AppLocalizations.getDoaNeedTier1Header(lang),
              items: result.tier1,
              lang: lang,
            ),
          if (result != null && result.tier2.isNotEmpty)
            _tierBlock(
              key: const Key('doa_need_header_tier2'),
              header: AppLocalizations.getDoaNeedTier2Header(lang),
              items: result.tier2,
              lang: lang,
            ),
          if (result != null && result.tier3.isNotEmpty)
            _tierBlock(
              key: const Key('doa_need_header_tier3'),
              header: AppLocalizations.getDoaNeedTier3Header(lang),
              items: result.tier3,
              lang: lang,
            ),
          if (result != null && result.tier3b.isNotEmpty)
            _tierBlock(
              key: const Key('doa_need_header_tier3b'),
              header: AppLocalizations.getDoaNeedTier3bHeader(lang),
              items: result.tier3b,
              lang: lang,
            ),
        ],
      ),
    );
  }

  Widget _tierBlock({
    required Key key,
    required String header,
    required List<DoaNeedItem> items,
    required String lang,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            header,
            key: key,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        for (final item in items)
          AiSearchHitCard(
            hit: AiSearchHit.fromIndex(item.hit),
            lang: lang,
          ),
      ],
    );
  }
}
