import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';

/// How [openPlayingRecitation] should navigate without pushing duplicate routes.
enum RecitationOpenStrategy {
  none,
  jumpMushaf,
  pushMushaf,
  jumpReader,
  pushReader,
}

bool readerShowsPlayingSurah(ReaderSource? source, int surahId) {
  if (source is SurahSource) return source.surahId == surahId;
  if (source is SurahInJuzSource) return source.surahId == surahId;
  return false;
}

bool juzReaderShowsPlayingSurah(List<Verse>? verses, int surahId) {
  if (verses == null) return false;
  return verses.any((v) => v.surahId == surahId);
}

/// Whether the global mini player should be hidden (inline reader covers playback).
bool shouldHideGlobalRecitationBar({
  required bool audioActive,
  required int? playingSurahId,
  required ReaderSource? readerSource,
  required bool splitLayout,
  required bool onReadTab,
  required bool readerScreenVisible,
  required List<Verse>? juzVerses,
}) {
  if (!audioActive || playingSurahId == null) return false;

  final inlineReaderContext =
      (splitLayout && onReadTab) || (!splitLayout && readerScreenVisible);

  if (!inlineReaderContext) return false;

  if (readerShowsPlayingSurah(readerSource, playingSurahId)) {
    return true;
  }
  if (readerSource is JuzSource) {
    return juzReaderShowsPlayingSurah(juzVerses, playingSurahId);
  }
  return false;
}

RecitationOpenStrategy resolveRecitationOpenStrategy({
  required bool audioActive,
  required int? playingSurahId,
  required RecitationReturnSurface? returnSurface,
  required bool mushafSessionActive,
  required bool readerScreenVisible,
  required bool readerSplitLayout,
}) {
  if (!audioActive || playingSurahId == null) {
    return RecitationOpenStrategy.none;
  }

  final surface = returnSurface ?? RecitationReturnSurface.reader;

  if (surface == RecitationReturnSurface.mushaf) {
    return mushafSessionActive
        ? RecitationOpenStrategy.jumpMushaf
        : RecitationOpenStrategy.pushMushaf;
  }

  if (readerSplitLayout || readerScreenVisible) {
    return RecitationOpenStrategy.jumpReader;
  }

  return RecitationOpenStrategy.pushReader;
}
