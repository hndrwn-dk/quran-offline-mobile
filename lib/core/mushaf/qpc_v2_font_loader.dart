import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_assets.dart';

/// Loads per-page QPC V2 TTF assets at runtime.
///
/// Registering a font makes the engine report "system fonts changed", and the
/// framework then re-lays out every [RenderParagraph] in the app, hidden
/// routes and tabs included. On a large screen that is hundreds of paragraphs
/// (issue #25). So:
/// * a page font is registered once and kept: the engine never unloads a
///   font, so forgetting it would only register it (and re-lay out) again;
/// * neighbour prefetches wait for an idle moment (no animation running) and
///   load a few fonts together, so their relayout lands outside page turns.
class QpcV2FontLoader {
  QpcV2FontLoader._();

  /// Fonts loaded per idle task; their relayouts coalesce into one frame.
  static const _prefetchBatch = 4;

  static final Map<int, String> _loadedFamilies = {};
  static final Map<int, Future<String>> _loading = {};
  static final LinkedHashSet<int> _prefetchQueue = LinkedHashSet<int>();
  static bool _prefetchScheduled = false;

  /// Opt-in font log (`--dart-define=QO_FRAME_LOG=true`), with the frame log.
  static const _log = bool.fromEnvironment('QO_FRAME_LOG');
  static bool _inPrefetch = false;

  static String familyForPage(int pageNumber) =>
      '${QpcV2Assets.pageFontFamilyPrefix}$pageNumber';

  /// Set by [QoWidgetsBinding]. When true, the "fonts changed" message that
  /// follows each page-font registration is dropped (see
  /// [consumeOwnFontChange]) instead of re-laying out the whole app.
  static bool skipRelayoutOnRegister = false;
  static int _ownFontChanges = 0;

  /// True when the next "fonts changed" message comes from a page font this
  /// loader registered. Such a message needs no relayout: a page's family
  /// name is unique and no text uses it before [ensurePageFontLoaded]
  /// completes, so no existing paragraph can look different afterwards.
  static bool consumeOwnFontChange() {
    if (_ownFontChanges <= 0) return false;
    _ownFontChanges--;
    return true;
  }

  static bool isLoaded(int pageNumber) =>
      _loadedFamilies.containsKey(pageNumber);

  /// Loads [pageNumber]'s font now (the page is about to be shown).
  static Future<String> ensurePageFontLoaded(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604, 'pageNumber');
    }
    final cached = _loadedFamilies[pageNumber];
    if (cached != null) return Future.value(cached);
    if (_log && !_inPrefetch && !_loading.containsKey(pageNumber)) {
      debugPrint('[MushafFont] on-demand p=$pageNumber');
    }
    _prefetchQueue.remove(pageNumber);

    return _loading.putIfAbsent(pageNumber, () async {
      final family = familyForPage(pageNumber);
      try {
        final data = await rootBundle.load(
          QpcV2Assets.pageFontAssetPath(pageNumber),
        );
        final loader = FontLoader(family);
        loader.addFont(Future.value(data));
        final counted = skipRelayoutOnRegister;
        if (counted) _ownFontChanges++;
        try {
          await loader.load();
        } catch (_) {
          // No "fonts changed" message follows a failed load.
          if (counted && _ownFontChanges > 0) _ownFontChanges--;
          rethrow;
        }
        _loadedFamilies[pageNumber] = family;
        if (_log) debugPrint('[MushafFont] registered p=$pageNumber');
        return family;
      } finally {
        _loading.remove(pageNumber);
      }
    });
  }

  /// Queues fonts for nearby pages; they load in idle time, not mid-turn.
  /// Earlier entries in [pageNumbers] load first.
  static void prefetchPages(Iterable<int> pageNumbers) {
    for (final page in pageNumbers) {
      if (page < 1 || page > 604) continue;
      if (_loadedFamilies.containsKey(page) || _loading.containsKey(page)) {
        continue;
      }
      _prefetchQueue.add(page);
    }
    _schedulePrefetch();
  }

  /// Frames to wait for an animation to stop before loading anyway (about
  /// half a second at 60 Hz), so an endless animation cannot starve prefetch.
  static const _maxWaitFrames = 30;
  static int _waitedFrames = 0;

  static void _schedulePrefetch() {
    if (_prefetchScheduled || _prefetchQueue.isEmpty) return;
    _prefetchScheduled = true;
    _waitedFrames = 0;
    // Checked after each frame instead of scheduleTask(Priority.idle): the
    // scheduler re-posts a blocked idle task as a zero-delay timer, which
    // spins the event loop for as long as an animation runs.
    final binding = SchedulerBinding.instance;
    binding.addPostFrameCallback(
      _afterFrame,
      debugLabel: 'QpcV2FontLoader.prefetch',
    );
    binding.ensureVisualUpdate();
  }

  static void _afterFrame(Duration _) {
    if (!_prefetchScheduled) return;
    final binding = SchedulerBinding.instance;
    // A ticking animation has already asked for the next frame here.
    if (binding.transientCallbackCount > 0 && _waitedFrames < _maxWaitFrames) {
      _waitedFrames++;
      binding.addPostFrameCallback(
        _afterFrame,
        debugLabel: 'QpcV2FontLoader.prefetch',
      );
      binding.ensureVisualUpdate();
      return;
    }
    unawaited(_runPrefetchBatch());
  }

  static Future<void> _runPrefetchBatch() async {
    try {
      final batch = _prefetchQueue.take(_prefetchBatch).toList();
      _prefetchQueue.removeAll(batch);
      if (_log) {
        debugPrint('[MushafFont] idle batch $batch waited=$_waitedFrames');
      }
      _inPrefetch = true;
      final loads = batch.map(ensurePageFontLoaded).toList();
      _inPrefetch = false;
      await Future.wait(
        loads.map(
          (load) => load.then<void>((_) {}, onError: (Object _) {}),
        ),
      );
    } finally {
      _prefetchScheduled = false;
      _schedulePrefetch();
    }
  }

  @visibleForTesting
  static List<int> get debugPrefetchQueue => _prefetchQueue.toList();

  @visibleForTesting
  static void debugNoteOwnFontChange() => _ownFontChanges++;

  @visibleForTesting
  static void debugReset() {
    _loadedFamilies.clear();
    _loading.clear();
    _prefetchQueue.clear();
    _prefetchScheduled = false;
    _ownFontChanges = 0;
  }
}
