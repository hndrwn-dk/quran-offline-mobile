import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/floating_nav_bar.dart';

void main() {
  const destinations = <FloatingNavDestination>[
    FloatingNavDestination(
      key: Key('nav_home'),
      icon: Icons.foundation_outlined,
      selectedIcon: Icons.foundation,
      label: 'Beranda',
    ),
    FloatingNavDestination(
      key: Key('nav_read'),
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories,
      label: 'Baca',
    ),
    FloatingNavDestination(
      key: Key('nav_search'),
      icon: Icons.travel_explore_outlined,
      selectedIcon: Icons.travel_explore,
      label: 'Cari',
    ),
    FloatingNavDestination(
      key: Key('nav_explore'),
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books,
      label: 'Jelajahi',
    ),
    FloatingNavDestination(
      key: Key('nav_library'),
      icon: Icons.collections_bookmark_outlined,
      selectedIcon: Icons.collections_bookmark,
      label: 'Koleksi',
    ),
  ];

  Future<void> pumpBar(
    WidgetTester tester, {
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('keeps tab order and shows only the selected label',
      (tester) async {
    await pumpBar(tester, selectedIndex: 0, onSelected: (_) {});

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Baca'), findsNothing);
    expect(find.text('Cari'), findsNothing);
    expect(find.text('Jelajahi'), findsNothing);
    expect(find.text('Koleksi'), findsNothing);

    final home = tester.getTopLeft(find.byKey(const Key('nav_home')));
    final read = tester.getTopLeft(find.byKey(const Key('nav_read')));
    final search = tester.getTopLeft(find.byKey(const Key('nav_search')));
    final explore = tester.getTopLeft(find.byKey(const Key('nav_explore')));
    final library = tester.getTopLeft(find.byKey(const Key('nav_library')));
    expect(home.dx, lessThan(read.dx));
    expect(read.dx, lessThan(search.dx));
    expect(search.dx, lessThan(explore.dx));
    expect(explore.dx, lessThan(library.dx));

    expect(
        tester.getSize(find.byKey(const Key('nav_read'))), const Size(48, 48));
    final selected = tester.getSize(find.byKey(const Key('nav_home')));
    expect(selected.height, 48);
    expect(selected.width, greaterThan(48));
    expect(
      tester.getSize(find.byKey(const Key('floating_nav_capsule'))).height,
      FloatingNavBar.barHeight,
    );
  });

  testWidgets('tap reports the destination index', (tester) async {
    int? tapped;
    await pumpBar(tester,
        selectedIndex: 0, onSelected: (index) => tapped = index);

    await tester.tap(find.byKey(const Key('nav_search')));
    expect(tapped, 2);
  });

  testWidgets('marks the selected destination in semantics', (tester) async {
    await pumpBar(tester, selectedIndex: 3, onSelected: (_) {});

    final selectedNode =
        tester.getSemantics(find.byKey(const Key('nav_explore')));
    expect(selectedNode.label, 'Jelajahi');
    expect(selectedNode.flagsCollection.isSelected.name, 'isTrue');
    expect(selectedNode.flagsCollection.isButton, isTrue);
    final idleNode = tester.getSemantics(find.byKey(const Key('nav_home')));
    expect(idleNode.label, 'Beranda');
    expect(idleNode.flagsCollection.isSelected.name, 'isFalse');
    expect(idleNode.flagsCollection.isButton, isTrue);
    expect(find.text('Jelajahi'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
  });

  test('clearance is the bar, its margin, and the system inset', () {
    expect(
      floatingNavBarBottomPadding(
        const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 20)),
      ),
      FloatingNavBar.barHeight + FloatingNavBar.bottomMargin + 20,
    );
    expect(
      floatingNavBarBottomPadding(
        const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 320)),
      ),
      0,
    );
  });
}
