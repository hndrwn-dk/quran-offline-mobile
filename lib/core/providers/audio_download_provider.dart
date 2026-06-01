import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/core/audio/audio_paths.dart';
import 'package:quran_offline/core/models/reciter.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';

const _kDownloadedSurahsKey = 'audioDownloadedSurahs';

/// Per-ayah network timeout; a stalled connection must not hang a surah or the
/// "Save all 114" bulk loop indefinitely.
const _kAyahDownloadTimeout = Duration(seconds: 20);

String downloadKey(String reciterId, int surahId) => '$reciterId:$surahId';

/// On-device audio usage for one reciter folder.
class ReciterStorageSummary {
  final String reciterId;
  final String displayName;
  final int bytes;
  final int savedSurahCount;

  const ReciterStorageSummary({
    required this.reciterId,
    required this.displayName,
    required this.bytes,
    required this.savedSurahCount,
  });

  bool get hasFiles => bytes > 0;
}

/// Progress of an in-flight per-surah download.
class DownloadProgress {
  final int done;
  final int total;
  final bool failed;

  const DownloadProgress({
    required this.done,
    required this.total,
    this.failed = false,
  });

  double get fraction => total == 0 ? 0 : done / total;

  DownloadProgress copyWith({int? done, int? total, bool? failed}) {
    return DownloadProgress(
      done: done ?? this.done,
      total: total ?? this.total,
      failed: failed ?? this.failed,
    );
  }
}

/// Progress when downloading all 114 surahs for one reciter.
class BulkDownloadProgress {
  final int surahsDone;
  final int surahsTotal;
  final int? currentSurahId;

  const BulkDownloadProgress({
    required this.surahsDone,
    required this.surahsTotal,
    this.currentSurahId,
  });

  double get fraction =>
      surahsTotal == 0 ? 0 : surahsDone / surahsTotal;
}

class AudioDownloadsState {
  /// Keys (`reciterId:surahId`) of fully downloaded surahs.
  final Set<String> completed;

  /// Active downloads keyed by `reciterId:surahId`.
  final Map<String, DownloadProgress> active;

  /// Set while [AudioDownloadNotifier.downloadAllSurahs] is running.
  final BulkDownloadProgress? bulk;

  const AudioDownloadsState({
    this.completed = const {},
    this.active = const {},
    this.bulk,
  });

  AudioDownloadsState copyWith({
    Set<String>? completed,
    Map<String, DownloadProgress>? active,
    BulkDownloadProgress? bulk,
    bool clearBulk = false,
  }) {
    return AudioDownloadsState(
      completed: completed ?? this.completed,
      active: active ?? this.active,
      bulk: clearBulk ? null : (bulk ?? this.bulk),
    );
  }

  bool isComplete(String reciterId, int surahId) =>
      completed.contains(downloadKey(reciterId, surahId));

  DownloadProgress? progressFor(String reciterId, int surahId) =>
      active[downloadKey(reciterId, surahId)];

  bool isDownloading(String reciterId, int surahId) =>
      active.containsKey(downloadKey(reciterId, surahId));
}

/// Downloads and manages locally cached per-ayah recitation files.
class AudioDownloadNotifier extends StateNotifier<AudioDownloadsState> {
  AudioDownloadNotifier(this._ref) : super(const AudioDownloadsState()) {
    _load();
  }

  final Ref _ref;
  final Set<String> _cancelRequested = {};
  bool _cancelBulkDownload = false;

  static const int _surahCount = 114;

  int completedCountForReciter(String reciterId) {
    final prefix = '$reciterId:';
    return state.completed.where((k) => k.startsWith(prefix)).length;
  }

