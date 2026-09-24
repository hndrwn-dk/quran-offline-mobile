import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/features/home/home_screen.dart';
import 'package:quran_offline/features/search/widgets/tanya_search_results.dart';
import 'package:shared_preferences/shared_preferences.dart';

AiSearchHit _hit(String type, int i) {
  return AiSearchHit(
    docId: '$type-$i',
    type: type,
    lang: 'id',
    refKey: '$type-$i',
    surah: 2,
    ayahFrom: i + 1,
    ayahTo: i + 1,
    score: 1.0 - i * 0.01,
  );
}

AiSearchTypeGroup _group(String type, int n) {
  return AiSearchTypeGroup(
    type: type,
    hits: [for (var i = 0; i < n; i++) _hit(type, i)],
  );
}

Widget _card(AiSearchHit hit, String lang) {
  return SizedBox(
    height: 88,
    child: Text(hit.docId, key: Key('card_${hit.docId}')),
  );
}

ScrollableState _resultsScrollable(WidgetTester tester) {
  return tester.state<ScrollableState>(
    find.descendant(
      of: find.byType(TanyaSearchResults),
      matching: find.byType(Scrollable),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'closing the keyboard shrinks scroll extent and first result is reachable',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 360);
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      tester.view.padding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTabProvider.overrideWith((ref) => AppTab.search),
            aiSearchEnabledProvider.overrideWith((ref) => true),
            tanyaCardBuilderProvider.overrideWith((ref) => _card),
            searchQueryProvider.overrideWith((ref) => 'sabar'),
            enhancedSearchResultsProvider.overrideWith((ref) async => []),
            aiSearchResultsProvider.overrideWith(
              (ref) async => AiSearchResults(
                groups: [
                  _group('ayah', 8),
                  _group('tafsir', 8),
                  _group('dua', 8),
                  _group('asma', 8),
                ],
              ),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(TanyaSearchResults), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      final withKeyboard = _resultsScrollable(tester).position;
      expect(withKeyboard.maxScrollExtent, greaterThan(0));
      await tester.drag(
        find.byType(TanyaSearchResults),
        Offset(0, -(withKeyboard.maxScrollExtent + 80)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final extentWhileOpen =
          _resultsScrollable(tester).position.maxScrollExtent;
      expect(extentWhileOpen, greaterThan(0));

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final afterClose = _resultsScrollable(tester).position;
      expect(
        afterClose.maxScrollExtent,
        lessThan(extentWhileOpen),
        reason: 'viewport must grow back when the inset is gone',
      );
      expect(
        afterClose.pixels,
        lessThanOrEqualTo(afterClose.maxScrollExtent + 0.5),
        reason: 'offset must clamp; no dead space below the last card',
      );

      await tester.drag(
        find.byType(TanyaSearchResults),
        Offset(0, afterClose.maxScrollExtent + 240),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('card_ayah-0')), findsOneWidget);
      final first = tester.getRect(find.byKey(const Key('card_ayah-0')));
      expect(first.top, greaterThanOrEqualTo(0));
      expect(first.bottom, lessThanOrEqualTo(800));
      expect(_resultsScrollable(tester).position.pixels, lessThan(1));
    },
  );
}
