import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/juz_surahs_provider.dart';
import 'package:quran_offline/core/providers/page_surahs_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/features/read/read_screen.dart';
import 'package:quran_offline/features/reader/reader_screen.dart';
import 'package:quran_offline/features/reader/widgets/reader_back_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

Verse _verse(int surahId, int ayahNo) => Verse(
      surahId: surahId,
      ayahNo: ayahNo,
      page: 1,
      juz: 1,
      arabic: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
      trEn: 'In the name of Allah',
      trId: 'Dengan nama Allah',
    );

List<Override> _overrides() => [
      readerVersesProvider.overrideWith(
        (ref, source) async => [_verse(1, 1), _verse(1, 2)],
      ),
      surahNamesProvider.overrideWith(
        (ref) async => [
          SurahInfo(
            id: 1,
            arabicName: 'الفاتحة',
            englishName: 'Al-Fatihah',
            englishMeaning: 'The Opening',
          ),
        ],
      ),
      juzSurahsProvider.overrideWith(
        (ref, juzNo) async => JuzSurahsInfo(
          juzNo: juzNo,
          surahIds: const [1],
          surahAyahCounts: const {1: 7},
        ),
      ),
      pageSurahsProvider.overrideWith(
        (ref, pageNo) async => PageSurahsInfo(
          pageNo: pageNo,
          surahIds: const [1],
        ),
      ),
    ];

ProviderContainer _container({ReaderSource? source}) {
  final container = ProviderContainer(overrides: _overrides());
  if (source != null) {
    container.read(readerSourceProvider.notifier).state = source;
  }
  return container;
}

void _setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpReaderScreen(
  WidgetTester tester,
  Size size,
  ProviderContainer container,
) async {
  _setViewSize(tester, size);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ReaderScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'language': 'id',
      'appLanguage': 'id',
    });
  });

  testWidgets('back button target is at least 48dp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ReaderBackButton(onFallback: () {})),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ReaderBackButton)), const Size(48, 48));
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('back button pops a pushed reader route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (routeContext) => Scaffold(
                      appBar: AppBar(
                        leading: ReaderBackButton.appBarLeading(routeContext),
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderBackButton), findsOneWidget);

    await tester.tap(find.byType(ReaderBackButton));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('back button falls back when the navigator cannot pop',
      (tester) async {
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              leading: ReaderBackButton.appBarLeading(
                context,
                onFallback: () => cleared = true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ReaderBackButton));
    await tester.pump();
    expect(cleared, isTrue);
  });

  testWidgets('Surah reader shows the back button on a phone', (tester) async {
    final container = _container(source: SurahSource(1));
    addTearDown(container.dispose);
    await _pumpReaderScreen(tester, const Size(390, 844), container);
    expect(find.byType(ReaderBackButton), findsOneWidget);
  });

  testWidgets('Surah reader shows the back button on Fold inner 933x704',
      (tester) async {
    final container = _container(source: SurahSource(1));
    addTearDown(container.dispose);
    await _pumpReaderScreen(tester, const Size(933, 704), container);
    expect(find.byType(ReaderBackButton), findsOneWidget);
  });

  testWidgets('Juz reader shows the back button on a wide screen',
      (tester) async {
    final container = _container(source: const JuzSource(1));
    addTearDown(container.dispose);
    await _pumpReaderScreen(tester, const Size(933, 704), container);
    expect(find.byType(ReaderBackButton), findsOneWidget);
  });

  testWidgets('tablet split pane reader keeps a back button', (tester) async {
    _setViewSize(tester, const Size(933, 704));
    final container = _container(source: SurahSource(1));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ReadScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.byType(ReaderBackButton), findsOneWidget);

    await tester.tap(find.byType(ReaderBackButton));
    await tester.pump();
    expect(container.read(readerSourceProvider), isNull);
  });
}
