import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quran_offline/core/providers/support_provider.dart';
import 'package:quran_offline/core/support/support_billing_client.dart';
import 'package:quran_offline/core/support/support_purchase_service.dart';
import 'package:quran_offline/features/support/support_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('thank-you shows the product times quantity when it is above 1', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'id',
      'appLanguage': 'id',
    });
    await _pumpThanks(tester, quantity: 3, productId: 'support_10k');
    expect(find.text('Segelas kopi ×3'), findsOneWidget);
  });

  testWidgets('thank-you hides the quantity line for a single unit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'id',
      'appLanguage': 'id',
    });
    await _pumpThanks(tester, quantity: 1, productId: 'support_10k');
    expect(find.textContaining('×'), findsNothing);
  });
}

Future<void> _pumpThanks(
  WidgetTester tester, {
  required int quantity,
  required String productId,
}) async {
  final service = SupportPurchaseService(_IdleBilling())
    ..phase = SupportUiPhase.thanks
    ..purchasedQuantity = quantity
    ..purchasedProductId = productId;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportPurchaseProvider.overrideWith((ref) => service),
      ],
      child: const MaterialApp(home: Scaffold(body: SupportSheet())),
    ),
  );
  await tester.pump();
}

class _IdleBilling implements SupportBillingClient {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return Future.value(
      ProductDetailsResponse(productDetails: const [], notFoundIDs: const []),
    );
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async =>
      false;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}
