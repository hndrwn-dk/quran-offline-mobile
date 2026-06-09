import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/audio/phoneme_checker.dart';
import 'package:quran_offline/core/audio/playback_actions.dart';
import 'package:quran_offline/core/audio/setoran_speech_checker.dart';
import 'package:quran_offline/core/audio/setoran_speech_recognizer.dart';
import 'package:quran_offline/core/quran/tajweed_rule_parser.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/juz_amma_hafalan.dart';
import 'package:quran_offline/core/providers/juz_amma_hafalan_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/voice_input_settings.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/features/hafalan/models/setoran_ayah_fade_state.dart';
import 'package:quran_offline/features/hafalan/models/setoran_check_feedback.dart';
import 'package:quran_offline/features/hafalan/models/setoran_session_summary.dart';
import 'package:quran_offline/features/hafalan/setoran_session_summary_screen.dart';
import 'package:quran_offline/features/hafalan/widgets/setoran_check_result_card.dart';
import 'package:quran_offline/features/hafalan/widgets/setoran_fade_ayah_text.dart';
import 'package:quran_offline/features/hafalan/widgets/tajwid_detail_panel.dart';

class SetoranSessionScreen extends ConsumerStatefulWidget {
  const SetoranSessionScreen({super.key, required this.unit});

  final JuzAmmaUnit unit;

  @override
  ConsumerState<SetoranSessionScreen> createState() =>
      _SetoranSessionScreenState();
}

class _SetoranSessionScreenState extends ConsumerState<SetoranSessionScreen> {
  final SetoranSpeechRecognizer _speech = SetoranSpeechRecognizer();

  List<Verse> _verses = [];
  int _index = 0;
  bool _loading = true;
  bool _isDone = false;
  List<SetoranAyahFadeState> _ayahStates = [];
  bool _checkingSpeech = false;
  bool _isCheckListening = false;
  String _liveTranscript = '';
  bool _speechReady = false;
  bool _probingArabicVoice = false;
  String? _detectedArabicLocale;
  String? _arabicRecheckNote;
  SetoranCheckFeedback? _checkFeedback;
  PhonemeCheckResult? _lastPhonemeResult;
  TajweedRuleMap? _lastTajweedMap;
  final Map<int, PhonemeCheckResult> _phonemeByAyah = {};
  final Map<int, double> _speechScoreByAyah = {};
  int? _advanceAfterCorrectFromIndex;

  @override
  void initState() {
    super.initState();
    unawaited(_initSpeech());
    _load();
  }

