import 'dart:async';

import 'package:quran_offline/core/mushaf/qpc_v2_font_loader.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_mushaf_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background Mushaf init + page preload for smooth first open and swiping.
///
/// Splash: SQLite + page-1 font + nearby pages (non-blocking after core).
/// While app is open: cache layout rows + prefetch neighbor fonts in background.
class MushafWarmup {
  MushafWarmup._();

  static const _bootstrapPages = [1, 2, 3, 4, 5];

  static Future<void>? _sessionTask;
  static Future<void>? _backgroundTask;
  static int? _sessionPriorityPage;
  static bool _coreReady = false;
  static final Set<int> _preloadedPages = {};
  static int? _lastSwipePrefetchTick;

  static bool get isCoreReady => _coreReady;

  static int? readLastMushafPageFromPrefs(SharedPreferences prefs) {
    if (prefs.getString('last_read_position_type') != 'page') return null;
    return prefs.getInt('last_read_position_id');
  }

  static Future<int?> readLastMushafPage() async {
    final prefs = await SharedPreferences.getInstance();
    return readLastMushafPageFromPrefs(prefs);
  }

  static Future<void> beginSession({int? priorityPage}) {
    if (priorityPage != null) {
      _sessionPriorityPage = priorityPage;
      if (_coreReady) {
        unawaited(_preloadAround(priorityPage));
      }
    }
    return _sessionTask ??= _runSession();
  }

  static void schedule({int? priorityPage}) {
    unawaited(beginSession(priorityPage: priorityPage));
  }

  static Future<void> ensureInitialized() async {
    await beginSession();
    while (!_coreReady) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  static Future<void> _runSession() async {
    if (!await QpcV2MushafLayout.isAvailable()) return;

    final repo = QpcV2MushafLayout.sharedRepository();
    await repo.ensureReady();
    await Future.wait([
      QpcV2FontLoader.ensurePageFontLoaded(1),
      repo.bismillahGlyphText(),
    ]);
    _coreReady = true;

    final layout = QpcV2MushafLayout(repo);
    final pagesToLoad = <int>{..._bootstrapPages};
    final priority = _sessionPriorityPage;
    if (priority != null && priority >= 1 && priority <= 604) {
      pagesToLoad.add(priority);
      for (var d = -3; d <= 3; d++) {
        final p = priority + d;
        if (p >= 1 && p <= 604) pagesToLoad.add(p);
      }
    }

    final ordered = pagesToLoad.toList()
      ..sort((a, b) {
        if (priority == null) return a.compareTo(b);
        final da = (a - priority).abs();
        final db = (b - priority).abs();
        if (da != db) return da.compareTo(db);
        return a.compareTo(b);
      });

    QpcV2FontLoader.prefetchPages(ordered);
    for (final page in ordered) {
      await _prewarmPage(layout, page);
    }

    _backgroundTask ??= _runBackgroundPreload();
  }

  /// Lightweight: layout rows for all pages; fonts only for pages not yet loaded.
  static Future<void> _runBackgroundPreload() async {
    if (!await QpcV2MushafLayout.isAvailable()) return;

    final repo = QpcV2MushafLayout.sharedRepository();
    final layout = QpcV2MushafLayout(repo);

    for (var page = 1; page <= 604; page++) {
      try {
        await repo.getPageLines(page);
      } catch (_) {
        // Best-effort.
      }
      if (page % 32 == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 12));
      }
    }

    for (var page = 1; page <= 604; page++) {
      if (_preloadedPages.contains(page)) continue;
      QpcV2FontLoader.prefetchPages([page]);
      unawaited(_prewarmPage(layout, page));
      if (page % 8 == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 24));
      }
    }
  }

  static Future<void> _preloadAround(int centerPage) async {
    if (!await QpcV2MushafLayout.isAvailable()) return;
    final layout = QpcV2MushafLayout(QpcV2MushafLayout.sharedRepository());
    final pages = <int>{centerPage};
    for (var d = -3; d <= 3; d++) {
      final p = centerPage + d;
      if (p >= 1 && p <= 604) pages.add(p);
    }
    QpcV2FontLoader.prefetchPages(pages);
    for (final page in pages) {
      unawaited(_prewarmPage(layout, page));
    }
  }

  static Future<void> _prewarmPage(QpcV2MushafLayout layout, int page) async {
    if (_preloadedPages.contains(page)) return;
    _preloadedPages.add(page);
    await layout.prewarm(page);
  }

  static void prefetchDuringSwipe(double pageIndex) {
    if (pageIndex.isNaN) return;
    final tick = (pageIndex * 20).round();
    if (_lastSwipePrefetchTick == tick) return;
    _lastSwipePrefetchTick = tick;

    final floor = pageIndex.floor().clamp(0, 603);
    final ceil = pageIndex.ceil().clamp(0, 603);
    final floorPage = floor + 1;
    final ceilPage = ceil + 1;
    final towardCeil = pageIndex - floor > 0.06;
    final towardFloor = ceil - pageIndex > 0.06;

    final fontPages = <int>{floorPage, ceilPage, 1};
    if (towardCeil && ceilPage <= 604) fontPages.add(ceilPage + 1);
    if (towardFloor && floorPage > 1) fontPages.add(floorPage - 1);
    QpcV2FontLoader.prefetchPages(fontPages);

    if (towardCeil && ceilPage <= 604) {
      unawaited(QpcV2MushafLayout.prewarmPage(ceilPage));
    }
    if (towardFloor && floorPage >= 1) {
      unawaited(QpcV2MushafLayout.prewarmPage(floorPage));
    }
  }
}
