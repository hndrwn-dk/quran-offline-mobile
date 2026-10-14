import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quran_offline/core/support/support_billing_client.dart';
import 'package:quran_offline/core/support/support_purchase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shows Play prices and buys the middle consumable', () async {
    final fake = _FakeBilling()
      ..products = [
        _product('support_10k', 'Rp10.000'),
        _product('support_25k', 'Rp25.000'),
        _product('support_50k', 'Rp50.000'),
      ];
    final service = SupportPurchaseService(fake);
    service.start();
    await service.prepare();

    expect(service.offers.map((offer) => offer.price), ['Rp10.000', 'Rp25.000', 'Rp50.000']);
    expect(service.selectedId, 'support_25k');
    expect(service.phase, SupportUiPhase.catalog);

    await service.buySelected();
    expect(service.phase, SupportUiPhase.pending);
    expect(fake.lastAutoConsume, isTrue);
    expect(fake.lastParam?.productDetails.id, 'support_25k');
    service.dispose();
  });

  test('unavailable when Play has no products', () async {
    final fake = _FakeBilling();
    final service = SupportPurchaseService(fake);
    service.start();
    await service.prepare();
    expect(service.phase, SupportUiPhase.unavailable);
    service.dispose();
  });

  test('completes a purchase once and shows thanks while the sheet is open', () async {
    var recorded = 0;
    final fake = _FakeBilling();
    final service = SupportPurchaseService(fake, onPurchased: () => recorded++);
    service.sheetOpen = true;
    service.start();
    final item = _purchase(PurchaseStatus.purchased, pendingComplete: true);
    fake.emit([item]);
    await pumpEventQueue();

    expect(fake.completed, [item]);
    expect(service.phase, SupportUiPhase.thanks);
    expect(recorded, 1);

    fake.emit([item]);
    await pumpEventQueue();
    expect(recorded, 1);
    service.dispose();
  });

  test('pending, cancel, and error', () async {
    final fake = _FakeBilling();
    final service = SupportPurchaseService(fake)..sheetOpen = true;
    service.start();

    fake.emit([_purchase(PurchaseStatus.pending)]);
    await pumpEventQueue();
    expect(service.phase, SupportUiPhase.pending);

    fake.emit([_purchase(PurchaseStatus.canceled)]);
    await pumpEventQueue();
    expect(service.phase, SupportUiPhase.catalog);
    expect(service.closeRequested, isTrue);
    expect(service.errorRequested, isFalse);

    service.consumeSignals();
    final failed = _purchase(PurchaseStatus.error, pendingComplete: true);
    fake.emit([failed]);
    await pumpEventQueue();
    expect(service.errorRequested, isTrue);
    expect(service.closeRequested, isTrue);
    expect(fake.completed, contains(failed));
    service.dispose();
  });
}

ProductDetails _product(String id, String price) {
  return ProductDetails(
    id: id,
    title: id,
    description: id,
    price: price,
    rawPrice: 1,
    currencyCode: 'IDR',
  );
}

PurchaseDetails _purchase(
  PurchaseStatus status, {
  bool pendingComplete = false,
  String id = 'support_25k',
}) {
  return PurchaseDetails(
    purchaseID: 'order-$id-${status.name}',
    productID: id,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'google_play',
    ),
    transactionDate: '1',
    status: status,
  )..pendingCompletePurchase = pendingComplete;
}

class _FakeBilling implements SupportBillingClient {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  List<ProductDetails> products = [];
  PurchaseParam? lastParam;
  bool? lastAutoConsume;
  final completed = <PurchaseDetails>[];

  void emit(List<PurchaseDetails> purchases) => _updates.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async {
    return ProductDetailsResponse(
      productDetails: products.where((product) => identifiers.contains(product.id)).toList(),
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    lastParam = purchaseParam;
    lastAutoConsume = autoConsume;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }
}
