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

  testWidgets('loading sheet shows three price placeholders, not a spinner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'id',
      'appLanguage': 'id',
    });
    final fake = _HangingBilling();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportPurchaseProvider.overrideWith(
            (ref) => SupportPurchaseService(fake),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SupportSheet())),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
        find.byKey(const Key('support_price_placeholder')), findsNWidgets(3));
    expect(find.text('Segelas kopi'), findsOneWidget);
    expect(find.text('Makan siang'), findsOneWidget);
    expect(find.text('Dukung penuh'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}

class _HangingBilling implements SupportBillingClient {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return Completer<ProductDetailsResponse>().future;
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