  bool hasAllSurahsForReciter(String reciterId) =>
      completedCountForReciter(reciterId) >= _surahCount;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kDownloadedSurahsKey) ?? const [];
    state = state.copyWith(completed: list.toSet());
  }

  Future<void> _persistCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kDownloadedSurahsKey, state.completed.toList());
  }

  void _setActive(String key, DownloadProgress progress) {
    final next = Map<String, DownloadProgress>.from(state.active);
    next[key] = progress;
    state = state.copyWith(active: next);
  }

  void _removeActive(String key) {
    final next = Map<String, DownloadProgress>.from(state.active)..remove(key);
    state = state.copyWith(active: next);
  }

  /// Downloads every ayah of [surahId] for [reciter] that is not already cached.
  Future<void> downloadSurah(Reciter reciter, int surahId) async {
    final key = downloadKey(reciter.id, surahId);
    if (state.isDownloading(reciter.id, surahId)) return;

    _cancelRequested.remove(key);
    final db = _ref.read(databaseProvider);
    final ayahCount = await db.getAyahCountForSurah(surahId);
    if (ayahCount <= 0) return;

    final withBismillah = Bismillah.hasBismillahAudio(surahId);
    final total = ayahCount + (withBismillah ? 1 : 0);

    _setActive(key, DownloadProgress(done: 0, total: total));
    final client = http.Client();
    try {
      var done = 0;
      if (withBismillah) {
        if (!await _downloadAyahIfMissing(client, reciter, surahId, Bismillah.audioAyahNo)) {
          _setActive(key, DownloadProgress(done: done, total: total, failed: true));
          return;
        }
        done++;
        _setActive(key, DownloadProgress(done: done, total: total));
      }
      for (var ayah = 1; ayah <= ayahCount; ayah++) {
        if (_cancelRequested.contains(key)) {
          _removeActive(key);
          _cancelRequested.remove(key);
          return;
        }

        if (!await _downloadAyahIfMissing(client, reciter, surahId, ayah)) {
          _setActive(key, DownloadProgress(done: done, total: total, failed: true));
          return;
        }
        done++;
        _setActive(key, DownloadProgress(done: done, total: total));
      }

      final completed = Set<String>.from(state.completed)..add(key);
      state = state.copyWith(completed: completed);
      await _persistCompleted();
    } catch (_) {
      final current = state.active[key];
      _setActive(
        key,
        DownloadProgress(
          done: current?.done ?? 0,
          total: total,
          failed: true,
        ),
      );
    } finally {
      client.close();
      // Clear the active entry shortly after success so the UI can settle.
      if (state.active[key]?.failed != true) {
        _removeActive(key);
      }
    }
  }

  Future<bool> _downloadAyahIfMissing(
    http.Client client,
    Reciter reciter,
    int surahId,
    int ayahNo,
  ) async {
    final file = await AudioPaths.localFile(reciter.id, surahId, ayahNo);
    if (await file.exists()) return true;
    final url = AudioPaths.remoteUrl(reciter, surahId, ayahNo);
    final http.Response resp;
    try {
      resp = await client.get(Uri.parse(url)).timeout(_kAyahDownloadTimeout);
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) return false;
    await file.writeAsBytes(resp.bodyBytes);
    return true;
  }

  /// Downloads all 114 surahs for [reciter], skipping those already complete.
  Future<void> downloadAllSurahs(Reciter reciter) async {
    if (state.bulk != null) return;
    _cancelBulkDownload = false;

    var surahsDone = 0;
    state = state.copyWith(
      bulk: BulkDownloadProgress(
        surahsDone: 0,
        surahsTotal: _surahCount,
        currentSurahId: 1,
      ),
    );

    try {
      for (var surahId = 1; surahId <= _surahCount; surahId++) {
        if (_cancelBulkDownload) break;

        if (state.isComplete(reciter.id, surahId)) {
          surahsDone++;
          state = state.copyWith(
            bulk: BulkDownloadProgress(
              surahsDone: surahsDone,
              surahsTotal: _surahCount,
              currentSurahId: surahId,
            ),
          );
          continue;
        }

        state = state.copyWith(
          bulk: BulkDownloadProgress(
            surahsDone: surahsDone,
            surahsTotal: _surahCount,
            currentSurahId: surahId,
          ),
        );

        await downloadSurah(reciter, surahId);

        if (state.isComplete(reciter.id, surahId)) {
          surahsDone++;
        }

        state = state.copyWith(
          bulk: BulkDownloadProgress(
            surahsDone: surahsDone,
            surahsTotal: _surahCount,
            currentSurahId: surahId,
          ),
        );
      }
    } finally {
      _cancelBulkDownload = false;
      state = state.copyWith(clearBulk: true);
    }
  }

  void cancelBulkDownload() {
    _cancelBulkDownload = true;
    final reciter = _ref.read(reciterProvider);
    for (var surahId = 1; surahId <= _surahCount; surahId++) {
      if (state.isDownloading(reciter.id, surahId)) {
        cancelDownload(reciter.id, surahId);
      }
    }
    state = state.copyWith(clearBulk: true);
  }

  /// Requests cancellation of an in-flight surah download.
  void cancelDownload(String reciterId, int surahId) {
    _cancelRequested.add(downloadKey(reciterId, surahId));
  }

  /// Deletes all cached files for a surah of the given reciter.
  Future<void> deleteSurah(String reciterId, int surahId) async {
    final db = _ref.read(databaseProvider);
    final ayahCount = await db.getAyahCountForSurah(surahId);
    if (Bismillah.hasBismillahAudio(surahId)) {
      final bism = await AudioPaths.localFile(reciterId, surahId, Bismillah.audioAyahNo);
      if (await bism.exists()) {
        try {
          await bism.delete();
        } catch (_) {}
      }
    }
    for (var ayah = 1; ayah <= ayahCount; ayah++) {
      final file = await AudioPaths.localFile(reciterId, surahId, ayah);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    final completed = Set<String>.from(state.completed)
      ..remove(downloadKey(reciterId, surahId));
    state = state.copyWith(completed: completed);
    await _persistCompleted();
  }

  /// Total bytes currently used by cached audio for a reciter.
  Future<int> storageBytesForReciter(String reciterId) async {
    final dir = await AudioPaths.reciterDir(reciterId);
    var total = 0;
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }

  String _displayNameForReciterId(String reciterId) {
    for (final r in ReciterCatalog.reciters) {
      if (r.id == reciterId) return r.name;
    }
    return reciterId;
  }

  /// Per-reciter file sizes on disk (includes folders with files but no completed marks).
  Future<List<ReciterStorageSummary>> storageSummariesForAllReciters() async {
    final onDisk = await AudioPaths.reciterIdsOnDisk();
    final ids = <String>{
      ...ReciterCatalog.reciters.map((r) => r.id),
      ...onDisk,
    };
    final summaries = <ReciterStorageSummary>[];
    for (final id in ids) {
      final bytes = await storageBytesForReciter(id);
      final saved = completedCountForReciter(id);
      if (bytes > 0 || saved > 0) {
        summaries.add(
          ReciterStorageSummary(
            reciterId: id,
            displayName: _displayNameForReciterId(id),
            bytes: bytes,
            savedSurahCount: saved,
          ),
        );
      }
    }
    summaries.sort((a, b) => b.bytes.compareTo(a.bytes));
    return summaries;
  }

  Future<int> storageBytesTotal() async {
    final summaries = await storageSummariesForAllReciters();
    return summaries.fold<int>(0, (sum, s) => sum + s.bytes);
  }

  /// Removes every cached file and download record for [reciterId].
  Future<void> deleteAllForReciter(String reciterId) async {
    for (var surahId = 1; surahId <= _surahCount; surahId++) {
      if (state.isDownloading(reciterId, surahId)) {
        cancelDownload(reciterId, surahId);
      }
    }

    final dir = await AudioPaths.reciterDir(reciterId);
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    final completed = state.completed
        .where((k) => !k.startsWith('$reciterId:'))
        .toSet();
    state = state.copyWith(completed: completed);
    await _persistCompleted();
  }

  /// Removes all recitation audio for every reciter on the device.
  Future<void> deleteAllReciters() async {
    final ids = await AudioPaths.reciterIdsOnDisk();
    for (final id in ids) {
      await deleteAllForReciter(id);
    }
    state = state.copyWith(completed: const {});
    await _persistCompleted();
  }
}

final audioDownloadProvider =
    StateNotifierProvider<AudioDownloadNotifier, AudioDownloadsState>((ref) {
  return AudioDownloadNotifier(ref);
});
