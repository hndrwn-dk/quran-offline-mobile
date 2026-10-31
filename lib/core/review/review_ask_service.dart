import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/review/reading_completion.dart';
import 'package:quran_offline/core/review/review_ask_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a Play review at most once, at a reading completion moment.
final reviewAskServiceProvider = Provider<ReviewAskService>((ref) {
  return ReviewAskService(ref);
});

class ReviewAskService {
  ReviewAskService(this._ref);

  final Ref _ref;
  Future<ReviewAskController>? _controller;
  bool _inFlight = false;

  Future<ReviewAskController> _ensureController() {
    return _controller ??= SharedPreferences.getInstance().then(
      (prefs) => ReviewAskController(
        prefs: prefs,
        requestReview: () => InAppReview.instance.requestReview(),
      ),
    );
  }

  /// Called with the topmost visible verse from the surah reader.
  Future<void> onReaderPosition({
    required ReaderSource source,
    required List<Verse> verses,
    required int verseIndex,
  }) async {
    if (!isSurahCompletion(source, verses, verseIndex)) return;
    await _ask();
  }

  /// Called when the mushaf shows a page.
  Future<void> onMushafPage(int pageNo) async {
    try {
      if ((await _ensureController()).hasRequested) return;

      final db = _ref.read(databaseProvider);
      final pageVerses = await db.getVersesByPage(pageNo);
      if (pageVerses.isEmpty) return;

      final juzVerses = await db.getVersesByJuz(pageVerses.first.juz);
      if (!isLastPageOfJuz(
        pageNo: pageNo,
        pageVerses: pageVerses,
        juzVerses: juzVerses,
      )) {
        return;
      }

      await _ask();
    } catch (_) {
      // Silent: prompting must never affect reading.
    }
  }

  bool _audioPlaying() => _ref.read(audioPlayerProvider).isPlaying;

  Future<void> _ask() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final controller = await _ensureController();
      if (controller.hasRequested) return;
      await controller.onCompletion(isAudioPlaying: _audioPlaying);
    } catch (_) {
      // Silent by design.
    } finally {
      _inFlight = false;
    }
  }
}
