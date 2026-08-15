import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';

void main() {
  group('AudioPlayerState.copyWith', () {
    test('keeps playback context by default', () {
      const active = AudioPlayerState(
        surahId: 2,
        ayahNo: 5,
        surahLabel: 'Al-Baqarah',
        isPlaying: true,
        isLoading: true,
      );

      final failed = active.copyWith(
        isPlaying: false,
        isLoading: false,
        error: 'Playback failed',
      );

      expect(failed.isActive, isTrue);
      expect(failed.surahId, 2);
      expect(failed.ayahNo, 5);
      expect(failed.surahLabel, 'Al-Baqarah');
      expect(failed.error, 'Playback failed');
    });

    test('clearPlaybackContext removes stale active session after failure', () {
      const active = AudioPlayerState(
        surahId: 2,
        ayahNo: 5,
        surahLabel: 'Al-Baqarah',
        isPlaying: true,
        isLoading: true,
      );

      final failed = active.copyWith(
        isPlaying: false,
        isLoading: false,
        error: 'No audio available',
        clearPlaybackContext: true,
      );

      expect(failed.isActive, isFalse);
      expect(failed.surahId, isNull);
      expect(failed.ayahNo, isNull);
      expect(failed.surahLabel, isNull);
      expect(failed.isPlaying, isFalse);
      expect(failed.isLoading, isFalse);
      expect(failed.error, 'No audio available');
    });
  });

  group('audioRestartShouldSeekToStart', () {
    test('does not seek after a media-session pause (ready)', () {
      expect(audioRestartShouldSeekToStart(ProcessingState.ready), isFalse);
    });

    test('does not seek while buffering or loading', () {
      expect(audioRestartShouldSeekToStart(ProcessingState.buffering), isFalse);
      expect(audioRestartShouldSeekToStart(ProcessingState.loading), isFalse);
      expect(audioRestartShouldSeekToStart(ProcessingState.idle), isFalse);
    });

    test('seeks to start only after the clip or playlist completed', () {
      expect(audioRestartShouldSeekToStart(ProcessingState.completed), isTrue);
    });
  });
}
