import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/reflection_history_store.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/home_tagline.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/core/widgets/home_widget_ayah_renderer.dart';
import 'package:quran_offline/core/widgets/home_widget_keys.dart';
import 'package:quran_offline/core/widgets/home_widget_mapping.dart';
import 'package:quran_offline/core/widgets/home_widget_payload.dart';
import 'package:quran_offline/core/widgets/home_widget_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads a provider; satisfied by both `WidgetRef.read` and
/// `ProviderContainer.read`.
typedef WidgetProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Daily refresh from the native WorkManager job (see QuranWidgetRefreshWorker).
const kHomeWidgetRefreshUri = 'quranoffline://widget/refresh';

/// home_widget background entry point. Runs in a headless engine, so it builds
/// its own [ProviderContainer] and reads language/last-read from prefs.
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri?.toString() != kHomeWidgetRefreshUri) return;
  await HomeWidgetSync.updateInBackground();
}

/// Builds widget payload from app state and pushes it to the native home widget.
class HomeWidgetSync {
  HomeWidgetSync._();

  static Future<void> _queue = Future.value();

  static Future<void> updateFromRef(WidgetRef ref) {
    final lang = ref.read(settingsProvider).appLanguage;
    final lastRead = ref.read(lastReadProvider);
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final dpr = views.isEmpty ? null : views.first.devicePixelRatio;
    return _enqueue(() => _update(ref.read, lang, lastRead, dpr));
  }

