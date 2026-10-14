import 'package:in_app_purchase/in_app_purchase.dart';

/// The slice of Play Billing the support flow uses.
abstract class SupportBillingClient {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  });

  Future<void> completePurchase(PurchaseDetails purchase);
}

class PlaySupportBillingClient implements SupportBillingClient {
  PlaySupportBillingClient(this._iap);

  final InAppPurchase _iap;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return _iap.queryProductDetails(identifiers);
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) {
    return _iap.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: autoConsume,
    );
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
  }
}
