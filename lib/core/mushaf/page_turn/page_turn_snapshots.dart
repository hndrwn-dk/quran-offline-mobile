import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_geometry.dart';

/// Rasterized page snapshots used only while a turn is animating.
///
/// Idle Mushaf pages stay live widgets; the reader only needs pixels of the
/// neighbouring spread (pages that are not in the pager's widget tree) to draw
/// the leaf back and the page underneath. Those neighbours are rasterized while
/// idle and thrown away on every page change, so at most
/// [kPageTurnMaxCachedSnapshots] images are alive.
class PageTurnSnapshotCache {
  final Map<int, ui.Image> _images = <int, ui.Image>{};

  int get length => _images.length;
  bool get isEmpty => _images.isEmpty;
  Iterable<int> get pages => _images.keys;

  ui.Image? imageFor(int pageNo) => _images[pageNo];

  /// Stores [image] for [pageNo]. The previous image (if any) is disposed.
  ///
  /// Evicts the oldest entry when the cache is full; the caller owns the passed
  /// image from now on.
  void put(int pageNo, ui.Image image) {
    final previous = _images.remove(pageNo);
    previous?.dispose();
    while (_images.length >= kPageTurnMaxCachedSnapshots) {
      final oldest = _images.keys.first;
      _images.remove(oldest)?.dispose();
    }
    _images[pageNo] = image;
  }

  void removePage(int pageNo) {
    _images.remove(pageNo)?.dispose();
  }

  /// Drops every snapshot (call on page change).
  void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }

  void dispose() => clear();
}

/// Captures the current pixels of a [RenderRepaintBoundary].
///
/// Returns `null` when the boundary is not attached, not laid out, or still
/// needs paint — a turn then simply draws the page tone until the next warm-up.
ui.Image? capturePageSnapshot(
  RenderRepaintBoundary? boundary, {
  required double pixelRatio,
}) {
  if (boundary == null || !boundary.hasSize || boundary.debugNeedsPaint) {
    return null;
  }
  if (boundary.size.width <= 0 || boundary.size.height <= 0) return null;
  return boundary.toImageSync(pixelRatio: pixelRatio);
}

/// Convenience wrapper for a keyed boundary.
ui.Image? capturePageSnapshotFor(
  GlobalKey? key, {
  required double pixelRatio,
}) {
  final object = key?.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return null;
  return capturePageSnapshot(object, pixelRatio: pixelRatio);
}