  static Future<void> updateInBackground() async {
    final container = ProviderContainer();
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('language') ?? 'en';
      final lastRead = LastReadNotifier.readFromPrefs(prefs);
      await _enqueue(() => _update(container.read, lang, lastRead, null));
    } finally {
      container.dispose();
    }
  }

  /// Updates run one at a time: listeners fire in bursts and each update
  /// writes the same files.
  static Future<void> _enqueue(Future<void> Function() task) {
    final next = _queue.then((_) => task());
    _queue = next.catchError((Object _) {});
    return next;
  }

  static Future<void> _update(
    WidgetProviderReader read,
    String lang,
    LastReadPosition? lastRead,
    double? devicePixelRatio,
  ) async {
    try {
      final dpr = await _devicePixelRatio(devicePixelRatio);
      final day = read(islamicDayProvider);
      final salt = await ReflectionHistoryStore().readOrCreateInstallSalt();
      final tagline = pickHomeTagline(
        language: lang,
        installSalt: salt,
        hijriYmd: day.hijri.ymdKey,
        period: day.period,
      );
      final payload = await _buildPayload(read, lang, lastRead, tagline, dpr);
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.payload,
        payload.encode(),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: HomeWidgetKeys.androidQualifiedName,
        iOSName: HomeWidgetKeys.iosName,
      );
    } catch (e, st) {
      debugPrint('HomeWidgetSync update failed: $e\n$st');
    }
  }

  /// The foreground value is remembered for the background refresh, which
  /// has no view to ask.
  static Future<double> _devicePixelRatio(double? current) async {
    const key = 'widget_device_pixel_ratio';
    if (current != null && current > 0) {
      await HomeWidget.saveWidgetData<String>(key, current.toString());
      return current;
    }
    final saved = await HomeWidget.getWidgetData<String>(key);
    return double.tryParse(saved ?? '') ?? 3.0;
  }

  static Future<BerandaWidgetPayload> _buildPayload(
    WidgetProviderReader read,
    String lang,
    LastReadPosition? lastRead,
    String tagline,
    double dpr,
  ) async {
    final db = read(databaseProvider);
    final surahs = await read(surahNamesProvider.future);
    final pick = await _safeReflectionPick(read);
    final reflection = _reflectionFields(pick, lang);
    final ayah = pick == null
        ? null
        : await _reflectionAyah(db, surahs, pick.entry, lang, dpr);
    final cont = lastRead == null
        ? null
        : await _continueFields(db, surahs, lastRead, lang);
    final continueLabel = AppLocalizations.getHomeContinuePill(lang);

    return BerandaWidgetPayload(
      tagline: tagline,
      reflectionLabel: reflection.label,
      reflectionTitle: reflection.title,
      reflectionRef: reflection.ref,
      reflectionBadge: reflection.badge,
      reflectionContext: reflection.context,
      continueLabel: continueLabel,
      surahName: cont?.progress?.surahName ?? cont?.surahName,
      ayahNo: cont?.ayahNo,
      surahPercent: cont?.progress?.surahPercent,
      juzLabel: cont?.juzLabel,
      juzPercent: cont?.progress?.juzPercent,
      surahCurrent: cont?.progress?.surahCurrent,
      surahTotal: cont?.progress?.surahTotal,
      juzCurrent: cont?.progress?.juzCurrent,
      juzTotal: cont?.progress?.juzTotal,
      readDeepLink: cont?.deepLink ?? 'quranoffline://home',
      reflectionDeepLink: 'quranoffline://reflection',
      hasContinue: cont != null,
      continueTitle: cont != null
          ? continueLabel
          : AppLocalizations.getWidgetStartReading(lang),
      continueMeta: cont?.meta,
      continueButton: cont == null
          ? AppLocalizations.getWidgetStartReading(lang)
          : AppLocalizations.getWidgetContinueButton(cont.page, lang),
      continuePercent: cont?.percent,
      continueDescription: cont == null
          ? null
          : AppLocalizations.formatWidgetProgressDescription(
              cont.percent,
              cont.scope,
              lang,
            ),
      continueHint: AppLocalizations.getWidgetStartReadingHint(lang),
      ayahRef: ayah?.ref,
      ayahTranslation: ayah?.translation,
      ayahPosition: ayah?.position,
      ayahDeepLink: ayah?.deepLink,
      reflectionButton: AppLocalizations.getWidgetReadReflection(lang),
      ayahImageMedium: ayah?.imageMedium,
      ayahImageLarge: ayah?.imageLarge,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<
      ({
        String ref,
        String? translation,
        String? position,
        String deepLink,
        String? imageMedium,
        String? imageLarge,
      })?> _reflectionAyah(
    AppDatabase db,
    List<SurahInfo> surahs,
    ReflectionLensEntry entry,
    String lang,
    double dpr,
  ) async {
    final verses = <String, Verse>{};
    for (final a in flattenReflectionAyahs(entry.ayahRefs)) {
      final verse = await db.getVerse(a.surah, a.ayah);
      if (verse != null) verses['${a.surah}:${a.ayah}'] = verse;
    }
    final picked = pickWidgetReflectionAyah(
      entry.ayahRefs,
      (s, a) => verses['$s:$a']?.arabic.length,
    );
    if (picked == null) return null;
    final verse = verses['${picked.surah}:${picked.ayah}'];

    final images = <WidgetAyahBucket, String?>{};
    if (verse != null) {
      final renderer = WidgetAyahRenderer();
      for (final bucket in WidgetAyahBucket.values) {
        try {
          images[bucket] = await renderer
              .renderCached(
                surah: picked.surah,
                ayah: picked.ayah,
                page: verse.page,
                bucket: bucket,
                devicePixelRatio: dpr,
              )
              .timeout(const Duration(seconds: 20));
        } catch (e) {
          debugPrint('HomeWidgetSync: ayah render failed (${bucket.name}): $e');
        }
      }
    }

    return (
      ref: AppLocalizations.formatWidgetAyahRef(
        _surahName(surahs, picked.surah),
        picked.surah,
        picked.ayah,
        lang,
      ),
      translation: verse == null ? null : _translation(verse, lang),
      // "1 dari 1 ayat" says nothing, so a single-ayah reflection has none.
      position: picked.total > 1
          ? AppLocalizations.formatWidgetAyahPosition(
              picked.index,
              picked.total,
              lang,
            )
          : null,
      deepLink: widgetAyahDeepLink(picked.surah, picked.ayah),
      imageMedium: images[WidgetAyahBucket.medium],
      imageLarge: images[WidgetAyahBucket.large],
    );
  }

  static Future<
      ({
        String surahName,
        int ayahNo,
        int page,
        int percent,
        String scope,
        String? juzLabel,
        String meta,
        String deepLink,
        WidgetReadingProgress? progress,
      })?> _continueFields(
    AppDatabase db,
    List<SurahInfo> surahs,
    LastReadPosition lastRead,
    String lang,
  ) async {
    final coords = await resolveSurahAyahFromLastRead(db, lastRead);
    if (coords == null) return null;
    final verse = await db.getVerse(coords.surahId, coords.ayahNo);
    final page = lastRead.type == 'page' ? lastRead.id : verse?.page;
    if (page == null) return null;

    final surahName = _surahName(surahs, coords.surahId);
    final progress = await computeWidgetReadingProgress(
      db: db,
      lastRead: lastRead,
      surahDisplayName: surahName,
    );
    // Same ring as the app's continue card: surah, juz, or Mushaf page
    // progress depending on how the last read was saved.
    final ring = computeLastReadProgress(
      lastRead: lastRead,
      surahAyahCount: lastRead.type == 'surah' || lastRead.type == 'surah_in_juz'
          ? await db.getAyahCountForSurah(coords.surahId)
          : null,
      juzVerses:
          lastRead.type == 'juz' ? await db.getVersesByJuz(lastRead.id) : null,
    );
    final juzNo = progress?.juzNo ?? verse?.juz;
    final juzLabel =
        juzNo == null ? null : '${AppLocalizations.getMenuText('juz', lang)} $juzNo';

    return (
      surahName: surahName,
      ayahNo: coords.ayahNo,
      page: page,
      percent: ring?.percent ?? widgetQuranPagePercent(page),
      scope: ring?.scope ?? 'page',
      juzLabel: juzLabel,
      meta: widgetContinueMeta(
        pageLabel: AppLocalizations.getWidgetPageShort(page, lang),
        juzLabel: juzLabel,
      ),
      deepLink: widgetContinueDeepLink(coords.surahId, coords.ayahNo),
      progress: progress,
    );
  }

  static String _surahName(List<SurahInfo> surahs, int surahId) {
    for (final s in surahs) {
      if (s.id == surahId) return s.englishName;
    }
    return '$surahId';
  }

  static String? _translation(Verse verse, String lang) {
    final raw = switch (lang) {
      'en' => verse.trEn,
      'zh' => verse.trZh,
      'ja' => verse.trJa,
      _ => verse.trId,
    };
    if (raw == null) return null;
    final text = TranslationCleaner.clean(raw).trim();
    return text.isEmpty ? null : text;
  }

  static Future<ReflectionPick?> _safeReflectionPick(
    WidgetProviderReader read,
  ) async {
    try {
      return await read(reflectionPickProvider.future);
    } catch (e) {
      debugPrint('HomeWidgetSync: reflection unavailable: $e');
      return null;
    }
  }

  static ({
    String label,
    String title,
    String ref,
    String badge,
    String? context,
  }) _reflectionFields(ReflectionPick? pick, String lang) {
    if (pick == null) {
      return (
        label: AppLocalizations.getReflectionCardTitle('weekly', lang),
        title: '',
        ref: '',
        badge: '',
        context: null,
      );
    }
    final entry = pick.entry;
    final sourceKey = switch (pick.source) {
      ReflectionPickSource.weekly => 'weekly',
      ReflectionPickSource.calendar => 'calendar',
      ReflectionPickSource.timeOfDay => 'calendar',
    };
    final refLabel = entry.ayahRefs.length == 1
        ? AppLocalizations.formatDuaAyahRef(
            entry.primaryRef.surah,
            entry.primaryRef.from,
            entry.primaryRef.to,
            lang,
          )
        : AppLocalizations.formatThemeAyahLabel(entry.ayahCount, lang);

    return (
      label: AppLocalizations.getReflectionCardTitle(sourceKey, lang),
      title: entry.title.forLanguage(lang),
      ref: refLabel,
      badge: entry.showsOccasionBadge
          ? AppLocalizations.getReflectionBadge(entry.badgeKey, lang)
          : '',
      context: entry.summary.forLanguage(lang),
    );
  }
}
