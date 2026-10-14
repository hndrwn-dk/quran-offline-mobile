import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/support_provider.dart';
import 'package:quran_offline/core/support/support_products.dart';
import 'package:quran_offline/core/support/support_purchase_service.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/support/support_heart_mark.dart';

Future<void> showSupportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const SupportSheet(),
  );
}

class SupportSheet extends ConsumerStatefulWidget {
  const SupportSheet({super.key});

  @override
  ConsumerState<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends ConsumerState<SupportSheet> {
  late final SupportPurchaseService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(supportPurchaseProvider);
    _service.consumeSignals();
    _service.sheetOpen = true;
    _service.start();
    _service.addListener(_onService);
    _service.prepare();
  }

  @override
  void dispose() {
    _service.sheetOpen = false;
    _service.removeListener(_onService);
    super.dispose();
  }

  void _onService() {
    if (!mounted) return;
    final service = _service;
    if (service.closeRequested) {
      final failed = service.errorRequested;
      service.consumeSignals();
      final messenger = ScaffoldMessenger.of(context);
      final language = ref.read(settingsProvider).appLanguage;
      Navigator.of(context).pop();
      if (failed) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.supportPurchaseError(language))),
        );
      }
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supportPurchaseProvider);
    final language = ref.watch(settingsProvider).appLanguage;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: service.phase == SupportUiPhase.thanks
              ? _Thanks(
                  key: const ValueKey('support_thanks'),
                  language: language,
                )
              : _Catalog(
                  key: const ValueKey('support_catalog'),
                  language: language,
                  service: service,
                ),
        ),
      ),
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({
    super.key,
    required this.language,
    required this.service,
  });

  final String language;
  final SupportPurchaseService service;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loading = service.phase == SupportUiPhase.loading;
    final tiles = loading
        ? [
            for (final id in SupportProducts.ordered)
              (id: id, price: null as String?),
          ]
        : [
            for (final offer in service.offers)
              (id: offer.id, price: offer.price),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.supportSheetTitle(language),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(AppLocalizations.supportSheetBody(language)),
        const SizedBox(height: 16),
        if (service.phase == SupportUiPhase.unavailable)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              AppLocalizations.supportUnavailable(language),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else ...[
          Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _TierTile(
                    price: tiles[i].price,
                    label: AppLocalizations.supportTierLabel(
                      language,
                      tiles[i].id,
                    ),
                    selected: tiles[i].id == service.selectedId,
                    onTap: loading ? null : () => service.select(tiles[i].id),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (service.phase == SupportUiPhase.pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                AppLocalizations.supportPaymentPending(language),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          FilledButton(
            onPressed: service.phase == SupportUiPhase.catalog
                ? service.buySelected
                : null,
            child: Text(AppLocalizations.supportContinuePlay(language)),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          AppLocalizations.supportFootnote(language),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.price,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String? price;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priceStyle = Theme.of(context).textTheme.titleSmall;
    final fontSize = priceStyle?.fontSize ?? 14;
    final lineHeight = fontSize * (priceStyle?.height ?? 1.43);
    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              SizedBox(
                height: lineHeight,
                child: price == null
                    ? Center(
                        child: DecoratedBox(
                          key: const Key('support_price_placeholder'),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SizedBox(width: 64, height: fontSize * 0.7),
                        ),
                      )
                    : Text(
                        price!,
                        textAlign: TextAlign.center,
                        style: priceStyle,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thanks extends StatelessWidget {
  const _Thanks({super.key, required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const SupportThanksHeart(),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.supportThanksTitle(language),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.supportThanksBody(language),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.supportClose(language)),
          ),
        ),
      ],
    );
  }
}
