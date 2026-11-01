import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/juz_surahs_provider.dart';
import 'package:quran_offline/core/providers/page_surahs_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/read/read_screen.dart';
import 'package:quran_offline/features/read/widgets/quick_search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Read (Baca) screen must offer quick search at every window width:
/// phones, the Fold inner screen (704 / 933dp) and the >= 840dp split layout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpRead(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahNamesProvider.overrideWith(
            (ref) async => [
              SurahInfo(
                id: 1,
                arabicName: '',
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
        ],
        child: const MaterialApp(home: ReadScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  for (final size in const [
    Size(390, 844), // phone portrait
    Size(844, 390), // phone landscape (>= 840: split layout)
    Size(704, 933), // Fold inner portrait
    Size(933, 704), // Fold inner landscape (split layout)
    Size(800, 1280), // tablet portrait
    Size(1280, 800), // tablet landscape (split layout)
  ]) {
    testWidgets('search is visible and opens at $size', (tester) async {
      await pumpRead(tester, size);

      final button = find.widgetWithIcon(IconButton, Icons.search);
      expect(button, findsOneWidget);
      expect(find.byType(QuickSearchBar), findsOneWidget);
      expect(find.byType(AppSearchField), findsNothing);

      await tester.tap(button);
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppSearchField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
