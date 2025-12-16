import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/verse_model.dart';
import 'package:quran_offline/core/providers/import_progress_provider.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataImporter {
  final AppDatabase _db;
  final void Function(ImportProgress)? onProgress;
  static const String _versionKey = 'quran_data_version';
  static const String currentVersion = 'v5-uthmani+translit+EN(SI)+ID(KEMENAG)+ZH(MaJian)+JA(Mita)-cleaned';

  DataImporter(this._db, {this.onProgress});

  Future<void> ensureDataImported() async {
    final prefs = await SharedPreferences.getInstance();
    final importedVersion = prefs.getString(_versionKey);

    if (importedVersion == currentVersion) {
      return;
    }

    await _importData();
    await prefs.setString(_versionKey, currentVersion);
  }

  Future<void> _importData() async {
    try {
      debugPrint('Starting data import...');
      onProgress?.call(ImportProgress(current: 0, total: 114, message: 'Starting import...'));
      
      debugPrint('Loading manifest...');
      await rootBundle.loadString('assets/quran/manifest_multi.json');
      debugPrint('Manifest loaded');

      const int batchSize = 5; // Smaller batches for better UI responsiveness
      final totalSurahs = 114;

      for (int batchStart = 1; batchStart <= totalSurahs; batchStart += batchSize) {
        final batchEnd = (batchStart + batchSize - 1).clamp(1, totalSurahs);
        debugPrint('Processing batch: Surah $batchStart to $batchEnd');
        
        await _db.batch((batch) async {
          for (int surahId = batchStart; surahId <= batchEnd; surahId++) {
            debugPrint('Loading Surah $surahId...');
            onProgress?.call(ImportProgress(
              current: surahId - 1,
              total: totalSurahs,
              message: 'Importing Surah $surahId...',
            ));

            final surahFile = 'assets/quran/s${surahId.toString().padLeft(3, '0')}.json';
            final surahData = await rootBundle.loadString(surahFile);
            debugPrint('Surah $surahId loaded, parsing...');
            
            final verses = jsonDecode(surahData) as List<dynamic>;
            debugPrint('Surah $surahId: ${verses.length} verses');

            for (final verseData in verses) {
              final verse = VerseModel.fromJson(verseData as Map<String, dynamic>);
              final metadata = verse.metadata;

              batch.insert(
                _db.verses,
                VersesCompanion.insert(
                  surahId: verse.surahId,
                  ayahNo: verse.ayahNo,
                  page: metadata?.page ?? 0,
                  juz: metadata?.juz ?? 0,
                  arabic: verse.arabic,
                  translit: Value(verse.translit),
                  trEn: Value(verse.translations?['en'] != null 
                      ? TranslationCleaner.clean(verse.translations!['en']) 
                      : null),
                  trId: Value(verse.translations?['id'] != null 
                      ? TranslationCleaner.clean(verse.translations!['id']) 
                      : null),
                  trZh: Value(verse.translations?['zh'] != null 
                      ? TranslationCleaner.clean(verse.translations!['zh']) 
                      : null),
                  trJa: Value(verse.translations?['ja'] != null 
                      ? TranslationCleaner.clean(verse.translations!['ja']) 
                      : null),
                ),
                mode: InsertMode.replace,
              );
            }
            debugPrint('Surah $surahId processed');
          }
        });
        debugPrint('Batch $batchStart-$batchEnd committed');

        // Allow UI to update between batches
        await Future.delayed(const Duration(milliseconds: 50));
      }

      debugPrint('Import complete!');
      onProgress?.call(ImportProgress(
        current: totalSurahs,
        total: totalSurahs,
        message: 'Import complete!',
      ));
    } catch (e, stackTrace) {
      debugPrint('Import error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

