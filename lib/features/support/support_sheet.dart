import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/support_provider.dart';
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
  @override
  void initState() {
    super.initState();
    final service = ref.read(supportPurchaseProvider);
    service.consumeSignals();
    service.sheetOpen = true;
    service.start();
    service.addListener(_onService);
    service.prepare();
  }

  @override
  void dispose() {
    final service = ref.read(supportPurchaseProvider);
    service.sheetOpen = false;
    service.removeListener(_onService);
    super.dispose();
  }

  void _onService() {
    if (!mounted) return;
    final service = ref.read(supportPurchaseProvider);
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
    final colorScheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: service.phase == SupportUiPhase.thanks
          ? _Thanks(language: language)
          : Column(
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
                if (service.phase == SupportUiPhase.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (service.phase == SupportUiPhase.unavailable)
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
                      for (var i = 0; i < service.offers.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _TierTile(
                            price: service.offers[i].price,
                            label: AppLocalizations.supportTierLabel(
                              language,
                              service.offers[i].id,
                            ),
                            selected:
                                service.offers[i].id == service.selectedId,
                            onTap: () => service.select(service.offers[i].id),
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
                    onPressed: service.phase == SupportUiPhase.pending
                        ? null
                        : service.buySelected,
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
            ),
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

  final String price;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              Text(
                price,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
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
  const _Thanks({required this.language});

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
