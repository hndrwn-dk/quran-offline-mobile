import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/juz_surahs_provider.dart';
import 'package:quran_offline/core/providers/page_surahs_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/features/read/juz_list_view.dart';
import 'package:quran_offline/features/read/read_screen.dart';
import 'package:quran_offline/features/read/surah_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Baca keeps Surah and Juz lists mounted when switching modes', (
    tester,
  ) async {
    late WidgetRef containerRef;

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
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              containerRef = ref;
              return const ReadScreen();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(SurahListView, skipOffstage: false), findsOneWidget);
    expect(find.byType(JuzListView, skipOffstage: false), findsOneWidget);

    containerRef.read(readModeProvider.notifier).state = ReadMode.juz;
    await tester.pump();

    expect(find.byType(SurahListView, skipOffstage: false), findsOneWidget);
    expect(find.byType(JuzListView, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
