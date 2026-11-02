import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Minimum share of a page's text box that must differ from the paper before
/// a snapshot counts as painted. A real QPC V2 page is several percent ink,
/// even the sparse opening pages; blank paper is 0.
const double kPageSnapshotMinInk = 0.01;

/// Most of a text box a real page ever inks (dense pages are ~15%). More means
/// the snapshot shows something else: an error box, a scrim, a solid fill.
const double kPageSnapshotMaxInk = 0.40;

/// Whether an ink coverage looks like a printed Mushaf page.
bool pageSnapshotInkIsValid(double ink) =>
    ink >= kPageSnapshotMinInk && ink <= kPageSnapshotMaxInk;

/// Waits until everything built so far has been laid out and painted.
Future<void> waitForPaintedFrame() async {
  final binding = SchedulerBinding.instance;
  binding.scheduleFrame();
  await binding.endOfFrame;
  // One more: the first frame after a rebuild may only have laid out.
  binding.scheduleFrame();
  await binding.endOfFrame;
}

/// Rasterizes [boundary] at [pixelRatio] and crops one image per rect.
///
/// [rects] are in the boundary's logical coordinates. The full capture is
/// disposed; the caller owns the returned crops.
List<ui.Image> captureSheetSnapshots(
  RenderRepaintBoundary boundary,
  List<Rect> rects, {
  required double pixelRatio,
}) {
  final full = boundary.toImageSync(pixelRatio: pixelRatio);
  try {
    return [for (final rect in rects) cropImage(full, rect, pixelRatio)];
  } finally {
    full.dispose();
  }
}

/// Copies [rect] (logical px) out of [source] into its own image.
ui.Image cropImage(ui.Image source, Rect rect, double pixelRatio) {
  final src = Rect.fromLTRB(
    (rect.left * pixelRatio).floorToDouble(),
    (rect.top * pixelRatio).floorToDouble(),
    (rect.right * pixelRatio).ceilToDouble(),
    (rect.bottom * pixelRatio).ceilToDouble(),
  ).intersect(
    Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
  );
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    source,
    src,
    Offset.zero & src.size,
    Paint()..filterQuality = FilterQuality.none,
  );
  final picture = recorder.endRecording();
  try {
    return picture.toImageSync(src.width.round(), src.height.round());
  } finally {
    picture.dispose();
  }
}

/// Bytes an image holds on the GPU (RGBA8).
int imageBytes(ui.Image image) => image.width * image.height * 4;

/// Share of pixels in [within] (image px, default: the whole image) that are
/// clearly not [paper].
///
/// A pixel counts as ink when its RGB distance to the paper colour exceeds
/// [threshold] (sum of channel differences, 0..765).
Future<double> snapshotInkCoverage(
  ui.Image image, {
  required Color paper,
  Rect? within,
  int threshold = 60,
}) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return 0;
  return inkCoverageOfRgba(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    width: image.width,
    height: image.height,
    paper: paper,
    within: within,
    threshold: threshold,
  );
}

/// [snapshotInkCoverage] on raw RGBA bytes.
double inkCoverageOfRgba(
  Uint8List bytes, {
  required int width,
  required int height,
  required Color paper,
  Rect? within,
  int threshold = 60,
}) {
  final region = (within ?? Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()))
      .intersect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  if (region.isEmpty) return 0;
  final pr = (paper.r * 255).round();
  final pg = (paper.g * 255).round();
  final pb = (paper.b * 255).round();
  var ink = 0;
  var total = 0;
  for (var y = region.top.floor(); y < region.bottom.floor(); y++) {
    var i = (y * width + region.left.floor()) * 4;
    for (var x = region.left.floor(); x < region.right.floor(); x++, i += 4) {
      total++;
      final d = (bytes[i] - pr).abs() +
          (bytes[i + 1] - pg).abs() +
          (bytes[i + 2] - pb).abs();
      if (d > threshold) ink++;
    }
  }
  return total == 0 ? 0 : ink / total;
}
