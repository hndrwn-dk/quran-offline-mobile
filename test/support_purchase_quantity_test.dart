import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:quran_offline/core/support/support_purchase_quantity.dart';

void main() {
  test('purchase quantity defaults to 1 when it is missing', () {
    expect(supportPurchaseQuantity(_plain()), 1);
    expect(supportPurchaseQuantity(_play(originalJson: '{}')), 1);
    expect(supportPurchaseQuantity(_play(originalJson: 'not-json')), 1);
  });

  test('purchase quantity reads 3 from the Play purchase', () {
    expect(
      supportPurchaseQuantity(_play(originalJson: '{"quantity":3}')),
      3,
    );
  });

  test('thank-you quantity line is shown only above 1', () {
    expect(
      supportThanksQuantityLine(
        language: 'id',
        productId: 'support_10k',
        quantity: 1,
      ),
      isNull,
    );
    expect(
      supportThanksQuantityLine(
        language: 'id',
        productId: 'support_10k',
        quantity: 3,
      ),
      'Segelas kopi ×3',
    );
  });
}

PurchaseDetails _plain() {
  return PurchaseDetails(
    purchaseID: 'order-1',
    productID: 'support_10k',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'google_play',
    ),
    transactionDate: '1',
    status: PurchaseStatus.purchased,
  );
}

GooglePlayPurchaseDetails _play({required String originalJson}) {
  return GooglePlayPurchaseDetails(
    purchaseID: 'order-play',
    productID: 'support_10k',
    verificationData: PurchaseVerificationData(
      localVerificationData: originalJson,
      serverVerificationData: 'server',
      source: 'google_play',
    ),
    transactionDate: '1',
    status: PurchaseStatus.purchased,
    billingClientPurchase: PurchaseWrapper(
      orderId: 'order-play',
      packageName: 'com.tursinalabs.quranoffline',
      purchaseTime: 1,
      purchaseToken: 'token',
      signature: 'sig',
      products: const ['support_10k'],
      isAutoRenewing: false,
      originalJson: originalJson,
      isAcknowledged: true,
      purchaseState: PurchaseStateWrapper.purchased,
    ),
  );
}
