import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/features/home/widgets/home_collection_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _t0 = DateTime(2026, 10, 1, 9);

Note _note(int surah, int ayah, String text, int minutes) => Note(
      surahId: surah,
      ayahNo: ayah,
      note: text,
      createdAt: _t0,
      updatedAt: _t0.add(Duration(minutes: minutes)),
    );

Bookmark _bookmark(int surah, int ayah, int minutes) => Bookmark(
      surahId: surah,
      ayahNo: ayah,
      createdAt: _t0.add(Duration(minutes: minutes)),
      openContext: 'surah',
    );

Highlight _highlight(int surah, int ayah, int minutes) => Highlight(
      surahId: surah,
      ayahNo: ayah,
      color: 0xFFFFD54F,
      createdAt: _t0.add(Duration(minutes: minutes)),
    );

final _surahs = [
  SurahInfo(
      id: 1, arabicName: '', englishName: 'Al-Fatihah', englishMeaning: ''),
  SurahInfo(
      id: 2, arabicName: '', englishName: 'Al-Baqarah', englishMeaning: ''),
  SurahInfo(id: 18, arabicName: '', englishName: 'Al-Kahf', englishMeaning: ''),
];

late WidgetRef _ref;

Future<void> _pump(
  WidgetTester tester, {
  List<Note> notes = const [],
  List<Bookmark> bookmarks = const [],
  List<Highlight> highlights = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'language': 'id',
    'appLanguage': 'id',
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notesProvider.overrideWith((ref) async => notes),
        bookmarksProvider.overrideWith((ref) async => bookmarks),
        highlightsProvider.overrideWith((ref) async => highlights),
        surahNamesProvider.overrideWith((ref) async => _surahs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              _ref = ref;
              return const SingleChildScrollView(
                child: HomeCollectionSection(),
              );
            },
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('feed', () {
    test('newest first across notes, bookmarks and highlights', () {
      final feed = buildHomeCollectionFeed(
        notes: [_note(1, 6, 'u', 30), _note(2, 255, 'old', 1)],
        bookmarks: [_bookmark(18, 10, 50)],
        highlights: [_highlight(2, 2, 40), _highlight(1, 1, 5)],
      );
      expect(
        feed.map((i) => '${i.kind.name} ${i.surahId}:${i.ayahNo}').toList(),
        [
          'bookmark 18:10',
          'highlight 2:2',
          'note 1:6',
          'highlight 1:1',
        ],
      );
    });

    test('one row per type and ayah, capped at the limit', () {
      final feed = buildHomeCollectionFeed(
        notes: [],
        bookmarks: [
          for (var m = 0; m < 6; m++) _bookmark(2, m + 1, m),
          _bookmark(2, 6, 99),
        ],
        highlights: [],
      );
      expect(feed.length, kHomeCollectionLimit);
      expect(feed.where((i) => i.ayahNo == 6).length, 1);
    });
  });

  group('section', () {
    testWidgets('one KOLEKSI section with count chips, zero counts hidden',
        (tester) async {
      await _pump(
        tester,
        notes: [_note(1, 6, 'catatan', 30), _note(2, 3, 'lagi', 20)],
        bookmarks: [
          _bookmark(18, 10, 50),
          _bookmark(2, 1, 10),
          _bookmark(2, 2, 11),
          _bookmark(2, 3, 12),
        ],
      );

      expect(find.text('KOLEKSI'), findsOneWidget);
      expect(find.text('CATATAN'), findsNothing);
      expect(find.text('2 catatan'), findsOneWidget);
      expect(find.text('4 penanda'), findsOneWidget);
      expect(
        find.byKey(const Key('home_collection_chip_highlight')),
        findsNothing,
      );
      expect(find.text('Lihat semua ›'), findsOneWidget);
    });

    testWidgets('rows: "Surah · QS s:a", note snippet or type', (tester) async {
      await _pump(
        tester,
        notes: [_note(1, 6, '  sabar   itu\nindah  ', 30)],
        bookmarks: [_bookmark(18, 10, 50)],
        highlights: [_highlight(2, 2, 40)],
      );

      expect(find.byKey(const Key('home_collection_row_0')), findsOneWidget);
      expect(find.text('Al-Kahf · QS 18:10'), findsOneWidget);
      expect(find.text('Penanda'), findsOneWidget);
      expect(find.text('Al-Baqarah · QS 2:2'), findsOneWidget);
      expect(find.text('Sorotan'), findsOneWidget);
      expect(find.text('Al-Fatihah · QS 1:6'), findsOneWidget);
      final snippet = tester.widget<Text>(find.text('sabar itu indah'));
      expect(snippet.style?.fontStyle, FontStyle.italic);
      expect(snippet.maxLines, 1);

      // Newest first: bookmark (50), highlight (40), note (30).
      final y = [
        tester.getTopLeft(find.text('Al-Kahf · QS 18:10')).dy,
        tester.getTopLeft(find.text('Al-Baqarah · QS 2:2')).dy,
        tester.getTopLeft(find.text('Al-Fatihah · QS 1:6')).dy,
      ];
      expect(y[0] < y[1] && y[1] < y[2], isTrue);
    });

    testWidgets('empty state when nothing is saved', (tester) async {
      await _pump(tester);
      expect(
        find.text(
          'Belum ada catatan, penanda, atau sorotan. Simpan saat kamu membaca.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home_collection_chip_note')), findsNothing);
    });

    testWidgets('chips open the Koleksi screen on their part', (tester) async {
      await _pump(
        tester,
        notes: [_note(1, 6, 'a', 1)],
        bookmarks: [_bookmark(2, 1, 2)],
        highlights: [_highlight(2, 2, 3)],
      );

      for (final (kind, tab) in [
        ('note', 1),
        ('bookmark', 0),
        ('highlight', 2),
      ]) {
        _ref.read(currentTabProvider.notifier).state = AppTab.home;
        await tester.tap(find.byKey(Key('home_collection_chip_$kind')));
        await tester.pump();
        expect(_ref.read(librarySubTabProvider), tab, reason: kind);
        expect(_ref.read(currentTabProvider), AppTab.library, reason: kind);
      }
    });

    testWidgets('"Lihat semua" opens the Koleksi screen', (tester) async {
      await _pump(tester, bookmarks: [_bookmark(2, 1, 2)]);
      await tester.tap(find.text('Lihat semua ›'));
      await tester.pump();
      expect(_ref.read(currentTabProvider), AppTab.library);
    });

    testWidgets('a row opens that ayah in the reader', (tester) async {
      await _pump(tester, bookmarks: [_bookmark(18, 10, 2)]);
      await tester.tap(find.text('Al-Kahf · QS 18:10'));
      await tester.pump();
      final source = _ref.read(readerSourceProvider);
      expect(source, isA<SurahSource>());
      expect((source! as SurahSource).surahId, 18);
      expect(_ref.read(targetAyahProvider), 10);
    });
  });
}
