import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/features/home/home_screen.dart';

void main() {
  testWidgets(
    'home scaffold does not overflow search when keyboard is open',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      // ~300 logical px keyboard + 14 logical px system bottom inset.
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      tester.view.viewPadding = const FakeViewPadding(bottom: 42);
      tester.view.padding = const FakeViewPadding(bottom: 42);
      addTearDown(tester.view.reset);

      FlutterError? overflow;
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          overflow = FlutterError(details.exceptionAsString());
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTabProvider.overrideWith((ref) => AppTab.search),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      expect(overflow, isNull, reason: overflow?.message);
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets(
    'explore hub does not overflow when keyboard is open',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      tester.view.viewPadding = const FakeViewPadding(bottom: 42);
      tester.view.padding = const FakeViewPadding(bottom: 42);
      addTearDown(tester.view.reset);

      FlutterError? overflow;
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          overflow = FlutterError(details.exceptionAsString());
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTabProvider.overrideWith((ref) => AppTab.explore),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      expect(overflow, isNull, reason: overflow?.message);
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('home bottom nav is visible when keyboard is closed', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTabProvider.overrideWith((ref) => AppTab.search),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search tab shows bottom nav when the field is unfocused',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTabProvider.overrideWith((ref) => AppTab.search),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      final field = tester.widget<TextField>(find.byKey(const Key('search_field')));
      expect(field.focusNode?.hasFocus, isFalse);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(const Key('nav_search')), findsOneWidget);
    },
  );

  testWidgets(
    'search tab keeps bottom nav when a system-nav inset is present',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 48);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTabProvider.overrideWith((ref) => AppTab.search),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );
}
