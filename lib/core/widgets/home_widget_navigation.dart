import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';

/// Handles taps from the Android/iOS home screen widget.
class HomeWidgetNavigation {
  HomeWidgetNavigation._();

  static StreamSubscription<Uri?>? _subscription;

  static void register(BuildContext context, WidgetRef ref) {
    _subscription?.cancel();
    _subscription = HomeWidget.widgetClicked.listen((uri) {
      if (uri == null) return;
      if (!context.mounted) return;
      unawaited(_handleUri(context, ref, uri));
    });

  unawaited(_handleInitialLaunch(context, ref));
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<void> _handleInitialLaunch(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null && context.mounted) {
        await _handleUri(context, ref, uri);
      }
    } catch (_) {
      // Widget launch probe not supported on this platform/build.
    }
  }

  static Future<void> _handleUri(
    BuildContext context,
    WidgetRef ref,
    Uri uri,
  ) async {
    if (uri.scheme != 'quranoffline') return;

    switch (uri.host) {
      case 'home':
        ref.read(currentTabProvider.notifier).state = AppTab.home;
        return;
      case 'read':
        final surah = int.tryParse(uri.queryParameters['surah'] ?? '');
        final ayah = int.tryParse(uri.queryParameters['ayah'] ?? '');
        if (surah != null) {
          ref.read(readerSourceProvider.notifier).state =
              SurahSource(surah, targetAyahNo: ayah);
          if (ayah != null) {
            ref.read(targetAyahProvider.notifier).state = ayah;
          }
          await openReaderScreen(context, ref);
          return;
        }
        final lastRead = ref.read(lastReadProvider);
        if (lastRead != null) {
          ref.read(readerSourceProvider.notifier).state =
              lastRead.toReaderSource();
          if (lastRead.ayahNo != null) {
            ref.read(targetAyahProvider.notifier).state = lastRead.ayahNo;
          }
          ref.read(targetSurahIdProvider.notifier).state =
              lastRead.type == 'juz' ? lastRead.surahId : null;
          await openReaderScreen(context, ref);
          return;
        }
        ref.read(currentTabProvider.notifier).state = AppTab.read;
        return;
      case 'reflection':
        ref.read(currentTabProvider.notifier).state = AppTab.home;
        try {
          final pick = await ref.read(reflectionPickProvider.future);
          final lang = ref.read(settingsProvider).appLanguage;
          if (!context.mounted) return;
          final entry = pick.entry;
          await showExploreDetailSheet(
            context: context,
            ref: ref,
            lang: lang,
            title: entry.title,
            summary: entry.summary,
            sectionNote: entry.reflection,
            sectionHeading:
                AppLocalizations.getReflectionReflectionHeading(lang),
            ayahRefs: entry.ayahRefs,
            onOpenReader: (ayahRef) {
              openReaderFromAyahRef(ref, ayahRef);
              openReaderScreen(context, ref);
            },
          );
        } catch (_) {
          // Reflection data not ready; user lands on Beranda.
        }
        return;
      default:
        ref.read(currentTabProvider.notifier).state = AppTab.home;
    }
  }
}
