import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/features/reader/visible_reader_item.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

ItemPosition _pos(int index, double leading, double trailing) {
  return ItemPosition(
    index: index,
    itemLeadingEdge: leading,
    itemTrailingEdge: trailing,
  );
}

void main() {
  test('uses the item nearest the top of the viewport', () {
    final index = visibleReaderItemIndex([
      _pos(10, -0.1, 0.3),
      _pos(11, 0.3, 0.7),
      _pos(12, 0.7, 1.1),
    ]);

    expect(index, 10);
  });

  test('skips a top item that is mostly above the viewport', () {
    final index = visibleReaderItemIndex([
      _pos(10, -0.5, 0.1),
      _pos(11, 0.1, 0.6),
      _pos(12, 0.6, 1.1),
    ]);

    expect(index, 11);
  });

  test('end of a surah: last ayah on screen counts, not two before it', () {
    // Header is index 0. Ayah 94/95/96 are indexes 94/95/96.
    // 94 stays at the top because the list cannot scroll the last card up.
    final index = visibleReaderItemIndex(
      [
        _pos(94, -0.2, 0.15),
        _pos(95, 0.15, 0.55),
        _pos(96, 0.55, 0.9),
      ],
      lastItemIndex: 96,
    );

    expect(index, 96);
  });

  test('short surah on one screen counts the last ayah, not the top one', () {
    final index = visibleReaderItemIndex(
      [
        _pos(0, 0.02, 0.2),
        _pos(1, 0.2, 0.4),
        _pos(2, 0.4, 0.62),
        _pos(3, 0.62, 0.84),
        _pos(4, 0.84, 1.05),
      ],
      lastItemIndex: 4,
    );

    expect(index, 4);
  });

  test('short surah end still counts when the last card is slightly clipped', () {
    final index = visibleReaderItemIndex(
      [
        _pos(4, -0.05, 0.35),
        _pos(5, 0.35, 0.7),
        _pos(6, 0.7, 1.15),
      ],
      lastItemIndex: 6,
    );

    expect(index, 6);
  });

  test('keeps the top ayah when the last card is still cut off', () {
    final index = visibleReaderItemIndex(
      [
        _pos(90, -0.1, 0.4),
        _pos(91, 0.4, 0.85),
        _pos(96, 0.85, 1.4),
      ],
      lastItemIndex: 96,
    );

    expect(index, 90);
  });
}
