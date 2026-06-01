import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';

/// Opens a full-screen [ReaderScreen] and tracks visibility for the global mini player.
Future<void> openReaderScreen(BuildContext context, WidgetRef ref) {
  ref.read(readerScreenVisibleProvider.notifier).state = true;
  return Navigator.of(context)
      .push<void>(
        MaterialPageRoute(builder: (context) => const ReaderScreen()),
      )
      .whenComplete(() {
    ref.read(readerScreenVisibleProvider.notifier).state = false;
  });
}
