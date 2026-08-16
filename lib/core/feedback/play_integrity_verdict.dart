const kFeedbackAndroidPackage = 'com.tursinalabs.quranoffline';
const playIntegrityMaxAgeMs = 5 * 60 * 1000;

enum PlayIntegrityVerdict {
  ok,
  notPlayRecognized,
  nonceMismatch,
  stale,
  wrongPackage,
  weakDevice,
  malformed,
}

/// Compare nonces regardless of URL-safe vs standard Base64 padding.
String normalizeIntegrityNonce(String value) {
  return value.replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_');
}

bool integrityNoncesMatch(Object? tokenNonce, String expectedNonce) {
  if (tokenNonce is! String) return false;
  return normalizeIntegrityNonce(tokenNonce) ==
      normalizeIntegrityNonce(expectedNonce);
}

PlayIntegrityVerdict evaluatePlayIntegrityVerdict({
  required Map<String, dynamic> payload,
  required String expectedNonce,
  required int nowMs,
}) {
  final request = payload['requestDetails'];
  final app = payload['appIntegrity'];
  final device = payload['deviceIntegrity'];
  if (request is! Map || app is! Map || device is! Map) {
    return PlayIntegrityVerdict.malformed;
  }

  final packageName = request['requestPackageName'];
  if (packageName != kFeedbackAndroidPackage) {
    return PlayIntegrityVerdict.wrongPackage;
  }

  if (!integrityNoncesMatch(request['nonce'], expectedNonce)) {
    return PlayIntegrityVerdict.nonceMismatch;
  }

  final tsRaw = request['timestampMillis'];
  final timestampMs = tsRaw is num
      ? tsRaw.toInt()
      : int.tryParse(tsRaw?.toString() ?? '');
  if (timestampMs == null) {
    return PlayIntegrityVerdict.malformed;
  }
  if ((nowMs - timestampMs).abs() > playIntegrityMaxAgeMs) {
    return PlayIntegrityVerdict.stale;
  }

  if (app['appRecognitionVerdict'] != 'PLAY_RECOGNIZED') {
    return PlayIntegrityVerdict.notPlayRecognized;
  }

  final verdicts = device['deviceRecognitionVerdict'];
  if (verdicts is! List ||
      !(verdicts.contains('MEETS_DEVICE_INTEGRITY') ||
          verdicts.contains('MEETS_BASIC_INTEGRITY'))) {
    return PlayIntegrityVerdict.weakDevice;
  }

  return PlayIntegrityVerdict.ok;
}
