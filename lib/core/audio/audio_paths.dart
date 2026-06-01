import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/models/reciter.dart';

/// Resolves remote URLs and local cache paths for per-ayah recitation audio.
///
/// File names use the everyayah.com convention `{SSS}{AAA}.mp3`, where the
/// surah and ayah numbers are each zero-padded to three digits.
/// Ayah `0` is the standalone Bismillah before surahs 2-8 and 10-114 (`002000.mp3`).
class AudioPaths {
  AudioPaths._();

  /// Cached application documents directory, resolved lazily once.
  static Directory? _docsDir;

  static String _pad3(int value) => value.toString().padLeft(3, '0');

  /// The bare file name for an ayah, e.g. `001001.mp3`.
  static String fileName(int surahId, int ayahNo) =>
      '${_pad3(surahId)}${_pad3(ayahNo)}.mp3';

  /// Remote CDN URL for an ayah of the given reciter.
  static String remoteUrl(Reciter reciter, int surahId, int ayahNo) =>
      '${reciter.baseUrl}/${fileName(surahId, ayahNo)}';

  /// Ensures and returns the root audio directory: `{docs}/audio`.
  static Future<Directory> _audioRoot() async {
    _docsDir ??= await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(_docsDir!.path, 'audio'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Ensures and returns the directory for a reciter: `{docs}/audio/{reciterId}`.
  static Future<Directory> reciterDir(String reciterId) async {
    final root = await _audioRoot();
    final dir = Directory(p.join(root.path, reciterId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Local file for a specific ayah. Does not guarantee the file exists.
  static Future<File> localFile(String reciterId, int surahId, int ayahNo) async {
    final dir = await reciterDir(reciterId);
    return File(p.join(dir.path, fileName(surahId, ayahNo)));
  }

  /// Whether the ayah audio is already downloaded for the reciter.
  static Future<bool> isDownloaded(String reciterId, int surahId, int ayahNo) async {
    final file = await localFile(reciterId, surahId, ayahNo);
    return file.exists();
  }

  /// Reciter folder names present under `{docs}/audio/`.
  static Future<List<String>> reciterIdsOnDisk() async {
    final root = await _audioRoot();
    final ids = <String>[];
    try {
      await for (final entity in root.list()) {
        if (entity is Directory) {
          ids.add(p.basename(entity.path));
        }
      }
    } catch (_) {}
    ids.sort();
    return ids;
  }
}
