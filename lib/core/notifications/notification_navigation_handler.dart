import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/notifications/notification_navigation.dart';
import 'package:quran_offline/core/notifications/notification_payload.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

/// Routes the user after tapping a weekly reminder notification.
Future<void> handleNotificationPayload(
  BuildContext context,
  WidgetRef ref,
  String payload,
) async {
  switch (payload) {
    case NotificationPayload.beranda:
      ref.read(currentTabProvider.notifier).state = AppTab.home;
      return;
    case NotificationPayload.continueReading:
      final lastRead = ref.read(lastReadProvider);
      if (lastRead == null) {
        ref.read(currentTabProvider.notifier).state = AppTab.read;
        return;
      }
      final source = lastRead.toReaderSource();
      ref.read(readerSourceProvider.notifier).state = source;
      if (lastRead.ayahNo != null) {
        ref.read(targetAyahProvider.notifier).state = lastRead.ayahNo;
      }
      await openReaderScreen(context, ref);
      return;
    default:
      return;
  }
}

void registerNotificationNavigationHandler(
  BuildContext context,
  WidgetRef ref,
) {
  NotificationNavigation.onPayload = (payload) {
    if (!context.mounted) return;
    handleNotificationPayload(context, ref, payload);
  };

  final pending = NotificationNavigation.takePending();
  if (pending != null && context.mounted) {
    handleNotificationPayload(context, ref, pending);
  }
}
