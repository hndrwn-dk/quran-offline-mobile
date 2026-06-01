import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran_offline/core/audio/audio_paths.dart';
import 'package:quran_offline/core/models/reciter.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';

/// Mushaf page currently visible, or null when not in mushaf mode.
final mushafVisiblePageProvider = StateProvider<int?>((ref) => null);

/// Immutable snapshot of the recitation player exposed to the UI.
class AudioPlayerState {
  /// The surah currently loaded into the playlist, or null when idle.
  final int? surahId;

  /// Current position: [Bismillah.audioAyahNo] for standalone Bismillah, else 1..N.
  final int? ayahNo;

  /// Whether audio is actively playing (vs paused).
  final bool isPlaying;

  /// Whether the player is buffering or loading a track.
  final bool isLoading;

  /// Human-readable surah label for the mini player.
  final String? surahLabel;

  /// Last error message (e.g. offline with no cached audio), or null.
  final String? error;

  const AudioPlayerState({
    this.surahId,
    this.ayahNo,
    this.isPlaying = false,
    this.isLoading = false,
    this.surahLabel,
    this.error,
  });

  /// Whether a recitation session is currently active (loaded).
  bool get isActive => surahId != null;

  /// True while the standalone Bismillah clip is playing.
  bool get isPlayingBismillah => ayahNo == Bismillah.audioAyahNo;

