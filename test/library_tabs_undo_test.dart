import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/highlights/highlights_screen.dart';
import 'package:quran_offline/features/library/my_library_screen.dart';
import 'package:quran_offline/features/notes/widgets/notes_tab_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

SurahInfo _surah(int id, String name) {
  return SurahInfo(
    id: id,
    arabicName: '',
    englishName: name,
    englishMeaning: '',
  );
}

Future<AppDatabase> _db() async {
  return AppDatabase.forTest(NativeDatabase.memory());
}

Future<void> _pump(
  WidgetTester tester,
  AppDatabase db,
  Widget home,
) async {
  SharedPreferences.setMockInitialValues({
    'appLanguage': 'id',
    'language': 'id',
    'weeklyReminderEnabled': false,
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        surahNamesProvider.overrideWith(
          (ref) async => [
            _surah(112, 'Al-Ikhlas'),
            _surah(2, 'Al-Baqarah'),
            _surah(67, 'Al-Mulk'),
          ],
        ),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _swipeUndo(WidgetTester tester, String removed, String stillVisible) async {
  await tester.drag(find.byType(Dismissible), const Offset(-800, 0));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  expect(find.text(removed), findsOneWidget);
  expect(find.text(stillVisible), findsNothing);

  await tester.tap(find.text(AppLocalizations.libraryUndo('id')));
  await tester.pumpAndSettle();
  expect(find.text(stillVisible), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('swipe undo restores a bookmark and its count', (tester) async {
    final db = await _db();
    addTearDown(db.close);
    await db.restoreBookmark(
      Bookmark(
        surahId: 112,
        ayahNo: 3,
        createdAt: DateTime.utc(2024, 1, 1),
        openContext: 'surah',
      ),
    );

    await _pump(tester, db, const MyLibraryScreen());

    expect(find.byKey(const Key('library-count-0')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('library-count-0'))).data, '1');
    expect(find.text('Al-Ikhlas'), findsOneWidget);
    expect(find.textContaining('Ayat 3'), findsOneWidget);
    expect(find.textContaining('QS 112:3'), findsNothing);

    final count = find.byKey(const Key('library-count-0'));
    final tile = tester.widget<Material>(
      find.ancestor(of: count, matching: find.byType(Material)).first,
    );
    final scheme = Theme.of(tester.element(count)).colorScheme;
    expect(tile.color, scheme.primaryContainer.withValues(alpha: 0.45));
    final side = (tile.shape! as RoundedRectangleBorder).side;
    expect(side.color, scheme.primary);
    expect(side.width, 1.5);
    expect(tester.widget<Text>(count).style?.color, scheme.primary);

    await _swipeUndo(tester, AppLocalizations.libraryDeleted('bookmark', 'id'), 'Al-Ikhlas');
    expect(tester.widget<Text>(find.byKey(const Key('library-count-0'))).data, '1');
    final restored = await db.getBookmark(112, 3);
    expect(restored?.createdAt.isAtSameMomentAs(DateTime.utc(2024, 1, 1)), isTrue);
  });

  testWidgets('swipe undo restores a note', (tester) async {
    final db = await _db();
    addTearDown(db.close);
    final created = DateTime.utc(2021, 1, 2);
    final updated = DateTime.utc(2021, 6, 7);
    await db.restoreNote(
      Note(
        surahId: 2,
        ayahNo: 286,
        note: 'beban ini sudah dikur.',
        createdAt: created,
        updatedAt: updated,
      ),
    );

    await _pump(tester, db, const Scaffold(body: NotesTabContent()));
    expect(find.text('Al-Baqarah · QS 2:286'), findsOneWidget);

    await _swipeUndo(tester, AppLocalizations.libraryDeleted('note', 'id'), 'Al-Baqarah · QS 2:286');
    final restored = await db.getNote(2, 286);
    expect(restored?.note, 'beban ini sudah dikur.');
    expect(restored?.createdAt.isAtSameMomentAs(created), isTrue);
    expect(restored?.updatedAt.isAtSameMomentAs(updated), isTrue);
  });

  testWidgets('swipe undo restores a highlight', (tester) async {
    final db = await _db();
    addTearDown(db.close);
    final created = DateTime.utc(2022, 8, 9);
    await db.restoreHighlight(
      Highlight(
        surahId: 67,
        ayahNo: 1,
        color: 0xFFC4920A,
        createdAt: created,
      ),
    );

    await _pump(tester, db, const Scaffold(body: HighlightsScreen()));
    expect(find.text('Al-Mulk · QS 67:1'), findsOneWidget);

    await _swipeUndo(
      tester,
      AppLocalizations.libraryDeleted('highlight', 'id'),
      'Al-Mulk · QS 67:1',
    );
    final restored = await db.getHighlight(67, 1);
    expect(restored?.color, 0xFFC4920A);
    expect(restored?.createdAt.isAtSameMomentAs(created), isTrue);
  });

  testWidgets('empty search offers the same query in Quran search', (tester) async {
    final db = await _db();
    addTearDown(db.close);
    await db.restoreBookmark(
      Bookmark(
        surahId: 112,
        ayahNo: 3,
        createdAt: DateTime.utc(2024, 1, 1),
        openContext: 'surah',
      ),
    );
    await _pump(tester, db, const MyLibraryScreen());

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizations.librarySearchEmpty('zzzz', 'id')),
      findsOneWidget,
    );
    await tester.tap(find.text(AppLocalizations.librarySearchInQuran('id')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(MyLibraryScreen));
    final container = ProviderScope.containerOf(context);
    expect(container.read(currentTabProvider), AppTab.search);
    expect(container.read(searchQueryProvider), 'zzzz');
  });

  testWidgets('library header shows the collection badge and subtitle', (
    tester,
  ) async {
    final db = await _db();
    addTearDown(db.close);
    await _pump(tester, db, const MyLibraryScreen());

    expect(
      find.text('Ayat yang kamu simpan dan renungkan'),
      findsOneWidget,
    );
    expect(
      AppLocalizations.getSubtitleText('library_subtitle', 'en'),
      "Verses you've saved and reflected on",
    );
    expect(
      AppLocalizations.getSubtitleText('library_subtitle', 'zh'),
      '你收藏和沉思的经文',
    );
    expect(
      AppLocalizations.getSubtitleText('library_subtitle', 'ja'),
      '保存して思いを巡らせた節',
    );

    final icon = find.byIcon(Icons.collections_bookmark);
    expect(icon, findsOneWidget);
    final badge = find.ancestor(
      of: icon,
      matching: find.byType(Container),
    );
    expect(tester.getSize(badge.first), const Size(44, 44));
    final scheme = Theme.of(tester.element(icon)).colorScheme;
    expect(tester.widget<Icon>(icon).color, scheme.primary);
    final decoration =
        tester.widget<Container>(badge.first).decoration! as BoxDecoration;
    expect(
      decoration.color,
      scheme.primaryContainer.withValues(alpha: 0.45),
    );
    expect(decoration.shape, BoxShape.circle);
  });
}
