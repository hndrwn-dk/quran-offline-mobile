import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quran_offline/app/app.dart';
import 'package:quran_offline/core/widgets/nav_read_icon.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/reader/ayah_card.dart';

import 'helpers/bootstrap.dart';

/// Emulator/device regression tests for core QA flows (complements `flutter test` unit tests).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await seedIntegrationTestPreferences();
  });

  group('QA regression (ID locale)', () {
    testWidgets('core flows on emulator', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: QuranOfflineApp(),
        ),
      );
      await tester.pump();
      await _waitForHome(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text("Qur'an"), findsOneWidget);
      expect(find.byType(NavReadIcon), findsWidgets);

      expect(find.textContaining('ayat'), findsWidgets);

      await tester.tap(find.byKey(const Key('nav_settings')));
      await tester.pumpAndSettle();
      expect(find.text('Bahasa'), findsWidgets);
      expect(find.text('Bahasa Aplikasi'), findsNothing);
      expect(find.text('Bahasa Terjemahan'), findsNothing);

      await tester.tap(find.byKey(const Key('nav_read')));
      await tester.pumpAndSettle();
      await _pumpUntilFound(
        tester,
        find.text('Al-Fatihah'),
        timeout: const Duration(seconds: 30),
      );

      await tester.tap(find.byKey(const Key('nav_search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('search_field')), '2');
      await tester.pump(const Duration(milliseconds: 400));
      await _pumpUntilFound(
        tester,
        find.text(SurahNameGlyph.ligatureFor(2)),
        timeout: const Duration(seconds: 10),
      );
      expect(find.byType(SurahNameSearchGlyph), findsWidgets);
      expect(find.text(SurahNameGlyph.ligatureFor(2)), findsWidgets);

      await tester.tap(find.byKey(const Key('nav_search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('search_field')), 'fatihah');
      await tester.pump(const Duration(milliseconds: 500));
      await _pumpUntilFound(
        tester,
        find.text(SurahNameGlyph.ligatureFor(1)),
        timeout: const Duration(seconds: 15),
      );
      final surahResult = find.ancestor(
        of: find.text(SurahNameGlyph.ligatureFor(1)).first,
        matching: find.byType(ListTile),
      );
      await tester.tap(surahResult);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await _pumpUntilFound(
        tester,
        find.byType(BackButton),
        timeout: const Duration(seconds: 20),
      );
      await _pumpUntilFound(
        tester,
        find.byType(AyahCard),
        timeout: const Duration(seconds: 45),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('surah_header_card')),
        timeout: const Duration(seconds: 45),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('surah_header_about_surah')),
        timeout: const Duration(seconds: 45),
      );

      expect(find.text(SurahNameGlyph.ligatureFor(1)), findsWidgets);
      expect(find.byKey(const Key('surah_header_about_surah')), findsWidgets);
    });
  });
}

Future<void> _waitForHome(
  WidgetTester tester, {
  Duration timeout = const Duration(minutes: 4),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 400));

    if (find.text('Bahasa Indonesia').evaluate().isNotEmpty) {
      await tester.tap(find.text('Bahasa Indonesia'));
      await tester.pumpAndSettle();
      continue;
    }

    if (find.byType(NavigationBar).evaluate().isNotEmpty) {
      await tester.pumpAndSettle(const Duration(seconds: 2));
      return;
    }
  }

  fail('Timed out waiting for home screen (NavigationBar)');
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (finder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Timed out waiting for $finder');
}
