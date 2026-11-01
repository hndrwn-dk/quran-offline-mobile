import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/widgets/mushaf_text_settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _languages = ['id', 'en', 'zh', 'ja'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('page turn setting', () {
    test('defaults to curl', () {
      expect(AppSettings().mushafPageTurn, MushafPageTurn.curl);
    });

    test('json round trip keeps the mode', () {
      for (final mode in MushafPageTurn.values) {
        final settings = AppSettings().copyWith(mushafPageTurn: mode);
        final restored = AppSettings.fromJson(settings.toJson());
        expect(restored.mushafPageTurn, mode);
        expect(settings.toJson()['mushafPageTurn'], mode.name);
      }
      // Unknown values fall back to curl instead of crashing.
      final restored = AppSettings.fromJson({'mushafPageTurn': 'nope'});
      expect(restored.mushafPageTurn, MushafPageTurn.curl);
    });

    test('labels exist and are translated in every language', () {
      final labels = {
        for (final lang in _languages)
          lang: [
            AppLocalizations.getSettingsText('page_turn_title', lang),
            AppLocalizations.getSettingsText('page_turn_subtitle', lang),
            AppLocalizations.getSettingsText('page_turn_curl', lang),
            AppLocalizations.getSettingsText('page_turn_slide', lang),
            AppLocalizations.getSettingsText('page_turn_none', lang),
          ],
      };
      for (final entry in labels.entries) {
        for (final label in entry.value) {
          expect(label, isNotEmpty);
          expect(label, isNot('page_turn_title'));
          expect(label, isNot(contains('?')));
        }
      }
      expect(labels['id']![0], 'Animasi balik halaman');
      expect(labels['id']![2], 'Lembar');
      expect(labels['id']![4], 'Tanpa');
      expect(labels['en']![0], 'Page turn animation');
      expect(labels['zh']![0], '翻页动画');
      expect(labels['zh']![4], '无');
      expect(labels['ja']![0], 'ページめくりアニメーション');
      expect(labels['ja']![4], 'なし');
      // Distinct labels for the three choices.
      for (final entry in labels.entries) {
        expect(entry.value.sublist(2).toSet().length, 3);
      }
    });

    testWidgets('dialog exposes the three modes and applies the choice',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'language': 'id',
        'appLanguage': 'id',
      });
      tester.view.physicalSize = const Size(933, 704);
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

      expect(find.text('Animasi balik halaman'), findsOneWidget);
      expect(find.byKey(const Key('mushaf-page-turn')), findsOneWidget);
      expect(find.text('Lembar'), findsOneWidget);
      expect(find.text('Geser'), findsOneWidget);
      expect(find.text('Tanpa'), findsOneWidget);

      await tester.tap(find.text('Tanpa'));
      await tester.pump();
      await tester.ensureVisible(find.text('Terapkan'));
      await tester.pump();
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mushafPageTurn'), 'none');
      expect(
          container.read(settingsProvider).mushafPageTurn, MushafPageTurn.none);
    });
  });
}
