import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran_offline/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.tursinalabs.quranoffline.audio',
      androidNotificationChannelName: 'Quran Recitation',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    // Audio background service failed to initialise; the app should still run.
    // Recitation playback may fall back to foreground-only behaviour.
    debugPrint('JustAudioBackground.init failed: $e');
  }
  runApp(
    const ProviderScope(
      child: QuranOfflineApp(),
    ),
  );
}
