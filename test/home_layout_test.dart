import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/features/home/home_search_suggestions.dart';
import 'package:quran_offline/features/home/home_screen.dart';
import 'package:quran_offline/features/home/widgets/home_collection_section.dart';
import 'package:quran_offline/features/home/widgets/home_hero_card.dart';
import 'package:quran_offline/features/home/widgets/home_search_section.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:quran_offline/features/read/widgets/weekly_reflection_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReflectionPick _fixturePick() {
  const text = LocalizedText(
    id: 'Teks',
    en: 'Text',
    zh: 'Text',
    ja: 'Text',
  );
  return const ReflectionPick(
    entry: ReflectionLensEntry(
      id: 'jumat_kahf',
      sort: 0,
      priority: 50,
      badgeKey: 'friday',
      title: text,
      summary: text,
      reflection: text,
      ayahRefs: [DuaAyahRef(surah: 18, from: 1, to: 10)],
      trigger: ReflectionTrigger(type: 'weekday', weekday: 5),
    ),
    source: ReflectionPickSource.calendar,
  );
}

Future<void> _pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'language': 'id',
    'appLanguage': 'id',
  });
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reflectionPickProvider.overrideWith((ref) async => _fixturePick()),
        homeSearchSuggestionsProvider.overrideWith(
          (ref) async => homeSearchSuggestions,
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('home no longer renders the quick access section', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.textContaining('AKSES CEPAT'), findsNothing);
    expect(find.textContaining('QUICK ACCESS'), findsNothing);
  });

  testWidgets('home sections render in the requested order', (tester) async {
    await _pumpHome(tester);

    for (final finder in [
      find.byType(HomeHeroCard),
      find.byType(LastReadCard),
      find.byType(HomeSearchSection),
      find.byType(WeeklyReflectionCard),
      find.byType(HomeCollectionSection),
    ]) {
      expect(finder, findsOneWidget);
    }

    // The phone body is the closest Column above the hero card; its children
    // are the home sections in display order.
    final bodyColumn = tester.widget<Column>(
      find
          .ancestor(
            of: find.byType(HomeHeroCard),
            matching: find.byType(Column),
          )
          .first,
    );
    expect(
      bodyColumn.children.map((child) => child.runtimeType).toList(),
      [
        HomeHeroCard,
        LastReadCard,
        HomeSearchSection,
        WeeklyReflectionCard,
        HomeCollectionSection,
        SizedBox,
      ],
    );
  });

  testWidgets('inline search sits directly below the continue card', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byKey(const Key('home_search_field')), findsOneWidget);
    expect(find.byKey(const Key('home_search_chip_sabar')), findsOneWidget);
    expect(find.byType(LastReadCard), findsOneWidget);
  });
}
