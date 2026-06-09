import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SetoranSpeechStartResult {
  started,
  unavailable,
  noArabicLocale,
}

class SetoranArabicVoiceProbe {
  const SetoranArabicVoiceProbe({
    required this.speechAvailable,
    required this.arabicListed,
    this.localeId,
  });

  final bool speechAvailable;
  final bool arabicListed;
  final String? localeId;

  bool get isReady => speechAvailable && arabicListed;
}

/// Device speech-to-text for setoran (Arabic locale required).
class SetoranSpeechRecognizer {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  String _lastWords = '';
  String? _activeLocaleId;

  bool get isAvailable => _initialized;
  bool get isListening => _speech.isListening;
  String? get activeLocaleId => _activeLocaleId;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  /// Re-query device locales after the user changes voice-typing languages.
  Future<bool> refresh() async {
    _initialized = false;
    return initialize();
  }

  /// True when the device speech engine lists an Arabic locale.
  Future<bool> hasArabicLocale() async {
    return (await preferredArabicLocaleId()) != null;
  }

  Future<SetoranArabicVoiceProbe> probeArabicVoice() async {
    await refresh();
    if (!_initialized) {
      return const SetoranArabicVoiceProbe(
        speechAvailable: false,
        arabicListed: false,
      );
    }
    final localeId = await preferredArabicLocaleId();
    return SetoranArabicVoiceProbe(
      speechAvailable: true,
      arabicListed: localeId != null,
      localeId: localeId,
    );
  }

  Future<String?> preferredArabicLocaleId() async {
    if (!_initialized) return null;
    final locales = await _speech.locales();
    const preferred = [
      'ar-SA',
      'ar_SA',
      'ar-EG',
      'ar_EG',
      'ar-ID',
      'ar_ID',
      'ar',
    ];
    for (final code in preferred) {
      for (final locale in locales) {
        if (locale.localeId == code) return locale.localeId;
      }
    }
    for (final locale in locales) {
      final id = locale.localeId.toLowerCase();
      if (id.startsWith('ar') || id.contains('arab')) {
        return locale.localeId;
      }
    }
    return null;
  }

  void Function(String words)? _onWords;

  Future<SetoranSpeechStartResult> startListening({
    void Function(String words)? onWords,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return SetoranSpeechStartResult.unavailable;
    }
    if (_speech.isListening) return SetoranSpeechStartResult.started;

    final localeId = await preferredArabicLocaleId();
    if (localeId == null) {
      return SetoranSpeechStartResult.noArabicLocale;
    }

    _onWords = onWords;
    _lastWords = '';
    _activeLocaleId = localeId;
    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        onDevice: false,
        localeId: localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 5),
      ),
    );
    return _speech.isListening
        ? SetoranSpeechStartResult.started
        : SetoranSpeechStartResult.unavailable;
  }

  void _onResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _onWords?.call(_lastWords);
  }

  Future<String> stopAndGetTranscript() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    return _lastWords.trim();
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
    _lastWords = '';
    _onWords = null;
    _activeLocaleId = null;
  }

  Future<void> dispose() async {
    await cancel();
  }
}

/// True when STT output looks like English hallucination, not romanized Qur'an.
bool setoranTranscriptLooksLatin(String text) {
  if (text.trim().isEmpty) return false;
  final arabic = RegExp(r'[\u0600-\u06FF]');
  if (arabic.hasMatch(text)) return false;

  final words = text.trim().split(RegExp(r'\s+'));
  final longLatinWords = words
      .where((w) => w.length >= 5 && RegExp(r'^[A-Za-z]+$').hasMatch(w))
      .length;
  // English STT: several words and/or multiple longer dictionary terms.
  if (words.length >= 4) return true;
  return longLatinWords >= 2;
}
