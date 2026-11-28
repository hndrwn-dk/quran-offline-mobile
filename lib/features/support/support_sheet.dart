import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/support_provider.dart';
import 'package:quran_offline/core/support/support_products.dart';
import 'package:quran_offline/core/support/support_purchase_quantity.dart';
import 'package:quran_offline/core/support/support_purchase_service.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';
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
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottom),
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
                  productId: service.purchasedProductId,
                  quantity: service.purchasedQuantity,
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
          style: _sheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.supportSheetBody(language),
          style: _sheetBodyStyle(context),
        ),
        const SizedBox(height: 18),
        if (service.phase == SupportUiPhase.unavailable)
          AppCard(
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
                if (i > 0) const SizedBox(width: 10),
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
          const SizedBox(height: 12),
          Text(
            AppLocalizations.supportQuantityHint(language),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 18),
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
            style: _sheetButtonStyle(context),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priceStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 17,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: colorScheme.onSurface,
    );
    final fontSize = priceStyle?.fontSize ?? 17;
    final lineHeight = fontSize * (priceStyle?.height ?? 1.25);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: selected ? colorScheme.primary : Colors.transparent,
        width: 2,
      ),
    );
    return Material(
      color: selected ? colorScheme.tint : colorScheme.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
          child: Column(
            children: [
              SizedBox(
                height: lineHeight,
                child: price == null
                    ? Center(
                        child: DecoratedBox(
                          key: const Key('support_price_placeholder'),
                          decoration: BoxDecoration(
                            color: colorScheme.hairline,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SizedBox(width: 64, height: fontSize * 0.7),
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          price!,
                          textAlign: TextAlign.center,
                          style: priceStyle,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle? _sheetTitleStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.titleLarge?.copyWith(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: theme.colorScheme.onSurface,
  );
}

TextStyle? _sheetBodyStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium?.copyWith(
    fontSize: 15,
    height: 1.45,
    color: theme.colorScheme.onSurfaceVariant,
  );
}

ButtonStyle _sheetButtonStyle(BuildContext context) {
  return FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(50),
    shape: const StadiumBorder(),
    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
  );
}

class _Thanks extends StatelessWidget {
  const _Thanks({
    super.key,
    required this.language,
    required this.productId,
    required this.quantity,
  });

  final String language;
  final String? productId;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final quantityLine = supportThanksQuantityLine(
      language: language,
      productId: productId,
      quantity: quantity,
    );
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const SupportThanksHeart(),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.supportThanksTitle(language),
          style: _sheetTitleStyle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.supportThanksBody(language),
          textAlign: TextAlign.center,
          style: _sheetBodyStyle(context),
        ),
        if (quantityLine != null) ...[
          const SizedBox(height: 8),
          Text(
            quantityLine,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: _sheetButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.supportClose(language)),
          ),
        ),
      ],
    );
  }
}
