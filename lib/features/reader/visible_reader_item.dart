import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// List index that should count as the current reading position.
///
/// The usual choice is the item nearest the top of the viewport. When several
/// short ayahs share the screen, that top item stays about two ayahs behind
/// the end. If the last item is already on screen with them, the position is
/// the last item.
int? visibleReaderItemIndex(
  Iterable<ItemPosition> positions, {
  int? lastItemIndex,
}) {
  if (positions.isEmpty) return null;

  final visiblePositions = positions.where((pos) {
    return pos.itemTrailingEdge > 0 &&
        pos.itemLeadingEdge < 1.0 &&
        pos.index >= 0;
  }).toList();

  int? targetIndex;
  if (visiblePositions.isNotEmpty) {
    visiblePositions.sort(
      (a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge),
    );
    final topItem = visiblePositions.first;
    if (topItem.itemLeadingEdge < -0.3 && visiblePositions.length > 1) {
      targetIndex = visiblePositions[1].index;
    } else {
      targetIndex = topItem.index;
    }
  }

  if (targetIndex == null) {
    final passedTop = positions
        .where((pos) => pos.itemTrailingEdge > 0 && pos.index >= 0)
        .toList();
    if (passedTop.isNotEmpty) {
      passedTop.sort(
        (a, b) => a.itemTrailingEdge.compareTo(b.itemTrailingEdge),
      );
      targetIndex = passedTop.first.index;
    }
  }

  if (targetIndex == null || targetIndex < 0) return null;

  if (lastItemIndex != null && lastItemIndex >= 0) {
    ItemPosition? last;
    for (final pos in positions) {
      if (pos.index == lastItemIndex) {
        last = pos;
        break;
      }
    }
    if (_lastAyahCountsAsPosition(last, targetIndex, lastItemIndex)) {
      return lastItemIndex;
    }
  }

  return targetIndex;
}

/// True when the last card is on screen together with the top card, so the
/// top-of-viewport rule would otherwise stop a couple of ayahs early.
bool _lastAyahCountsAsPosition(
  ItemPosition? last,
  int topIndex,
  int lastItemIndex,
) {
  if (last == null) return false;
  final onScreen = last.itemLeadingEdge < 1.0 && last.itemTrailingEdge > 0;
  if (!onScreen) return false;

  final gap = lastItemIndex - topIndex;
  if (gap < 0) return false;

  // Fully shown, or only a slight clip at the bottom of a short card.
  if (last.itemTrailingEdge <= 1.2) return true;

  // End cluster: a few short ayahs fill the screen and the last one is in view.
  return gap <= 4 && last.itemLeadingEdge < 0.85;
}
