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

  final nonce = request['nonce'];
  if (nonce != expectedNonce) {
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
