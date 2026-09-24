import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty home continue card changes tab when the tile is tapped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'id',
      'appLanguage': 'id',
    });
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                widgetRef = ref;
                return const LastReadCard(forHome: true);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(widgetRef.read(currentTabProvider), AppTab.home);
    await tester.tap(
      find.text(AppLocalizations.getHomeStartReadingTitle('id')),
    );
    await tester.pump();

    expect(widgetRef.read(currentTabProvider), AppTab.read);
  });

  testWidgets('home continue card body shares the same tap as the arrow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'id',
      'appLanguage': 'id',
      'last_read_position_type': 'surah',
      'last_read_position_id': 1,
      'last_read_position_ayahNo': 1,
      'last_read_position_timestamp': DateTime.now().toIso8601String(),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lastReadProgressProvider.overrideWith(
            (ref) async => const LastReadProgress(
              fraction: 0.14,
              scope: 'surah',
              current: 1,
              total: 7,
            ),
          ),
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
        ],
        child: const MaterialApp(
          home: Scaffold(body: LastReadCard(forHome: true)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final titleInk = tester.widget<InkWell>(
      find
          .ancestor(
            of: find.text('Al-Fatihah'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(titleInk.onTap, isNotNull);

    final pillInk = tester.widget<InkWell>(
      find
          .ancestor(
            of: find.text(AppLocalizations.getHomeContinuePill('id')),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(pillInk.onTap, isNotNull);
    expect(identical(titleInk.onTap, pillInk.onTap), isTrue);
  });
}
