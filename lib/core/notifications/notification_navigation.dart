/// Holds a notification payload until [HomeScreen] can navigate.
abstract final class NotificationNavigation {
  static String? pendingPayload;
  static void Function(String payload)? onPayload;

  static void dispatch(String? payload) {
    if (payload == null || payload.isEmpty) return;
    pendingPayload = payload;
    onPayload?.call(payload);
  }

  static String? takePending() {
    final value = pendingPayload;
    pendingPayload = null;
    return value;
  }
}