  AudioPlayerState copyWith({
    int? surahId,
    int? ayahNo,
    bool? isPlaying,
    bool? isLoading,
    String? surahLabel,
    String? error,
    bool clearError = false,
  }) {
    return AudioPlayerState(
      surahId: surahId ?? this.surahId,
      ayahNo: ayahNo ?? this.ayahNo,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      surahLabel: surahLabel ?? this.surahLabel,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const idle = AudioPlayerState();
}

/// Wraps a single [AudioPlayer] and drives per-ayah / full-surah recitation.
///
/// For surahs with a separate Bismillah, the playlist is:
/// `[Bismillah (000), ayah 1, ayah 2, ...]`.
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  AudioPlayerNotifier(this._ref) : super(AudioPlayerState.idle) {
    _init();
  }

  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();

  int? _sessionSurahId;

  /// True while building/attaching a surah playlist (avoids isLoading flicker).
  bool _preparingPlaylist = false;

  /// When true, the player holds a single ayah; [next]/[previous] step one ayah.
  bool _singleAyahMode = false;

  /// Whether single-ayah stepping may stream missing ayahs (reader/online).
  bool _singleAyahAllowStreaming = true;

  void _init() {
    _player.playerStateStream.listen((ps) {
      final streamLoading = ps.processingState == ProcessingState.loading ||
          ps.processingState == ProcessingState.buffering;
      final loading = _preparingPlaylist || streamLoading;
      if (ps.processingState == ProcessingState.completed) {
        state = state.copyWith(isPlaying: false, isLoading: loading);
      } else {
        state = state.copyWith(isPlaying: ps.playing, isLoading: loading);
      }
    });

    _player.currentIndexStream.listen((index) {
      // Single-ayah clips use index 0; do not map that to Bismillah on surahs 2+.
      if (index == null ||
          _sessionSurahId == null ||
          _singleAyahMode ||
          _preparingPlaylist) {
        return;
      }
      _syncAyahFromPlaylistIndex(index);
    });
  }

  void _syncAyahFromPlaylistIndex(int index) {
    final surahId = _sessionSurahId;
    if (surahId == null) return;
    final ayah = Bismillah.ayahFromPlaylistIndex(surahId, index);
    if (state.ayahNo != ayah) {
      state = state.copyWith(ayahNo: ayah);
    }
  }

  void _setAyahNo(int ayahNo) {
    if (state.ayahNo != ayahNo) {
      state = state.copyWith(ayahNo: ayahNo);
    }
  }

  /// Plays the whole surah from Bismillah (if any) then ayah 1..N.
  Future<void> playSurah(int surahId, {String? surahName}) async {
    await _loadAndPlay(
      surahId,
      Bismillah.playSurahStartAyah(surahId),
      surahName,
      allowStreaming: true,
    );
  }

  /// Plays exactly the tapped ayah only and stops at its end (reader per-ayah).
  /// Use [playSurah] for continuous playback; mini player next/prev steps ayahs.
  Future<void> playAyah(int surahId, int ayahNo, {String? surahName}) async {
    await playSingleAyah(surahId, ayahNo, surahName: surahName);
  }

  /// Plays exactly the tapped ayah (mushaf). Ayah 1 is Alif Lam Mim, not Bismillah.
  Future<void> playAyahExact(int surahId, int ayahNo, {String? surahName}) async {
    await playSingleAyah(surahId, ayahNo, surahName: surahName);
  }

  /// Loads a single ayah ([Bismillah.audioAyahNo] for standalone Bismillah) and
  /// plays it without auto-advancing. Prefers local cache, streams as fallback.
  Future<void> playSingleAyah(
    int surahId,
    int ayahNo, {
    String? surahName,
    bool allowStreaming = true,
  }) async {
    final reciter = _ref.read(reciterProvider);
    final label = surahName ?? state.surahLabel ?? 'Surah $surahId';
    final title = _trackTitle(label, ayahNo);

    await _detachCurrentPlayback();

    _preparingPlaylist = true;
    _singleAyahMode = true;
    _singleAyahAllowStreaming = allowStreaming;
    state = state.copyWith(
      surahId: surahId,
      ayahNo: ayahNo,
      surahLabel: label,
      isLoading: true,
      clearError: true,
    );

    var source = await _sourceForLocal(reciter, surahId, ayahNo, label, title);
    if (source == null && allowStreaming) {
      source = await _sourceFor(
        reciter,
        surahId,
        ayahNo,
        label,
        title,
        localOnly: false,
        allowStreaming: true,
      );
    }

    if (source == null) {
      _preparingPlaylist = false;
      _singleAyahMode = false;
      _sessionSurahId = null;
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error:
            'This surah is not saved on your device yet. Use Save to download it for offline playback.',
      );
      return;
    }

    try {
      _sessionSurahId = surahId;
      await _player.setAudioSource(source);
      _preparingPlaylist = false;
      state = state.copyWith(ayahNo: ayahNo, clearError: true);
      await _player.play();
    } catch (e) {
      _preparingPlaylist = false;
      _singleAyahMode = false;
      _sessionSurahId = null;
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: 'Playback failed: $e',
      );
    }
  }

  Future<void> _detachCurrentPlayback() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> _loadAndPlay(
    int surahId,
    int startAyah,
    String? surahName, {
    bool allowStreaming = true,
  }) async {
    final reciter = _ref.read(reciterProvider);
    final db = _ref.read(databaseProvider);
    final downloads = _ref.read(audioDownloadProvider);
    final surahDownloaded =
        downloads.isComplete(reciter.id, surahId);

    final sameSurahSession = _sessionSurahId == surahId;
    final canSeekInPlaylist = sameSurahSession &&
        _player.audioSource != null &&
        !_singleAyahMode;

    if (canSeekInPlaylist) {
      final index = Bismillah.playlistIndex(surahId, startAyah);
      // Block index echoes only while seeking; clear before play (play() does
      // not resolve until playback ends, so it must not gate the index stream).
      _preparingPlaylist = true;
      try {
        await _player.seek(Duration.zero, index: index);
      } finally {
        _preparingPlaylist = false;
      }
      state = state.copyWith(
        surahId: surahId,
        ayahNo: startAyah,
        surahLabel: surahName ?? state.surahLabel ?? 'Surah $surahId',
        clearError: true,
      );
      await _player.play();
      return;
    }

    if (_sessionSurahId != surahId || _singleAyahMode) {
      await _detachCurrentPlayback();
    }

    _preparingPlaylist = true;
    _singleAyahMode = false;
    state = state.copyWith(
      surahId: surahId,
      ayahNo: startAyah,
      surahLabel: surahName ?? 'Surah $surahId',
      isLoading: true,
      clearError: true,
    );

    final ayahCount = await db.getAyahCountForSurah(surahId);
    if (ayahCount <= 0) {
      _preparingPlaylist = false;
      _sessionSurahId = null;
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: 'No audio available',
      );
      return;
    }

    final label = surahName ?? 'Surah $surahId';

    if (!surahDownloaded && !allowStreaming) {
      final title = _trackTitle(label, startAyah);
      var source = await _sourceForLocal(
        reciter,
        surahId,
        startAyah,
        label,
        title,
      );
      // Mushaf: play the tapped ayah via stream if not cached (never leave prior surah playing).
      source ??= await _sourceFor(
        reciter,
        surahId,
        startAyah,
        label,
        title,
        localOnly: false,
        allowStreaming: true,
      );
      if (source == null) {
        _preparingPlaylist = false;
        _sessionSurahId = null;
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          error:
              'This surah is not saved on your device yet. Use Save to download it for offline playback.',
        );
        return;
      }
      try {
        _sessionSurahId = surahId;
        _singleAyahMode = true;
        await _player.setAudioSource(source);
        _preparingPlaylist = false;
        state = state.copyWith(ayahNo: startAyah, clearError: true);
        await _player.play();
      } catch (e) {
        _preparingPlaylist = false;
        _sessionSurahId = null;
        _singleAyahMode = false;
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          error: 'Playback failed: $e',
        );
      }
      return;
    }

    final sources = await _buildSources(
      reciter,
      surahId,
      ayahCount,
      surahName,
      localOnly: surahDownloaded || !allowStreaming,
      allowStreaming: allowStreaming,
    );
    if (sources.isEmpty) {
      _preparingPlaylist = false;
      _sessionSurahId = null;
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: surahDownloaded
            ? 'No audio available'
            : 'Audio not downloaded. Download this surah in Settings for offline playback.',
      );
      return;
    }

    final initialIndex = Bismillah.playlistIndex(surahId, startAyah)
        .clamp(0, sources.length - 1);

    try {
      _sessionSurahId = surahId;
      await _player.setAudioSources(
        sources,
        initialIndex: initialIndex,
        initialPosition: Duration.zero,
      );
      // Clear before play(): play() resolves only when playback ends, so it
      // must not keep the index stream gated while audio advances.
      _preparingPlaylist = false;
      _setAyahNo(startAyah);
      await _player.play();
    } catch (e) {
      _preparingPlaylist = false;
      _sessionSurahId = null;
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: 'Playback failed: $e',
      );
    }
  }

  String _trackTitle(String label, int ayahNo) {
    if (ayahNo == Bismillah.audioAyahNo) return '$label - Bismillah';
    return '$label - Ayah $ayahNo';
  }

  Future<List<AudioSource>> _buildSources(
    Reciter reciter,
    int surahId,
    int ayahCount,
    String? surahName, {
    required bool localOnly,
    required bool allowStreaming,
  }) async {
    final label = surahName ?? 'Surah $surahId';
    final sources = <AudioSource>[];

    if (Bismillah.hasBismillahAudio(surahId)) {
      final bismillah = await _sourceFor(
        reciter,
        surahId,
        Bismillah.audioAyahNo,
        label,
        '$label - Bismillah',
        localOnly: localOnly,
        allowStreaming: allowStreaming,
      );
      if (bismillah != null) sources.add(bismillah);
    }

    for (var ayah = 1; ayah <= ayahCount; ayah++) {
      final source = await _sourceFor(
        reciter,
        surahId,
        ayah,
        label,
        '$label - Ayah $ayah',
        localOnly: localOnly,
        allowStreaming: allowStreaming,
      );
      if (source != null) sources.add(source);
    }
    return sources;
  }

  Future<AudioSource?> _sourceForLocal(
    Reciter reciter,
    int surahId,
    int ayahNo,
    String album,
    String title,
  ) async {
    return _sourceFor(
      reciter,
      surahId,
      ayahNo,
      album,
      title,
      localOnly: true,
      allowStreaming: false,
    );
  }

  Future<AudioSource?> _sourceFor(
    Reciter reciter,
    int surahId,
    int ayahNo,
    String album,
    String title, {
    required bool localOnly,
    required bool allowStreaming,
  }) async {
    final file = await AudioPaths.localFile(reciter.id, surahId, ayahNo);
    final exists = await file.exists();
    if (!exists && localOnly) return null;
    if (!exists && !allowStreaming) return null;
    final Uri uri = exists
        ? Uri.file(file.path)
        : Uri.parse(AudioPaths.remoteUrl(reciter, surahId, ayahNo));
    return AudioSource.uri(
      uri,
      tag: MediaItem(
        id: '${reciter.id}_${surahId}_$ayahNo',
        album: album,
        title: title,
        artist: reciter.name,
      ),
    );
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Replays the current track from its start (used when a track has finished).
  Future<void> restart() async {
    try {
      await _player.seek(Duration.zero, index: _singleAyahMode ? null : 0);
    } catch (_) {}
    await _player.play();
  }

  Future<void> next() async {
    if (_singleAyahMode && _sessionSurahId != null) {
      await _stepSingleAyah(1);
      return;
    }
    await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_singleAyahMode && _sessionSurahId != null) {
      await _stepSingleAyah(-1);
      return;
    }
    await _player.seekToPrevious();
  }

  /// Steps single-ayah playback by [delta] over [Bismillah, 1..N], stopping at bounds.
  Future<void> _stepSingleAyah(int delta) async {
    final surahId = _sessionSurahId!;
    final db = _ref.read(databaseProvider);
    final ayahCount = await db.getAyahCountForSurah(surahId);
    if (ayahCount <= 0) return;

    final hasBismillah = Bismillah.hasBismillahAudio(surahId);
    final current = state.ayahNo ?? 1;
    int target;
    if (delta > 0) {
      target = current == Bismillah.audioAyahNo ? 1 : current + 1;
      if (target > ayahCount) return;
    } else {
      if (current == Bismillah.audioAyahNo) return;
      if (current <= 1) {
        if (!hasBismillah) return;
        target = Bismillah.audioAyahNo;
      } else {
        target = current - 1;
      }
    }

    await playSingleAyah(
      surahId,
      target,
      surahName: state.surahLabel,
      allowStreaming: _singleAyahAllowStreaming,
    );
  }

  Future<void> stop() async {
    _sessionSurahId = null;
    _singleAyahMode = false;
    _preparingPlaylist = false;
    await _player.stop();
    state = AudioPlayerState.idle;
  }

  bool isCurrent(int surahId, int ayahNo) =>
      state.surahId == surahId && state.ayahNo == ayahNo;

  bool isCurrentBismillah(int surahId) =>
      state.surahId == surahId && state.isPlayingBismillah;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier(ref);
});

/// True when the visible mushaf [pageNo] should show recitation chrome/controls.
///
/// autoDispose so per-page instances are released as the user scrolls instead
/// of accumulating one cached provider per visited mushaf page.
final mushafPageShowsRecitationProvider =
    FutureProvider.autoDispose.family<bool, int>((ref, pageNo) async {
  final audio = ref.watch(audioPlayerProvider);
  if (!audio.isActive || audio.surahId == null || audio.ayahNo == null) {
    return false;
  }
  return MushafLayout.pageContainsRecitation(
    pageNo,
    audio.surahId!,
    audio.ayahNo!,
  );
});

/// True when the visible mushaf page shows the playing ayah (inline app bar controls).
final recitationOnCurrentMushafPageProvider = FutureProvider<bool>((ref) async {
  final pageNo = ref.watch(mushafVisiblePageProvider);
  final audio = ref.watch(audioPlayerProvider);
  if (pageNo == null ||
      !audio.isActive ||
      audio.surahId == null ||
      audio.ayahNo == null) {
    return false;
  }
  return MushafLayout.pageContainsRecitation(
    pageNo,
    audio.surahId!,
    audio.ayahNo!,
  );
});
