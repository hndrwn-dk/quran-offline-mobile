import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_geometry.dart';

/// Minimum share of the page interior that must differ from the paper colour
/// before a snapshot counts as painted.
///
/// A blank (never painted / clipped out) boundary rasterizes to a single flat
/// colour: 0% coverage. A real QPC V2 page is mostly ink and rules, comfortably
/// above 1% even on the sparse opening pages.
const double kPageTurnMinInkCoverage = 0.01;

/// Rasterized page snapshots used only while a turn is animating.
///
/// Idle Mushaf pages stay live widgets; the reader only needs pixels of the
/// neighbouring spread (pages that are not in the pager's widget tree) to draw
/// the leaf back and the page underneath. Those neighbours are rasterized while
/// idle and thrown away on every page change, so at most
/// [kPageTurnMaxCachedSnapshots] images are alive.
///
/// Only verified images may enter this cache: see [imageHasInk].
class PageTurnSnapshotCache {
  final Map<int, ui.Image> _images = <int, ui.Image>{};
  int _bytes = 0;

  int get length => _images.length;
  bool get isEmpty => _images.isEmpty;
  Iterable<int> get pages => _images.keys;

  /// Approximate GPU bytes currently held.
  int get byteSize => _bytes;

  ui.Image? imageFor(int pageNo) => _images[pageNo];

  bool contains(int pageNo) => _images.containsKey(pageNo);

  /// Stores [image] for [pageNo]. The previous image (if any) is disposed.
  ///
  /// Evicts the oldest entry when the cache is full or its byte budget is
  /// exceeded; the caller owns the passed image from now on.
  void put(int pageNo, ui.Image image) {
    _remove(pageNo);
    while (_images.length >= kPageTurnMaxCachedSnapshots ||
        (_bytes > 0 && _bytes + _imageBytes(image) > kPageTurnMaxSnapshotBytes)) {
      final oldest = _images.keys.first;
      _remove(oldest);
    }
    _images[pageNo] = image;
    _bytes += _imageBytes(image);
  }

  void removePage(int pageNo) => _remove(pageNo);

  void _remove(int pageNo) {
    final previous = _images.remove(pageNo);
    if (previous == null) return;
    _bytes -= _imageBytes(previous);
    previous.dispose();
  }

  /// Drops every snapshot (call on page change).
  void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    _bytes = 0;
  }

  static int _imageBytes(ui.Image image) => image.width * image.height * 4;

  void dispose() => clear();
}

/// Captures the current pixels of a [RenderRepaintBoundary].
///
/// Returns `null` when the boundary is not attached, not laid out, or still
/// needs paint. Callers must not start a curl with a `null` image: the leaf
/// would be blank paper.
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

/// True when [key]'s boundary has painted at least one frame.
bool snapshotBoundaryIsPainted(GlobalKey? key) {
  final object = key?.currentContext?.findRenderObject();
  if (object is! RenderRepaintBoundary) return false;
  return object.hasSize && !object.debugNeedsPaint;
}

/// Whether [image] carries real page content (ink) instead of flat paper.
///
/// The image is downscaled to a tiny proxy before reading pixels so verification
/// stays cheap even for a 3x device pixel ratio page. The outer 10% of the page
/// is ignored so the paper frame/shadow alone cannot pass as content.
Future<bool> imageHasInk(
  ui.Image image, {
  double minCoverage = kPageTurnMinInkCoverage,
}) async {
  if (image.width < 8 || image.height < 8) return false;
  return await imageInkCoverage(image) >= minCoverage;
}

/// Named draw path used for one turn, for the debug log.
enum PageTurnDrawPath {
  /// Real cylindrical fold drawn by the fragment shader.
  shader,

  /// Mesh/gradient fallback when the shader could not be compiled.
  painterFallback,

  /// No curl: the page changes immediately because a snapshot was not painted.
  instantFallback,
}

/// Logs the draw path once per change so the device log shows which one ran.
void logPageTurnPath(PageTurnDrawPath path, {String? reason}) {
  debugPrint(
    '[MushafCurl] draw=${path.name}${reason == null ? '' : ' ($reason)'}',
  );
}

/// Debug-only handle to a raw image's ink coverage, for tests.
@visibleForTesting
Future<double> imageInkCoverage(ui.Image image) async {
  const proxyWidth = 48;
  const proxyHeight = 64;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(
      0,
      0,
      proxyWidth.toDouble(),
      proxyHeight.toDouble(),
    ),
    Paint()..filterQuality = FilterQuality.low,
  );
  final picture = recorder.endRecording();
  ui.Image? proxy;
  ByteData? data;
  try {
    proxy = await picture.toImage(proxyWidth, proxyHeight);
    data = await proxy.toByteData(format: ui.ImageByteFormat.rawRgba);
  } finally {
    picture.dispose();
    proxy?.dispose();
  }
  if (data == null) return 0;
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  double bg = 0;
  for (final (x, y) in const [(4, 4), (43, 4), (4, 59), (43, 59)]) {
    final i = (y * proxyWidth + x) * 4;
    bg += 0.299 * bytes[i] + 0.587 * bytes[i + 1] + 0.114 * bytes[i + 2];
  }
  bg /= 4;
  var samples = 0;
  var differing = 0;
  for (var y = 6; y < proxyHeight - 6; y++) {
    for (var x = 5; x < proxyWidth - 5; x++) {
      final i = (y * proxyWidth + x) * 4;
      final luma =
          0.299 * bytes[i] + 0.587 * bytes[i + 1] + 0.114 * bytes[i + 2];
      samples++;
      if ((luma - bg).abs() > 26) differing++;
    }
  }
  return samples == 0 ? 0 : differing / samples;
}
