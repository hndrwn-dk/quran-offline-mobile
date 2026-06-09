import 'dart:io';

import 'package:flutter/services.dart';

/// Opens the system voice-input settings screen (Android).
Future<bool> openVoiceInputSettings() async {
  if (!Platform.isAndroid) return false;
  const channel = MethodChannel('com.tursinalabs.quranoffline/voice_settings');
  try {
    final ok = await channel.invokeMethod<bool>('openVoiceInputSettings');
    return ok ?? false;
  } on PlatformException {
    return false;
  }
}
