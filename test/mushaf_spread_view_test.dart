import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/widgets/mushaf_page_frame.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_sheet.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A page shaped like a real QPC page: surah banner, bismillah, ayah rows.
QpcV2PageContent _pageContent({int pageNumber = 3, int surahId = 2}) {
  final lines = <QpcV2Line>[
    QpcV2Line(
      lineNumber: 1,
      lineType: 'surah_name',
      isCentered: true,
      surahId: surahId,
    ),
    QpcV2Line(
      lineNumber: 2,
      lineType: 'basmallah',
      isCentered: true,
      surahId: surahId,
    ),
  ];
  var lineNumber = 3;
  for (var ayah = 1; ayah <= 13; ayah++) {
    lines.add(
      QpcV2Line(
        lineNumber: lineNumber++,
        lineType: 'ayah',
        isCentered: false,
        words: [
          QpcV2Word(
            id: ayah,
            surah: surahId,
            ayah: ayah,
            word: 1,
            glyph: 'ﱁﱂﱃ',
            location: '$surahId:$ayah:1',
          ),
        ],
      ),
    );
  }
  return QpcV2PageContent(
    pageNumber: pageNumber,
    lines: lines,
    fontFamily: 'UthmanicHafsV22',
    basmallahFontFamily: 'UthmanicHafsV22',
    bismillahGlyphText: 'ﱁﱂﱃﱄ',
  );
}

/// The page frame itself (the glyph glyph's own FittedBox uses scaleDown).
final Finder _pageFrameBoxes = find.byWidgetPredicate(
  (widget) => widget is FittedBox && widget.fit == BoxFit.contain,
);

void _setViewSize(WidgetTester tester, Size size) {  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpSpread(
  WidgetTester tester,
  Size size, {
  int leftPage = 4,
  int rightPage = 3,
  MushafHingeLayout hinge = const MushafHingeLayout(),
}) async {
  _setViewSize(tester, size);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MushafSpreadRow(
              hinge: hinge,
              left: MushafPageSheet(
                key: ValueKey<int>(leftPage),
                content: _pageContent(pageNumber: leftPage),
                colorScheme: Theme.of(context).colorScheme,
                ayahKeys: <String, GlobalKey>{},
              ),
              right: MushafPageSheet(
                key: ValueKey<int>(rightPage),
                content: _pageContent(pageNumber: rightPage),
                colorScheme: Theme.of(context).colorScheme,
                ayahKeys: <String, GlobalKey>{},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('spread rendering', () {
    testWidgets('even page is left, odd page is right', (tester) async {
      await _pumpSpread(tester, const Size(933, 704));

      final left = tester.getRect(find.byKey(const ValueKey<int>(4)));
      final right = tester.getRect(find.byKey(const ValueKey<int>(3)));
      expect(left.left, lessThan(right.left));
      expect(left.right, lessThanOrEqualTo(right.left));
    });

    testWidgets('both pages share one frame size and scale', (tester) async {
      await _pumpSpread(tester, const Size(933, 704));

      final frames = find.byType(MushafPageFrame);
      expect(frames, findsNWidgets(2));
      final first = tester.getSize(_pageFrameBoxes.at(0));
      final second = tester.getSize(_pageFrameBoxes.at(1));
      expect(first, second);
      expect(first.width / first.height, closeTo(0.65, 0.001));
      expect(
        mushafPageScaleFor(first),
        closeTo(mushafPageScaleFor(second), 1e-9),
      );
    });

    testWidgets('page frames never grow past the window height', (tester) async {
      for (final size in const [
        Size(933, 704),
        Size(1024, 768),
        Size(955, 860),
      ]) {
        await _pumpSpread(tester, size);
        final frame = tester.getSize(_pageFrameBoxes.first);
        expect(frame.height, lessThanOrEqualTo(size.height));
        expect(frame.width, lessThanOrEqualTo(size.width / 2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('hinge gap keeps text off the crease', (tester) async {
      const hinge = MushafHingeLayout(gap: 40);
      await _pumpSpread(tester, const Size(933, 704), hinge: hinge);

      final left = tester.getRect(find.byKey(const ValueKey<int>(4)));
      final right = tester.getRect(find.byKey(const ValueKey<int>(3)));
      expect(right.left - left.right, closeTo(40, 0.01));
    });

    testWidgets('single page keeps the same 0.65 frame on a phone',
        (tester) async {
      _setViewSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => MushafPageSheet(
                  content: _pageContent(pageNumber: 2),
                  colorScheme: Theme.of(context).colorScheme,
                  ayahKeys: <String, GlobalKey>{},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final frame = tester.getSize(_pageFrameBoxes);
      expect(frame.width / frame.height, closeTo(0.65, 0.001));
      expect(frame.width, lessThanOrEqualTo(390));
      expect(tester.takeException(), isNull);
    });

    testWidgets('surah banner and bismillah never overflow their slots',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(933, 704),
        Size(1024, 768),
        Size(475, 751),
      ]) {
        await _pumpSpread(tester, size);
        expect(tester.takeException(), isNull);
        // 15 layout rows fit the fixed reference page exactly.
        expect(kMushafPageRowHeight * kMushafPageLineCount,
            closeTo(kMushafPageLayoutHeight, 0.001));
      }
    });
  });

  group('mushaf page view', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'language': 'id',
        'appLanguage': 'id',
      });
    });

    Future<void> pumpView(
      WidgetTester tester,
      Size size, {
      int initialPage = 1,
    }) async {
      _setViewSize(tester, size);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: MushafPageView(initialPage: initialPage)),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
    }

    testWidgets('spread AppBar shows the localized page pair', (tester) async {
      await pumpView(tester, const Size(933, 704), initialPage: 1);
      expect(find.text('Mushaf - Halaman 1–2'), findsOneWidget);
    });

    testWidgets('two page bodies are laid out on a Fold inner screen',
        (tester) async {
      await pumpView(tester, const Size(933, 704), initialPage: 1);
      expect(find.byType(MushafPageBody, skipOffstage: false), findsNWidgets(2));
    });

    testWidgets('single page on the cover screen', (tester) async {
      await pumpView(tester, const Size(475, 751), initialPage: 4);
      expect(find.byType(MushafPageBody, skipOffstage: false), findsOneWidget);
      expect(find.text('Mushaf - Halaman 4'), findsOneWidget);
    });

    testWidgets('fold and unfold keeps the page in view', (tester) async {
      await pumpView(tester, const Size(933, 704), initialPage: 4);
      expect(find.text('Mushaf - Halaman 3–4'), findsOneWidget);

      tester.view.physicalSize = const Size(475, 751);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Mushaf - Halaman 4'), findsOneWidget);

      tester.view.physicalSize = const Size(933, 704);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Mushaf - Halaman 3–4'), findsOneWidget);
    });

    testWidgets('last read follows spread navigation', (tester) async {
      await pumpView(tester, const Size(933, 704), initialPage: 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('last_read_position_id'), 1);

      await tester.drag(find.byType(PageView), const Offset(900, 0));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(find.text('Mushaf - Halaman 3–4'), findsOneWidget);
      expect(prefs.getInt('last_read_position_id'), 3);
    });

    testWidgets('spread setting off renders one page at a time',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'language': 'id',
        'appLanguage': 'id',
        'mushafTwoPageSpread': false,
      });
      await pumpView(tester, const Size(933, 704), initialPage: 4);

      expect(find.byType(MushafPageBody, skipOffstage: false), findsOneWidget);
      expect(find.text('Mushaf - Halaman 4'), findsOneWidget);
    });
  });
}
