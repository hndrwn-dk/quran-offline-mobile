import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const playIntegrityChannelName = 'com.tursinalabs.quran_offline/play_integrity';

/// URL-safe Base64 nonce (32 bytes of entropy, no padding).
String generatePlayIntegrityNonce() {
  final rng = Random.secure();
  final bytes = Uint8List.fromList(List<int>.generate(32, (_) => rng.nextInt(256)));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

abstract class PlayIntegrityAttestation {
  Future<String?> requestToken(String nonce);
}

class MethodChannelPlayIntegrityAttestation implements PlayIntegrityAttestation {
  const MethodChannelPlayIntegrityAttestation({
    MethodChannel? channel,
  }) : _channel = channel;

  final MethodChannel? _channel;

  MethodChannel get channel =>
      _channel ?? const MethodChannel(playIntegrityChannelName);

  @override
  Future<String?> requestToken(String nonce) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final token = await channel.invokeMethod<String>('requestToken', {
        'nonce': nonce,
      });
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }
}
