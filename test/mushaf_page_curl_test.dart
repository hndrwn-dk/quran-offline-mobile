import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_overlay.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pages actually laid out by the pager (excludes the offscreen snapshot farm).
List<int> _pagesInPager(WidgetTester tester) {
  final bodies = tester.widgetList<MushafPageBody>(
    find.descendant(
      of: find.byType(PageView),
      matching: find.byType(MushafPageBody, skipOffstage: false),
    ),
  );
  final pages = bodies.map((body) => body.pageNo).toList()..sort();
  return pages;
}

Future<void> _pumpView(
  WidgetTester tester,
  Size size, {
  int initialPage = 1,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(disableAnimations: disableAnimations),
              child: MushafPageView(initialPage: initialPage),
            );
          },
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

/// Lets a turn animation finish and any snapshot warm-up settle.
Future<void> _settleTurn(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _showChrome(WidgetTester tester, Offset center) async {
  await tester.tapAt(center);
  await tester.pump(const Duration(milliseconds: 220));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'language': 'id',
      'appLanguage': 'id',
    });
  });

  group('curl mode (default)', () {
    testWidgets('pager does not slide; the leaf owns the turn', (tester) async {
      await _pumpView(tester, const Size(933, 704), initialPage: 1);

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.physics, isA<NeverScrollableScrollPhysics>());
      expect(find.byType(MushafPageTurnOverlay), findsOneWidget);
    });

    testWidgets('a drag released below 35% springs back and keeps the page',
        (tester) async {
      await _pumpView(tester, const Size(933, 704), initialPage: 1);
      final prefs = await SharedPreferences.getInstance();

      final gesture = await tester.startGesture(const Offset(466, 352));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      // 60 / 446 px ~ 13%.
      expect(find.byType(MushafPageTurnOverlay), findsOneWidget);
      await gesture.up();
      await _settleTurn(tester);

      expect(_pagesInPager(tester), [1, 2]);
      expect(prefs.getInt('last_read_position_id'), 1);
      await _showChrome(tester, const Offset(466, 352));
      expect(find.text('Mushaf - Halaman 1–2'), findsOneWidget);
    });

    testWidgets('a drag past the threshold completes and updates last read',
        (tester) async {
      await _pumpView(tester, const Size(933, 704), initialPage: 1);
      final prefs = await SharedPreferences.getInstance();

      final gesture = await tester.startGesture(const Offset(300, 352));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(300, 0));
      await tester.pump();
      // The overlay is up while the leaf is lifted.
      expect(find.byType(MushafPageTurnOverlay), findsOneWidget);
      await gesture.up();
      await _settleTurn(tester);

      expect(_pagesInPager(tester), [3, 4]);
      expect(prefs.getInt('last_read_position_id'), 3);
      // A drag must not toggle the immersive bars.
      expect(find.text('Mushaf - Halaman 3–4'), findsNothing);
    });

    testWidgets('edge tap turns forward; a centre tap toggles the bars',
        (tester) async {
      await _pumpView(tester, const Size(933, 704), initialPage: 1);

      // Outer 12% of the right page (right page is 478..925 here).
      await tester.tapAt(const Offset(910, 352));
      await _settleTurn(tester);
      expect(_pagesInPager(tester), [3, 4]);

      await _showChrome(tester, const Offset(466, 352));
      expect(find.text('Mushaf - Halaman 3–4'), findsOneWidget);
      expect(_pagesInPager(tester), [3, 4]);
    });

    testWidgets('edge tap on the left goes back', (tester) async {
      await _pumpView(tester, const Size(933, 704), initialPage: 4);

      await tester.tapAt(const Offset(30, 352));
      await _settleTurn(tester);
      expect(_pagesInPager(tester), [1, 2]);
    });

    testWidgets('no turn before page 1 or after page 604', (tester) async {
      await _pumpView(tester, const Size(933, 704), initialPage: 1);
      await tester.tapAt(const Offset(30, 352)); // back at the first spread
      await _settleTurn(tester);
      expect(_pagesInPager(tester), [1, 2]);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpView(tester, const Size(933, 704), initialPage: 603);
      await tester.tapAt(const Offset(910, 352)); // forward at the last spread
      await _settleTurn(tester);
      expect(_pagesInPager(tester), [603, 604]);
    });

    testWidgets('single page taps turn one page', (tester) async {
      await _pumpView(tester, const Size(390, 844), initialPage: 1);

      await tester.tapAt(const Offset(384, 400));
      await _settleTurn(tester);
      expect(_pagesInPager(tester), [2]);
      expect(find.text('Mushaf - Halaman 2'), findsOneWidget);
    });

    testWidgets('folding mid-turn cancels the turn and keeps the page',
        (tester) async {
      await _pumpView(tester, const Size(933, 704), initialPage: 1);

      final gesture = await tester.startGesture(const Offset(300, 352));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(200, 0)); // ~50%
      await tester.pump();
      expect(find.byType(MushafPageTurnOverlay), findsOneWidget);

      // Unfold to the cover screen while the leaf is in flight.
      tester.view.physicalSize = const Size(475, 751);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await gesture.up();
      await _settleTurn(tester);

      expect(find.text('Mushaf - Halaman 1'), findsOneWidget);
      expect(_pagesInPager(tester), [1]);
    });
  });

  group('settings', () {
    testWidgets('slide keeps the PageView behaviour and no edge taps',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'language': 'id',
        'appLanguage': 'id',
        'mushafPageTurn': 'slide',
      });
      await _pumpView(tester, const Size(933, 704), initialPage: 1);

      expect(
        tester.widget<PageView>(find.byType(PageView)).physics,
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
      expect(find.byType(MushafPageTurnOverlay), findsNothing);

      // The outer edge is not a turn zone in slide mode: it toggles the bars.
      await tester.tapAt(const Offset(910, 352));
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('Mushaf - Halaman 1–2'), findsOneWidget);
      expect(_pagesInPager(tester), [1, 2]);

      await tester.drag(find.byType(PageView), const Offset(900, 0));
      await _settleTurn(tester);
      expect(_pagesInPager(tester), [3, 4]);
    });

    testWidgets('none changes the page without an animation', (tester) async {
      SharedPreferences.setMockInitialValues({
        'language': 'id',
        'appLanguage': 'id',
        'mushafPageTurn': 'none',
      });
      await _pumpView(tester, const Size(933, 704), initialPage: 1);

      expect(find.byType(MushafPageTurnOverlay), findsNothing);
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pump();
      expect(_pagesInPager(tester), [3, 4]);
    });

    testWidgets('reduced motion behaves as slide', (tester) async {
      await _pumpView(
        tester,
        const Size(933, 704),
        initialPage: 1,
        disableAnimations: true,
      );

      expect(
        tester.widget<PageView>(find.byType(PageView)).physics,
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
      expect(find.byType(MushafPageTurnOverlay), findsNothing);

      await tester.drag(find.byType(PageView), const Offset(900, 0));
      await _settleTurn(tester);
      expect(_pagesInPager(tester), [3, 4]);
    });
  });
}
