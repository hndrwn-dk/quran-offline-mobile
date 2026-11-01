import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/features/home/home_search_suggestions.dart';
import 'package:quran_offline/features/home/widgets/home_search_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpSection(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'language': 'id',
    'appLanguage': 'id',
  });
  final container = ProviderContainer(
    overrides: [
      homeSearchSuggestionsProvider.overrideWith(
        (ref) async => homeSearchSuggestions,
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: HomeSearchSection()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

void main() {
  testWidgets('search field is a real TextField with the localized hint', (
    tester,
  ) async {
    await _pumpSection(tester);

    final field = tester.widget<TextField>(
      find.byKey(const Key('home_search_field')),
    );
    expect(field.readOnly, isTrue);
    expect(field.decoration?.hintText, 'Apa yang sedang kamu rasakan?');
    expect(find.text('TEMUKAN DI AL-QUR\'AN'), findsOneWidget);
  });

  testWidgets('tapping the field opens Cari with focus and no query', (
    tester,
  ) async {
    final container = await _pumpSection(tester);
    expect(container.read(searchQueryProvider), '');

    await tester.tap(find.byKey(const Key('home_search_field')));
    await tester.pump();

    expect(container.read(currentTabProvider), AppTab.search);
    expect(container.read(searchFocusRequestProvider), 1);
    expect(container.read(searchQueryProvider), '');
  });

  testWidgets('every chip opens Cari with its localized query', (
    tester,
  ) async {
    final container = await _pumpSection(tester);

    expect(find.byKey(const Key('home_search_chip_sabar')), findsOneWidget);
    expect(find.byKey(const Key('home_search_chip_syukur')), findsOneWidget);
    expect(find.byKey(const Key('home_search_chip_rezeki')), findsOneWidget);
    expect(find.byKey(const Key('home_search_chip_orangtua')), findsOneWidget);

    for (final suggestion in homeSearchSuggestions) {
      container.read(currentTabProvider.notifier).state = AppTab.home;
      await tester.tap(
        find.byKey(Key('home_search_chip_${suggestion.tag}')),
      );
      await tester.pump();

      expect(container.read(currentTabProvider), AppTab.search);
      expect(
        container.read(searchQueryProvider),
        suggestion.query('id'),
      );
    }
  });

  testWidgets('submitting text passes the query to Cari', (tester) async {
    final container = await _pumpSection(tester);

    final field = tester.widget<TextField>(
      find.byKey(const Key('home_search_field')),
    );
    field.onSubmitted?.call('  ampun  ');
    await tester.pump();

    expect(container.read(searchQueryProvider), 'ampun');
    expect(container.read(currentTabProvider), AppTab.search);
    expect(container.read(searchFocusRequestProvider), 1);
  });

  testWidgets('suggestion chips keep a 44px tap target', (tester) async {
    await _pumpSection(tester);

    for (final suggestion in homeSearchSuggestions) {
      final size = tester.getSize(
        find.byKey(Key('home_search_chip_${suggestion.tag}')),
      );
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });
}