  bool get _arabicVoiceReady =>
      _speechReady && _detectedArabicLocale != null;

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize();
    if (!mounted) return;
    setState(() => _speechReady = ok);
    if (ok) await _probeArabicVoice();
  }

  Future<void> _probeArabicVoice() async {
    if (!_speechReady) return;
    setState(() {
      _probingArabicVoice = true;
      _arabicRecheckNote = null;
    });
    final probe = await _speech.probeArabicVoice();
    if (!mounted) return;
    setState(() {
      _probingArabicVoice = false;
      _detectedArabicLocale =
          probe.isReady ? probe.localeId : null;
    });
  }

  Future<void> _recheckArabicLocale() async {
    setState(() {
      _probingArabicVoice = true;
      _arabicRecheckNote = null;
    });
    final probe = await _speech.probeArabicVoice();
    if (!mounted) return;
    final lang = ref.read(settingsProvider).appLanguage;
    setState(() {
      _probingArabicVoice = false;
      _detectedArabicLocale =
          probe.isReady ? probe.localeId : null;
      _arabicRecheckNote = probe.isReady
          ? AppLocalizations.getSetoranArabicVoiceRecheckOk(
              lang,
              probe.localeId!,
            )
          : AppLocalizations.getSetoranArabicVoiceRecheckFail(lang);
    });
  }

  void _showArabicVoiceBlockedDialog(String lang) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.getSetoranArabicVoiceBlockedTitle(lang)),
        content: Text(AppLocalizations.getSetoranArabicVoiceBlockedBody(lang)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showArabicVoiceStepsDialog(lang);
            },
            child: Text(AppLocalizations.getSetoranArabicVoiceShowSteps(lang)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              unawaited(openVoiceInputSettings());
            },
            child: Text(
              AppLocalizations.getSetoranArabicVoiceOpenSettings(lang),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  void _onCheckBacaanPressed(BuildContext context, String lang) {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.getSetoranSpeechUnavailable(lang)),
        ),
      );
      return;
    }
    if (!_arabicVoiceReady) {
      _showArabicVoiceBlockedDialog(lang);
      return;
    }
    unawaited(_startCheckListen(context, lang));
  }

  void _showArabicVoiceStepsDialog(String lang) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.getSetoranArabicVoiceShowSteps(lang)),
        content: SingleChildScrollView(
          child: Text(
            AppLocalizations.getSetoranArabicVoiceSetupSteps(lang),
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_speech.dispose());
    super.dispose();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final verses = await db.getVersesByRange(
      widget.unit.surah,
      widget.unit.from,
      widget.unit.to,
    );
    final fridayKey = fridayKeyFor(DateTime.now());
    final logs = await db.getSetoranLogsForFriday(fridayKey);
    final key = setoranItemKey(widget.unit);
    final done = logs.any((l) => l.itemKey == key);
    if (mounted) {
      setState(() {
        _verses = verses;
        _ayahStates = List.filled(
          verses.length,
          SetoranAyahFadeState.ghost,
        );
        _loading = false;
        _isDone = done;
      });
    }
  }

  Future<void> _cancelCheck() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  void _goToIndex(int i) {
    unawaited(_cancelCheck());
    setState(() {
      _index = i;
      _liveTranscript = '';
      _isCheckListening = false;
      _checkFeedback = null;
      _lastPhonemeResult = null;
      _lastTajweedMap = null;
      _advanceAfterCorrectFromIndex = null;
    });
  }

  void _runPhonemeCheck(String transcript, Verse verse, String lang) {
    if (setoranTranscriptLooksLatin(transcript)) {
      setState(() {
        _lastPhonemeResult = null;
        _lastTajweedMap = null;
      });
      return;
    }

    final result = PhonemeChecker.check(
      transcript: transcript,
      translitTj: verse.translitTj,
      tajweedHtml: verse.tajweed,
      arabic: verse.arabic,
      language: lang,
    );
    final tajweedMap = TajweedRuleParser.parse(verse.tajweed);

    setState(() {
      _lastPhonemeResult = result;
      _lastTajweedMap = tajweedMap;
      _phonemeByAyah[_index] = result;
    });
  }

  Future<void> _openSessionSummary(
    BuildContext context,
    String lang,
    String surahName,
    String refText,
  ) async {
    final summary = SetoranSessionSummaryBuilder.build(
      verses: _verses,
      states: _ayahStates,
      phonemeByAyah: _phonemeByAyah,
      speechScoreByAyah: _speechScoreByAyah,
      lang: lang,
    );

    final result = await Navigator.of(context).push<SetoranSummaryResult>(
      MaterialPageRoute(
        builder: (_) => SetoranSessionSummaryScreen(
          unit: widget.unit,
          summary: summary,
          surahLabel: surahName,
          ayahRef: refText,
        ),
      ),
    );

    if (!mounted) return;

    if (result == SetoranSummaryResult.markedDone) {
      setState(() => _isDone = true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.getFridaySetoranDone(lang)),
          ),
        );
      }
      return;
    }

    if (result == SetoranSummaryResult.retryAyah &&
        summary.reviewAyahIndices.isNotEmpty) {
      _goToIndex(summary.reviewAyahIndices.first);
    }
  }

  Future<void> _startCheckListen(BuildContext context, String lang) async {
    if (_isCheckListening) return;
    if (!_speechReady) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.getSetoranSpeechUnavailable(lang)),
          ),
        );
      }
      return;
    }
    await PlaybackActions.stopIfActive(ref);
    setState(() {
      _isCheckListening = true;
      _liveTranscript = '';
      _checkFeedback = null;
    });
    final result = await _speech.startListening(
      onWords: (words) {
        if (mounted) setState(() => _liveTranscript = words);
      },
    );
    if (!mounted) return;
    if (result != SetoranSpeechStartResult.started) {
      setState(() => _isCheckListening = false);
      if (!context.mounted) return;
      final message = result == SetoranSpeechStartResult.noArabicLocale
          ? AppLocalizations.getSetoranSpeechArabicRequired(lang)
          : AppLocalizations.getSetoranSpeechUnavailable(lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<void> _finishCheckListen(
    BuildContext context,
    String lang,
    Verse verse,
  ) async {
    if (!_isCheckListening && !_speech.isListening) return;
    setState(() => _checkingSpeech = true);
    final transcript = await _speech.stopAndGetTranscript();
    if (!mounted) return;
    setState(() {
      _isCheckListening = false;
      _checkingSpeech = false;
      _liveTranscript = transcript;
    });
    if (!context.mounted) return;

    if (transcript.isEmpty) {
      setState(() {
        _checkFeedback = SetoranCheckFeedback(
          kind: SetoranCheckFeedbackKind.empty,
        );
        _lastPhonemeResult = null;
        _lastTajweedMap = null;
      });
      return;
    }

    if (setoranTranscriptLooksLatin(transcript)) {
      if (_ayahStates[_index] == SetoranAyahFadeState.error) {
        setState(() => _ayahStates[_index] = SetoranAyahFadeState.ghost);
      }
      setState(() {
        _checkFeedback = SetoranCheckFeedback(
          kind: SetoranCheckFeedbackKind.wrongLanguage,
          transcript: transcript,
        );
        _lastPhonemeResult = null;
        _lastTajweedMap = null;
      });
      return;
    }

    final result = SetoranSpeechChecker.check(
      transcript: transcript,
      verse: verse,
    );
    _applySpeechResult(result, transcript: transcript, verse: verse, lang: lang);
  }

  void _applySpeechResult(
    SetoranSpeechCheckResult result, {
    required String transcript,
    required Verse verse,
    required String lang,
  }) {
    final feedbackKind = switch (result.verdict) {
      SetoranSpeechVerdict.correct => SetoranCheckFeedbackKind.correct,
      SetoranSpeechVerdict.incorrect => SetoranCheckFeedbackKind.incorrect,
      SetoranSpeechVerdict.uncertain => SetoranCheckFeedbackKind.uncertain,
    };

    setState(() {
      _checkFeedback = SetoranCheckFeedback.fromVerdict(
        kind: feedbackKind,
        transcript: transcript,
        score: result.score,
      );
      _speechScoreByAyah[_index] = result.score;
    });
    _runPhonemeCheck(transcript, verse, lang);

    switch (result.verdict) {
      case SetoranSpeechVerdict.correct:
        if (_ayahStates[_index] != SetoranAyahFadeState.revealed) {
          setState(() {
            _ayahStates[_index] = SetoranAyahFadeState.revealed;
          });
          _scheduleAdvanceAfterCorrect();
        }
      case SetoranSpeechVerdict.incorrect:
        setState(() => _ayahStates[_index] = SetoranAyahFadeState.error);
      case SetoranSpeechVerdict.uncertain:
        break;
    }
  }

  void _scheduleAdvanceAfterCorrect() {
    final from = _index;
    _advanceAfterCorrectFromIndex = from;
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_advanceAfterCorrectFromIndex != from) return;
      if (_index != from) return;
      _advanceAfterCorrectFromIndex = null;
      if (from < _verses.length - 1) {
        _goToIndex(from + 1);
      } else {
        unawaited(_cancelCheck());
      }
    });
  }

  Verse? get _current =>
      _verses.isEmpty || _index >= _verses.length ? null : _verses[_index];

  int get _revealedCount =>
      _ayahStates.where((s) => s == SetoranAyahFadeState.revealed).length;

  bool get _allRevealed =>
      _verses.isNotEmpty && _revealedCount == _verses.length;

  void _markCurrentCorrect() {
    setState(() {
      _ayahStates[_index] = SetoranAyahFadeState.revealed;
    });
    if (_index < _verses.length - 1) {
      _goToIndex(_index + 1);
    } else {
      unawaited(_cancelCheck());
    }
  }

  void _markCurrentError() {
    setState(() {
      _ayahStates[_index] = SetoranAyahFadeState.error;
    });
  }

  void _resetCurrentAyah() {
    setState(() {
      _ayahStates[_index] = SetoranAyahFadeState.ghost;
      _checkFeedback = null;
      _lastPhonemeResult = null;
      _lastTajweedMap = null;
      _phonemeByAyah.remove(_index);
      _speechScoreByAyah.remove(_index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).appLanguage;
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surahs = ref.watch(surahNamesProvider).valueOrNull;
    final surahName = surahs == null
        ? 'Surah ${widget.unit.surah}'
        : surahs
            .firstWhere(
              (s) => s.id == widget.unit.surah,
              orElse: () => surahs.first,
            )
            .englishName;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.getSetoranSessionTitle(lang)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_verses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.getSetoranSessionTitle(lang)),
        ),
        body: const Center(child: Text('No verses')),
      );
    }

    final verse = _current!;
    final currentState = _ayahStates[_index];
    final refText = AppLocalizations.formatJuzAmmaAyahRef(
      widget.unit.surah,
      widget.unit.from,
      widget.unit.to,
      lang,
    );
    final arabicFontSize = settings.arabicFontSize + 4;

    String? translation;
    final raw = switch (lang) {
      'en' => verse.trEn,
      'id' => verse.trId,
      'zh' => verse.trZh,
      'ja' => verse.trJa,
      _ => verse.trId,
    };
    if (raw != null && raw.isNotEmpty) {
      translation = TranslationCleaner.clean(raw);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.getSetoranSessionTitle(lang),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '$surahName · $refText',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _revealedCount / _verses.length,
            minHeight: 3,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.getSetoranFadeModeHint(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  if (_speechReady) ...[
                    const SizedBox(height: 10),
                    _ArabicVoiceStatusBanner(
                      lang: lang,
                      ready: _arabicVoiceReady,
                      probing: _probingArabicVoice,
                      localeId: _detectedArabicLocale,
                      recheckNote: _arabicRecheckNote,
                      onShowSteps: () => _showArabicVoiceStepsDialog(lang),
                      onOpenSettings: () => unawaited(openVoiceInputSettings()),
                      onRecheck: () => unawaited(_recheckArabicLocale()),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _AyahProgressStrip(
                    verses: _verses,
                    states: _ayahStates,
                    currentIndex: _index,
                    onTap: _goToIndex,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.getSetoranRevealAllHint(
                      lang,
                      _revealedCount,
                      _verses.length,
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${verse.surahId}:${verse.ayahNo}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: SetoranFadeAyahText.revealDuration,
                    child: KeyedSubtree(
                      key: ValueKey('${verse.surahId}:${verse.ayahNo}'),
                      child: SetoranFadeAyahText(
                        arabic: verse.arabic,
                        tajweedHtml: verse.tajweed,
                        fontSize: arabicFontSize + 4,
                        state: currentState,
                        isLightTheme: isLight,
                        listeningForCheck: _isCheckListening,
                      ),
                    ),
                  ),
                  if (currentState == SetoranAyahFadeState.revealed &&
                      translation != null) ...[
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: 1,
                      duration: SetoranFadeAyahText.revealDuration,
                      child: Text(
                        translation,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_previous),
                        tooltip: AppLocalizations.getSetoranPrevAyah(lang),
                        onPressed: _index > 0 && !_isCheckListening
                            ? () => _goToIndex(_index - 1)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.volume_up),
                        tooltip: AppLocalizations.getSetoranPlayAyah(lang),
                        onPressed: _isCheckListening
                            ? null
                            : () async {
                                await _cancelCheck();
                                if (!context.mounted) return;
                                await PlaybackActions.playAyah(
                                  context,
                                  ref,
                                  verse.surahId,
                                  verse.ayahNo,
                                  surahName: surahName,
                                );
                              },
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.skip_next),
                        tooltip: AppLocalizations.getSetoranNextAyah(lang),
                        onPressed: _index < _verses.length - 1 &&
                                !_isCheckListening
                            ? () => _goToIndex(_index + 1)
                            : null,
                      ),
                    ],
                  ),
                  if (_isCheckListening) ...[
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.getSetoranCheckListeningHint(lang),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (_liveTranscript.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.formatSetoranHeardTranscript(
                          lang,
                          _liveTranscript,
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _checkingSpeech
                          ? null
                          : () => _finishCheckListen(context, lang, verse),
                      icon: const Icon(Icons.check),
                      label: Text(AppLocalizations.getSetoranFinishCheck(lang)),
                    ),
                  ],
                  if (!_isCheckListening &&
                      currentState != SetoranAyahFadeState.revealed) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isCheckListening ||
                              currentState == SetoranAyahFadeState.revealed
                          ? null
                          : () => _onCheckBacaanPressed(context, lang),
                      icon: const Icon(Icons.hearing),
                      label: Text(
                        AppLocalizations.getSetoranCheckRecitation(lang),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.getSetoranCheckOnlyHint(lang),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (_checkingSpeech) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.getSetoranSpeechChecking(lang),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                  if (_checkFeedback != null && !_isCheckListening) ...[
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      child: SetoranCheckResultCard(
                        key: ValueKey(
                          '${_index}_${_checkFeedback!.kind}_${_checkFeedback!.transcript}',
                        ),
                        feedback: _checkFeedback!,
                        lang: lang,
                      ),
                    ),
                    if (_lastPhonemeResult != null &&
                        _lastTajweedMap != null &&
                        _checkFeedback!.kind !=
                            SetoranCheckFeedbackKind.wrongLanguage &&
                        _checkFeedback!.kind !=
                            SetoranCheckFeedbackKind.empty)
                      TajwidDetailPanel(
                        key: ValueKey(
                          'tajwid_${_index}_${_checkFeedback!.transcript}',
                        ),
                        phonemeResult: _lastPhonemeResult!,
                        tajweedMap: _lastTajweedMap!,
                        lang: lang,
                      ),
                  ],
                  const SizedBox(height: 16),
                  if (currentState == SetoranAyahFadeState.error) ...[
                    FilledButton.tonal(
                      onPressed: _resetCurrentAyah,
                      child: Text(
                        AppLocalizations.getSetoranAyahReset(lang),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: currentState == SetoranAyahFadeState.revealed
                              ? null
                              : _markCurrentError,
                          child: Text(
                            AppLocalizations.getSetoranAyahRetry(lang),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: currentState == SetoranAyahFadeState.revealed
                              ? null
                              : _markCurrentCorrect,
                          child: Text(
                            AppLocalizations.getSetoranAyahCorrect(lang),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._verses.asMap().entries.map((entry) {
                    final i = entry.key;
                    final v = entry.value;
                    final st = _ayahStates[i];
                    final isCurrent = i == _index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: isCurrent
                            ? colorScheme.primaryContainer
                                .withValues(alpha: 0.35)
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _goToIndex(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${v.ayahNo}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: switch (st) {
                                            SetoranAyahFadeState.revealed =>
                                              colorScheme.primary,
                                            SetoranAyahFadeState.error =>
                                              colorScheme.error,
                                            SetoranAyahFadeState.ghost =>
                                              colorScheme.onSurfaceVariant,
                                          },
                                        ),
                                  ),
                                ),
                                Expanded(
                                  child: SetoranFadeAyahText(
                                    arabic: v.arabic,
                                    tajweedHtml: v.tajweed,
                                    fontSize: settings.arabicFontSize - 2,
                                    state: st,
                                    isLightTheme: isLight,
                                    compact: true,
                                  ),
                                ),
                                if (st == SetoranAyahFadeState.revealed)
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: colorScheme.primary,
                                  )
                                else if (st == SetoranAyahFadeState.error)
                                  Icon(
                                    Icons.error_outline,
                                    size: 18,
                                    color: colorScheme.error,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.getSetoranTeacherNote(lang),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_isDone)
                    OutlinedButton(
                      onPressed: () async {
                        await unmarkFridaySetoran(ref, widget.unit);
                        setState(() => _isDone = false);
                      },
                      child: Text(
                        AppLocalizations.getFridaySetoranUnmark(lang),
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: _allRevealed
                          ? () => unawaited(
                                _openSessionSummary(
                                  context,
                                  lang,
                                  surahName,
                                  refText,
                                ),
                              )
                          : null,
                      child: Text(
                        _allRevealed
                            ? AppLocalizations.getSetoranSummaryOpen(lang)
                            : AppLocalizations.getFridaySetoranMarkDone(lang),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahProgressStrip extends StatelessWidget {
  const _AyahProgressStrip({
    required this.verses,
    required this.states,
    required this.currentIndex,
    required this.onTap,
  });

  final List<Verse> verses;
  final List<SetoranAyahFadeState> states;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(verses.length, (i) {
          final st = states[i];
          final isCurrent = i == currentIndex;
          final bg = switch (st) {
            SetoranAyahFadeState.revealed => colorScheme.primaryContainer,
            SetoranAyahFadeState.error =>
              colorScheme.errorContainer.withValues(alpha: 0.7),
            SetoranAyahFadeState.ghost =>
              colorScheme.surfaceContainerHighest,
          };
          final border = isCurrent
              ? Border.all(color: colorScheme.primary, width: 2)
              : null;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bg.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: border,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${verses[i].ayahNo}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (st == SetoranAyahFadeState.revealed) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check, size: 14, color: colorScheme.primary),
                    ] else if (st == SetoranAyahFadeState.error) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.close, size: 14, color: colorScheme.error),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ArabicVoiceStatusBanner extends StatelessWidget {
  const _ArabicVoiceStatusBanner({
    required this.lang,
    required this.ready,
    required this.probing,
    required this.localeId,
    required this.recheckNote,
    required this.onShowSteps,
    required this.onOpenSettings,
    required this.onRecheck,
  });

  final String lang;
  final bool ready;
  final bool probing;
  final String? localeId;
  final String? recheckNote;
  final VoidCallback onShowSteps;
  final VoidCallback onOpenSettings;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = ready
        ? colorScheme.primaryContainer.withValues(alpha: 0.45)
        : colorScheme.secondaryContainer.withValues(alpha: 0.45);
    final fg = ready
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    final message = ready && localeId != null
        ? AppLocalizations.getSetoranArabicVoiceReady(lang, localeId!)
        : AppLocalizations.getSetoranArabicVoiceSetupHint(lang);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ready
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (probing)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              else
                Icon(
                  ready ? Icons.check_circle_outline : Icons.info_outline,
                  size: 18,
                  color: fg,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fg,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
          if (recheckNote != null) ...[
            const SizedBox(height: 8),
            Text(
              recheckNote!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (!ready) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                TextButton(onPressed: onShowSteps, child: Text(AppLocalizations.getSetoranArabicVoiceShowSteps(lang))),
                TextButton(
                  onPressed: onOpenSettings,
                  child: Text(
                    AppLocalizations.getSetoranArabicVoiceOpenSettings(lang),
                  ),
                ),
                TextButton(
                  onPressed: probing ? null : onRecheck,
                  child: Text(
                    AppLocalizations.getSetoranArabicVoiceRecheck(lang),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: probing ? null : onRecheck,
                child: Text(AppLocalizations.getSetoranArabicVoiceRecheck(lang)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
