import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Local mic capture + playback for Friday setoran self-practice (fase 2).
class SetoranRecitationRecorder {
  SetoranRecitationRecorder();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _recording = false;

  bool get isRecording => _recording;
  bool get isPlaying => _player.playing;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  static Future<String> recordingPath({
    required String fridayKey,
    required String itemKey,
    required int surahId,
    required int ayahNo,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = p.join(docs.path, 'setoran', fridayKey, itemKey);
    await Directory(dir).create(recursive: true);
    return p.join(dir, '${surahId}_$ayahNo.m4a');
  }

  static const int minRecordingBytes = 1200;

  static Future<bool> hasRecording({
    required String fridayKey,
    required String itemKey,
    required int surahId,
    required int ayahNo,
  }) async {
    final path = await recordingPath(
      fridayKey: fridayKey,
      itemKey: itemKey,
      surahId: surahId,
      ayahNo: ayahNo,
    );
    if (await File(path).exists()) return true;
    final legacyWav = path.replaceAll('.m4a', '.wav');
    return await File(legacyWav).exists();
  }

  static Future<String> resolvePlaybackPath({
    required String fridayKey,
    required String itemKey,
    required int surahId,
    required int ayahNo,
  }) async {
    final m4a = await recordingPath(
      fridayKey: fridayKey,
      itemKey: itemKey,
      surahId: surahId,
      ayahNo: ayahNo,
    );
    if (await File(m4a).exists()) return m4a;
    final legacyWav = m4a.replaceAll('.m4a', '.wav');
    if (await File(legacyWav).exists()) return legacyWav;
    return m4a;
  }

  Future<bool> ensureMicPermission() async {
    if (await _recorder.hasPermission()) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _configureRecordSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ),
    );
  }

  Future<void> _configurePlaybackSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ),
    );
    await session.setActive(true);
  }

  Future<void> startRecording(String filePath) async {
    if (_recording) return;
    if (!await ensureMicPermission()) {
      throw SetoranRecorderException.permissionDenied();
    }
    await _configureRecordSession();
    await _player.stop();
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: filePath,
    );
    _recording = true;
  }

  Future<String?> stopRecording() async {
    if (!_recording) return null;
    final path = await _recorder.stop();
    _recording = false;
    if (path == null) return null;
    final bytes = await File(path).length();
    if (bytes < minRecordingBytes) {
      await File(path).delete();
      throw SetoranRecorderException.fileEmpty();
    }
    return path;
  }

  Future<void> playRecording(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw SetoranRecorderException.fileMissing();
    }
    if (await file.length() < minRecordingBytes) {
      throw SetoranRecorderException.fileEmpty();
    }
    await _configurePlaybackSession();
    await _player.stop();
    await _player.setVolume(1.0);
    try {
      await _player.setAudioSource(
        AudioSource.file(
          filePath,
          tag: MediaItem(
            id: 'setoran_recording_$filePath',
            album: 'Setoran',
            title: 'Rekaman setoran',
          ),
        ),
      );
      await _player.play();
    } on PlayerException {
      throw SetoranRecorderException.playbackFailed();
    }
  }

  Future<void> stopPlayback() => _player.stop();

  Future<void> dispose() async {
    if (_recording) {
      await _recorder.stop();
      _recording = false;
    }
    await _player.dispose();
    await _recorder.dispose();
  }
}

class SetoranRecorderException implements Exception {
  SetoranRecorderException(this.code);

  final SetoranRecorderExceptionCode code;

  factory SetoranRecorderException.permissionDenied() =>
      SetoranRecorderException(SetoranRecorderExceptionCode.permissionDenied);

  factory SetoranRecorderException.fileMissing() =>
      SetoranRecorderException(SetoranRecorderExceptionCode.fileMissing);

  factory SetoranRecorderException.fileEmpty() =>
      SetoranRecorderException(SetoranRecorderExceptionCode.fileEmpty);

  factory SetoranRecorderException.playbackFailed() =>
      SetoranRecorderException(SetoranRecorderExceptionCode.playbackFailed);
}

enum SetoranRecorderExceptionCode {
  permissionDenied,
  fileMissing,
  fileEmpty,
  playbackFailed,
}
