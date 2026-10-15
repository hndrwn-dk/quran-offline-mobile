import 'dart:convert';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Play consumable quantity. Missing or non-Play purchases count as 1.
///
/// [PurchaseWrapper] in in_app_purchase_android 0.5.4 does not expose
/// `quantity` even though the billing purchase carries it, so this reads the
/// field when present and otherwise the purchase JSON.
int supportPurchaseQuantity(PurchaseDetails purchase) {
  if (purchase is! GooglePlayPurchaseDetails) return 1;
  final billing = purchase.billingClientPurchase;
  final fromField = _quantityField(billing);
  if (fromField != null) return fromField;
  return _quantityJson(billing.originalJson);
}

/// Null when a single unit should stay unmentioned.
String? supportThanksQuantityLine({
  required String language,
  required String? productId,
  required int quantity,
}) {
  if (quantity <= 1 || productId == null || productId.isEmpty) return null;
  final label = AppLocalizations.supportTierLabel(language, productId);
  return '$label ×$quantity';
}

int? _quantityField(PurchaseWrapper billing) {
  try {
    final dynamic value = (billing as dynamic).quantity;
    if (value is int) return _atLeastOne(value);
  } on NoSuchMethodError {
    return null;
  }
  return null;
}

int _quantityJson(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      final value = decoded['quantity'];
      if (value is int) return _atLeastOne(value);
    }
  } catch (_) {}
  return 1;
}

int _atLeastOne(int value) => value < 1 ? 1 : value;
