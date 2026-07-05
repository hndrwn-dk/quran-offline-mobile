import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/home_widget_keys.dart';
import 'package:quran_offline/core/widgets/home_widget_payload.dart';
import 'package:quran_offline/core/widgets/home_widget_progress.dart';

/// Builds widget payload from app state and pushes it to the native home widget.
class HomeWidgetSync {
  HomeWidgetSync._();

  static Future<void> updateFromRef(WidgetRef ref) async {
    try {
      final lang = ref.read(settingsProvider).appLanguage;
      final payload = await _buildPayload(ref, lang);
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.payload,
        payload.encode(),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: HomeWidgetKeys.androidQualifiedName,
        iOSName: HomeWidgetKeys.iosName,
      );
    } catch (e, st) {
      debugPrint('HomeWidgetSync.updateFromRef failed: $e\n$st');
    }
  }

  static Future<BerandaWidgetPayload> _buildPayload(
    WidgetRef ref,
    String lang,
  ) async {
    final reflection = await _safeReflection(ref, lang);
    final lastRead = ref.read(lastReadProvider);
    final continueLabel = AppLocalizations.getHomeContinuePill(lang);

    if (lastRead == null) {
      return BerandaWidgetPayload(
        tagline: AppLocalizations.getHomeTagline(lang),
        reflectionLabel: reflection.label,
        reflectionTitle: reflection.title,
        reflectionRef: reflection.ref,
        reflectionBadge: reflection.badge,
        reflectionContext: reflection.context,
        continueLabel: continueLabel,
        readDeepLink: 'quranoffline://home',
        reflectionDeepLink: 'quranoffline://reflection',
        hasContinue: false,
      );
    }

    final db = ref.read(databaseProvider);
    final surahs = await ref.read(surahNamesProvider.future);
    final coords = await resolveSurahAyahFromLastRead(db, lastRead);
    if (coords == null) {
      return BerandaWidgetPayload(
        tagline: AppLocalizations.getHomeTagline(lang),
        reflectionLabel: reflection.label,
        reflectionTitle: reflection.title,
        reflectionRef: reflection.ref,
        reflectionBadge: reflection.badge,
        reflectionContext: reflection.context,
        continueLabel: continueLabel,
        readDeepLink: 'quranoffline://home',
        reflectionDeepLink: 'quranoffline://reflection',
        hasContinue: false,
      );
    }

    final surah = surahs.firstWhere(
      (s) => s.id == coords.surahId,
      orElse: () => surahs.first,
    );
    final surahName = _surahLabel(surah, lang);

    final progress = await computeWidgetReadingProgress(
      db: db,
      lastRead: lastRead,
      surahDisplayName: surahName,
    );

    final readLink =
        'quranoffline://read?surah=${coords.surahId}&ayah=${coords.ayahNo}';

    if (progress == null) {
      return BerandaWidgetPayload(
        tagline: AppLocalizations.getHomeTagline(lang),
        reflectionLabel: reflection.label,
        reflectionTitle: reflection.title,
        reflectionRef: reflection.ref,
        reflectionBadge: reflection.badge,
        reflectionContext: reflection.context,
        continueLabel: continueLabel,
        surahName: surahName,
        ayahNo: coords.ayahNo,
        readDeepLink: readLink,
        reflectionDeepLink: 'quranoffline://reflection',
        hasContinue: true,
      );
    }

    return BerandaWidgetPayload(
      tagline: AppLocalizations.getHomeTagline(lang),
      reflectionLabel: reflection.label,
      reflectionTitle: reflection.title,
      reflectionRef: reflection.ref,
      reflectionBadge: reflection.badge,
      reflectionContext: reflection.context,
      continueLabel: continueLabel,
      surahName: progress.surahName,
      ayahNo: progress.ayahNo,
      surahPercent: progress.surahPercent,
      juzLabel: '${AppLocalizations.getMenuText('juz', lang)} ${progress.juzNo}',
      juzPercent: progress.juzPercent,
      surahCurrent: progress.surahCurrent,
      surahTotal: progress.surahTotal,
      juzCurrent: progress.juzCurrent,
      juzTotal: progress.juzTotal,
      readDeepLink: readLink,
      reflectionDeepLink: 'quranoffline://reflection',
      hasContinue: true,
    );
  }

  static String _surahLabel(SurahInfo surah, String lang) {
    if (lang == 'id') {
      return surah.getMeaning('id');
    }
    return surah.englishName;
  }

  static Future<
      ({
        String label,
        String title,
        String ref,
        String badge,
        String? context,
      })> _safeReflection(WidgetRef ref, String lang) async {
    try {
      final pick = await ref.read(reflectionPickProvider.future);
      return _reflectionFields(pick, lang);
    } catch (e) {
      debugPrint('HomeWidgetSync: reflection unavailable: $e');
      return (
        label: AppLocalizations.getReflectionCardTitle('weekly', lang),
        title: '',
        ref: '',
        badge: '',
        context: null,
      );
    }
  }

  static ({
    String label,
    String title,
    String ref,
    String badge,
    String? context,
  }) _reflectionFields(ReflectionPick pick, String lang) {
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
      badge: AppLocalizations.getReflectionBadge(entry.badgeKey, lang),
      context: entry.summary.forLanguage(lang),
    );
  }
}
