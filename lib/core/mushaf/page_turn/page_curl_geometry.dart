import 'dart:math' as math;
import 'dart:ui';

/// Where the moving leaf sits for one turn, in stage coordinates.
///
/// Leaf space (u, v): u is the distance from the spine towards the leaf's free
/// edge, v the distance from the leaf's top. The front sheet covers
/// u in [[innerOffset], [freeEdge]] and v in [0, height]; once turned, the
/// leaf lies mirrored on the other side of the spine.
class PageCurlLeaf {
  const PageCurlLeaf({
    required this.rect,
    required this.hingeX,
    required this.side,
  });

  /// Spread: the page that turns, hinged at the middle of the gutter.
  ///
  /// Forward (1|2 -> 3|4) lifts the LEFT sheet; backward lifts the right one.
  factory PageCurlLeaf.spread({
    required Rect left,
    required Rect right,
    required bool forward,
  }) {
    final hinge = (left.right + right.left) / 2;
    return PageCurlLeaf(
      rect: forward ? left : right,
      hingeX: hinge,
      side: forward ? 1 : -1,
    );
  }

  /// Single page: the spine is the sheet's right edge; forward lifts the left.
  factory PageCurlLeaf.single(Rect sheet) =>
      PageCurlLeaf(rect: sheet, hingeX: sheet.right, side: 1);

  /// Front sheet of the leaf.
  final Rect rect;

  /// Spine x.
  final double hingeX;

  /// +1 when the leaf lies left of the spine, -1 when it lies right.
  final double side;

  double get width => rect.width;
  double get height => rect.height;

  /// Gap between the spine and the leaf's inner edge (half the gutter).
  double get innerOffset =>
      math.max(0, side > 0 ? hingeX - rect.right : rect.left - hingeX);

  /// u of the free (outer) edge.
  double get freeEdge => innerOffset + width;

  Offset toLeaf(Offset stage) =>
      Offset(side * (hingeX - stage.dx), stage.dy - rect.top);

  Offset toStage(Offset leaf) =>
      Offset(hingeX - side * leaf.dx, leaf.dy + rect.top);
}

/// Fold of the leaf for one frame (leaf space), as the shader consumes it.
class PageCurlFrame {
  const PageCurlFrame({
    required this.origin,
    required this.normal,
    required this.radius,
    required this.progress,
    required this.strength,
  });

  /// Untouched leaf: the fold sits on the free edge with no curl.
  factory PageCurlFrame.flat(PageCurlLeaf leaf) => PageCurlFrame(
        origin: Offset(leaf.freeEdge, 0),
        normal: const Offset(1, 0),
        radius: 0,
        progress: 0,
        strength: 0,
      );

  /// A point on the fold line.
  final Offset origin;

  /// Unit normal of the fold line, pointing towards the free edge.
  final Offset normal;

  /// Cylinder radius (px).
  final double radius;

  /// 0 = leaf flat on its own side, 1 = landed on the other side.
  final double progress;

  /// Shadow strength 0..1 (fades out at rest and on landing).
  final double strength;

  /// Signed distance of a leaf-space point from the fold line.
  double distance(Offset p) =>
      (p.dx - origin.dx) * normal.dx + (p.dy - origin.dy) * normal.dy;
}

/// Default cylinder radius as a share of the page width.
const double kPageCurlRadiusFactor = 0.10;

/// Steepest fold the leaf allows: the normal stays within 60 degrees of the
/// page's horizontal, so a vertical drag never folds the page sideways.
const double _kMinNormalX = 0.5;

/// Fold for a finger at [finger] that grabbed the leaf at [grab] (leaf space).
///
/// The grabbed point of the free edge wraps over the cylinder and lands under
/// the finger, so the fold follows the finger's x and y: a lower-corner grab
/// dragged up and across lifts the corner first, a mid-edge drag gives a
/// nearly vertical fold. The fold never crosses the spine inside the page,
/// and the curl flattens at both ends so rest and landing are exact.
PageCurlFrame computePageCurl({
  required PageCurlLeaf leaf,
  required Offset grab,
  required Offset finger,
  double radiusFactor = kPageCurlRadiusFactor,
}) {
  final edge = leaf.freeEdge;
  final h = leaf.height;
  final a = Offset(edge, grab.dy.clamp(0.0, h));
  final f = Offset(
    finger.dx.clamp(-edge, edge),
    finger.dy.clamp(-0.25 * h, 1.25 * h),
  );
  final delta = a - f;
  final len = delta.distance;
  if (len < 0.5) return PageCurlFrame.flat(leaf);

  final r0 = radiusFactor * leaf.width;
  double ramp(double x) => r0 <= 0 ? 0 : (x / (math.pi * r0)).clamp(0.0, 1.0);
  final landing = Offset(-edge, a.dy);
  final radius = r0 * ramp(len) * ramp((f - landing).distance);

  var normal = delta / len;
  if (normal.dx < _kMinNormalX) {
    final dy = normal.dy >= 0 ? 1.0 : -1.0;
    normal = Offset(
      _kMinNormalX,
      dy * math.sqrt(1 - _kMinNormalX * _kMinNormalX),
    );
  }

  // The grabbed point travels len along the paper: down the fold, over the
  // cylinder (pi * r) and back, ending under the finger.
  final fingerDistance = (math.pi * radius - len) / 2;
  var origin = f - normal * fingerDistance;

  // Keep the spine flat: the fold may not reach u < 0 at the top or bottom.
  double uAt(double v) => origin.dx - (v - origin.dy) * normal.dy / normal.dx;
  final minU = math.min(uAt(0), uAt(h));
  if (minU < 0) origin = origin.translate(-minU, 0);

  final progress = ((edge - f.dx) / (2 * edge)).clamp(0.0, 1.0);
  final strength = (math.min(progress, 1 - progress) * 6).clamp(0.0, 1.0);
  return PageCurlFrame(
    origin: origin,
    normal: normal,
    radius: radius,
    progress: progress,
    strength: strength,
  );
}

/// Grab point for a non-interactive turn (tap, audio): near the lower corner.
Offset pageCurlAutoGrab(PageCurlLeaf leaf) =>
    Offset(leaf.freeEdge, leaf.height * 0.9);

/// Finger position of a non-interactive turn at [t] (0..1).
///
/// The finger sweeps from the free edge to its landing spot and rises a little
/// on the way, so the lower corner leads like a hand-turned page.
Offset pageCurlAutoFinger(PageCurlLeaf leaf, double t) {
  final grab = pageCurlAutoGrab(leaf);
  final edge = leaf.freeEdge;
  return Offset(
    edge - 2 * edge * t,
    grab.dy - leaf.height * 0.12 * math.sin(math.pi * t),
  );
}
