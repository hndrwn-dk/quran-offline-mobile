import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quran_offline/core/support/reading_coverage_controller.dart';
import 'package:quran_offline/core/support/support_billing_client.dart';
import 'package:quran_offline/core/support/support_purchase_service.dart';

final readingCoverageProvider = ChangeNotifierProvider<ReadingCoverageController>((ref) {
  return ReadingCoverageController();
});

final supportPurchaseProvider = ChangeNotifierProvider<SupportPurchaseService>((ref) {
  return SupportPurchaseService(
    PlaySupportBillingClient(InAppPurchase.instance),
    onPurchased: () {
      ref.read(readingCoverageProvider).recordPurchase();
    },
  );
});
