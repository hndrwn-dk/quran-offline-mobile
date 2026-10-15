import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quran_offline/core/support/support_billing_client.dart';
import 'package:quran_offline/core/support/support_products.dart';
import 'package:quran_offline/core/support/support_purchase_quantity.dart';

enum SupportUiPhase { loading, catalog, pending, thanks, unavailable }

class SupportOffer {
  const SupportOffer({required this.id, required this.price});

  final String id;
  final String price;
}

/// Play consumables for support. Prices are [ProductDetails.price].
class SupportPurchaseService extends ChangeNotifier {
  SupportPurchaseService(this._client, {this.onPurchased});

  final SupportBillingClient _client;
  final VoidCallback? onPurchased;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Map<String, ProductDetails> _details = {};
  final Set<String> _recordedPurchases = {};
  var _started = false;
  var _disposed = false;

  SupportUiPhase phase = SupportUiPhase.loading;
  List<SupportOffer> offers = const [];
  String selectedId = SupportProducts.defaultSelected;
  bool sheetOpen = false;
  bool closeRequested = false;
  bool errorRequested = false;
  int purchasedQuantity = 1;
  String? purchasedProductId;

  void start() {
    if (_started) return;
    _started = true;
    try {
      _subscription = _client.purchaseStream.listen(
        _onPurchases,
        onError: (_) => _failQuietly(),
      );
    } catch (_) {
      phase = SupportUiPhase.unavailable;
      return;
    }
    unawaited(_prefetchDetails());
  }

  /// Fills [_details] after the purchase listener is attached. Does not change
  /// phase and does not block startup.
  Future<void> _prefetchDetails() async {
    try {
      await _readProducts();
    } catch (_) {}
  }

  bool get _cacheComplete => SupportProducts.ids.every(_details.containsKey);

  bool get _holdsPurchasePhase =>
      phase == SupportUiPhase.pending || phase == SupportUiPhase.thanks;

  Future<void> prepare() async {
    if (_cacheComplete) {
      _publishOffers(updatePhase: true);
      unawaited(_refreshPrices());
      return;
    }
    if (!_holdsPurchasePhase && phase != SupportUiPhase.loading) {
      phase = SupportUiPhase.loading;
      _notify();
    }
    try {
      final stored = await _readProducts();
      if (_disposed) return;
      if (!stored && !_cacheComplete) {
        _markUnavailable();
        return;
      }
      _publishOffers(updatePhase: true);
    } catch (_) {
      if (_disposed) return;
      _markUnavailable();
    }
  }

  Future<void> _refreshPrices() async {
    try {
      final changed = await _readProducts();
      if (_disposed || !changed) return;
      _publishOffers(updatePhase: false);
    } catch (_) {}
  }

  /// Returns whether cached prices changed. A partial Play response leaves the
  /// existing cache in place.
  Future<bool> _readProducts() async {
    final available = await _client.isAvailable();
    if (!available || _disposed) return false;
    final response = await _client.queryProductDetails(SupportProducts.ids);
    if (_disposed) return false;
    final incoming = {
      for (final product in response.productDetails) product.id: product,
    };
    if (!SupportProducts.ids.every(incoming.containsKey)) return false;
    final changed = SupportProducts.ordered.any(
      (id) => _details[id]?.price != incoming[id]!.price,
    );
    _details
      ..clear()
      ..addAll(incoming);
    return changed;
  }

  void _publishOffers({required bool updatePhase}) {
    offers = [
      for (final id in SupportProducts.ordered)
        if (_details[id] != null)
          SupportOffer(id: id, price: _details[id]!.price),
    ];
    if (offers.isNotEmpty && !offers.any((offer) => offer.id == selectedId)) {
      selectedId = offers.length >= 2 ? offers[1].id : offers.first.id;
    }
    if (_holdsPurchasePhase) {
      _notify();
      return;
    }
    if (offers.isEmpty) {
      _markUnavailable();
      return;
    }
    if (updatePhase) phase = SupportUiPhase.catalog;
    _notify();
  }

  void _markUnavailable() {
    if (_holdsPurchasePhase || _cacheComplete) return;
    phase = SupportUiPhase.unavailable;
    offers = const [];
    _notify();
  }

  void select(String id) {
    if (!_details.containsKey(id)) return;
    selectedId = id;
    _notify();
  }

  Future<void> buySelected() async {
    final details = _details[selectedId];
    if (details == null) {
      phase = SupportUiPhase.unavailable;
      _notify();
      return;
    }
    phase = SupportUiPhase.pending;
    _notify();
    try {
      final sent = await _client.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
        autoConsume: true,
      );
      if (!sent) _failQuietly();
    } catch (_) {
      _failQuietly();
    }
  }

  void finishThanks() {
    phase = SupportUiPhase.catalog;
    _notify();
  }

  void consumeSignals() {
    closeRequested = false;
    errorRequested = false;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    if (_disposed) return;
    for (final purchase in purchases) {
      final ours = SupportProducts.ids.contains(purchase.productID);
      if (!ours) {
        if (purchase.pendingCompletePurchase) {
          await _client.completePurchase(purchase);
        }
        continue;
      }
      switch (purchase.status) {
        case PurchaseStatus.pending:
          phase = SupportUiPhase.pending;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.pendingCompletePurchase) {
            await _client.completePurchase(purchase);
          }
          _recordOnce(purchase);
          purchasedProductId = purchase.productID;
          purchasedQuantity = supportPurchaseQuantity(purchase);
          phase = sheetOpen ? SupportUiPhase.thanks : SupportUiPhase.catalog;
        case PurchaseStatus.canceled:
          phase = SupportUiPhase.catalog;
          if (sheetOpen) closeRequested = true;
        case PurchaseStatus.error:
          if (purchase.pendingCompletePurchase) {
            await _client.completePurchase(purchase);
          }
          _failQuietly();
      }
      _notify();
    }
  }

  void _recordOnce(PurchaseDetails purchase) {
    final key = purchase.purchaseID ??
        '${purchase.productID}:${purchase.transactionDate ?? purchase.hashCode}';
    if (!_recordedPurchases.add(key)) return;
    onPurchased?.call();
  }

  void _notify() {
    if (_disposed) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  void _failQuietly() {
    if (_disposed) return;
    phase = SupportUiPhase.catalog;
    errorRequested = true;
    if (sheetOpen) closeRequested = true;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
