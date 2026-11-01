import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_number_badge.dart';
import 'package:quran_offline/features/read/widgets/mushaf_text_settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _languages = ['id', 'en', 'zh', 'ja'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('localization', () {
    test('page range is localized for every language', () {
      expect(AppLocalizations.formatMushafPageRange(3, 4, 'id'), 'Halaman 3–4');
      expect(AppLocalizations.formatMushafPageRange(3, 4, 'en'), 'Pages 3–4');
      expect(AppLocalizations.formatMushafPageRange(3, 4, 'zh'), '第 3–4 页');
      expect(AppLocalizations.formatMushafPageRange(3, 4, 'ja'), '3–4 ページ');
    });

    test('single page range falls back to the page label', () {
      expect(AppLocalizations.formatMushafPageRange(7, 7, 'id'), 'Halaman 7');
    });

    test('mushaf spread title includes the range', () {
      expect(
        AppLocalizations.getMushafSpreadPageText(1, 2, 'id'),
        'Mushaf - Halaman 1–2',
      );
    });

    test('two page toggle label exists in every language', () {
      final labels = {
        for (final lang in _languages)
          lang: AppLocalizations.getSettingsText('mushaf_two_page_title', lang),
      };
      expect(labels['id'], 'Tampilan dua halaman');
      expect(labels['en'], 'Two-page view');
      expect(labels['zh'], '双页显示');
      expect(labels['ja'], '2ページ表示');
      for (final label in labels.values) {
        expect(label, isNotEmpty);
        expect(label, isNot('mushaf_two_page_title'));
      }
      expect(
        AppLocalizations.getSettingsText('mushaf_two_page_subtitle', 'id'),
        contains('kamu'),
      );
    });
  });

  testWidgets('page badge shows the spread pair without a caption',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: MushafPageNumberBadge(pageNo: 3, rangeEnd: 4),
          ),
        ),
      ),
    );
    expect(find.text('3–4'), findsOneWidget);
    expect(find.textContaining('Halaman'), findsNothing);
  });

  group('two page toggle', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'language': 'id',
        'appLanguage': 'id',
      });
    });

    Future<ProviderContainer> pumpDialog(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const MushafTextSettingsDialog(),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('is visible and persists on a Fold sized window',
        (tester) async {
      final container = await pumpDialog(tester, const Size(933, 704));
      expect(find.text('Tampilan dua halaman'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.ensureVisible(find.text('Terapkan'));
      await tester.pump();
      await tester.tap(find.text('Terapkan'));
      await tester.pump();
      await tester.pump();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('mushafTwoPageSpread'), isFalse);
      expect(container.read(settingsProvider).mushafTwoPageSpread, isFalse);
    });

    testWidgets('is hidden on a narrow phone', (tester) async {
      await pumpDialog(tester, const Size(390, 844));
      expect(find.text('Tampilan dua halaman'), findsNothing);
    });

    testWidgets('defaults to on', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(settingsProvider.notifier).updateMushafTwoPageSpread(
            true,
          );
      // Fresh container to read the default.
      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final settings = fresh.read(settingsProvider);
      expect(settings.mushafTwoPageSpread, isTrue);
    });
  });
}
