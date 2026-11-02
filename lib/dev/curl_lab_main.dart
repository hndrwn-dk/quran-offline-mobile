// Curl Lab: dev-only harness for the Mushaf page-turn shader.
//
//   QO_APP_ID_SUFFIX=.curllab flutter run -t lib/dev/curl_lab_main.dart
//
// Nothing in lib/main.dart imports this file, so release builds never contain
// it. The app id suffix installs it next to the real app instead of over it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran_offline/dev/curl_lab_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  try {
    // Mushaf text watches the audio provider, which needs the service.
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.tursinalabs.quranoffline.curllab',
      androidNotificationChannelName: 'Curl Lab',
    );
  } catch (e) {
    debugPrint('JustAudioBackground.init failed: $e');
  }
  runApp(const ProviderScope(child: CurlLabApp()));
}
