import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/app_version_provider.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/whats_new.dart';
import 'package:quran_offline/features/home/home_search_suggestions.dart';
import 'package:quran_offline/features/home/home_screen.dart';
import 'package:quran_offline/features/home/widgets/home_whats_new_card.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReflectionPick _fixturePick() {
  const text = LocalizedText(id: 'Teks', en: 'Text', zh: 'Text', ja: 'Text');
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

/// Pumps the real home with [version] as `APP_VERSION`. Prefs are set by the
/// caller; a new [ProviderScope] key reloads settings from them.
Future<void> _pumpHome(
  WidgetTester tester, {
  required String version,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        appVersionProvider.overrideWithValue(version),
        reflectionPickProvider.overrideWith((ref) async => _fixturePick()),
        homeSearchSuggestionsProvider.overrideWith(
          (ref) async => homeSearchSuggestions,
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(colorScheme: AppColors.lightColorScheme()),
        darkTheme: ThemeData(colorScheme: AppColors.darkColorScheme()),
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Map<String, Object> _onboardedPrefs({String? seen}) => {
      'language': 'id',
      'appLanguage': 'id',
      kLanguageSelectionDoneKey: true,
      if (seen != null) 'seenVersion': seen,
    };

final _cardFinder = find.byKey(const Key('home_whats_new_card'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('featureVersion', () {
    test('keeps major.minor', () {
      expect(featureVersion('1.3.1'), '1.3');
      expect(featureVersion('2.0.0'), '2.0');
      expect(featureVersion(''), '');
    });
  });

  group('whatsNewDue', () {
    test('feature update is due', () {
      expect(whatsNewDue(true, '1.2.4', '1.3.0'), isTrue);
    });
    test('fix update is not due', () {
      expect(whatsNewDue(true, '1.3.0', '1.3.1'), isFalse);
    });
    test('skipping x.y.0 still shows the feature version once', () {
      expect(whatsNewDue(true, '1.2.4', '1.3.2'), isTrue);
    });
    test('upgrader from a build without the card (nothing saved) is due', () {
      expect(whatsNewDue(true, '', '1.3.0'), isTrue);
    });
    test('not onboarded is never due', () {
      expect(whatsNewDue(false, '1.2.4', '1.3.0'), isFalse);
      expect(whatsNewDue(false, '', '1.3.0'), isFalse);
    });
    test('no APP_VERSION (debug, flutter run, tests) is never due', () {
      expect(whatsNewDue(true, '1.2.4', ''), isFalse);
      expect(whatsNewDue(true, '', ''), isFalse);
    });
  });

  testWidgets('new install: completing onboarding saves the version as seen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [appVersionProvider.overrideWithValue('1.3.0')],
    );
    addTearDown(container.dispose);
    container.read(settingsProvider);
    await tester.pump();
    expect(container.read(whatsNewDueProvider), isFalse);

    await container.read(settingsProvider.notifier).completeOnboarding('1.3.0');
    expect(container.read(settingsProvider).onboarded, isTrue);
    expect(container.read(whatsNewDueProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('seenVersion'), '1.3.0');
    // Let the reminder scheduler's timeout timer finish.
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('legacy upgrader with a language but no onboarding flag is due',
      (tester) async {
    SharedPreferences.setMockInitialValues({'appLanguage': 'id'});
    final container = ProviderContainer(
      overrides: [appVersionProvider.overrideWithValue('1.3.0')],
    );
    addTearDown(container.dispose);
    container.read(settingsProvider);
    await tester.pump();
    expect(container.read(whatsNewDueProvider), isTrue);
  });

  test('seenVersion round-trips through toJson/fromJson', () {
    final settings = AppSettings(seenVersion: '1.3.0');
    expect(AppSettings.fromJson(settings.toJson()).seenVersion, '1.3.0');
    expect(AppSettings.fromJson(const {}).seenVersion, '');
  });

  testWidgets('card shows above Lanjutkan baca, closes, stays closed',
      (tester) async {
    SharedPreferences.setMockInitialValues(_onboardedPrefs(seen: '1.2.4'));
    await _pumpHome(tester, version: '1.3.0');

    expect(_cardFinder, findsOneWidget);
    expect(find.text('Yang baru di 1.3'), findsOneWidget);
    expect(find.text(AppLocalizations.getWhatsNewNotes('id').first),
        findsOneWidget);
    expect(
      tester.getTopLeft(_cardFinder).dy,
      lessThan(tester.getTopLeft(find.byType(LastReadCard)).dy),
    );
    // Title is a heading; close target is at least 48dp.
    expect(
      tester.getSemantics(find.text('Yang baru di 1.3')),
      matchesSemantics(isHeader: true, label: 'Yang baru di 1.3'),
    );
    final close = find.byTooltip('Tutup');
    expect(close, findsOneWidget);
    final closeSize = tester.getSize(close);
    expect(closeSize.width, greaterThanOrEqualTo(48));
    expect(closeSize.height, greaterThanOrEqualTo(48));

    await tester.tap(close);
    await tester.pump();
    expect(_cardFinder, findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('seenVersion'), '1.3.0');

    // Reload (fresh providers from the saved prefs): still closed.
    await _pumpHome(tester, version: '1.3.0');
    expect(_cardFinder, findsNothing);

    // Fix release on top of that saved state: no card.
    await _pumpHome(tester, version: '1.3.1');
    expect(_cardFinder, findsNothing);
  });

  testWidgets('no card without APP_VERSION (debug/test builds)',
      (tester) async {
    SharedPreferences.setMockInitialValues(_onboardedPrefs());
    await _pumpHome(tester, version: '');
    expect(_cardFinder, findsNothing);
  });

  // Scoped to the card: other Beranda sections are out of scope here.
  for (final brightness in Brightness.values) {
    testWidgets('card has no overflow at text scale 2.0 (${brightness.name})',
        (tester) async {
      SharedPreferences.setMockInitialValues(_onboardedPrefs(seen: '1.2.4'));
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appVersionProvider.overrideWithValue('1.3.0')],
          child: MaterialApp(
            theme: ThemeData(colorScheme: AppColors.lightColorScheme()),
            darkTheme: ThemeData(colorScheme: AppColors.darkColorScheme()),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(child: HomeWhatsNewCard()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(_cardFinder, findsOneWidget);
      expect(
        Theme.of(tester.element(_cardFinder)).brightness,
        brightness,
      );
      expect(tester.takeException(), isNull);
    });
  }

  test('card keeps at most 3 notes', () {
    for (final lang in ['id', 'en', 'zh', 'ja']) {
      expect(
        AppLocalizations.getWhatsNewNotes(lang).length,
        lessThanOrEqualTo(HomeWhatsNewCard.maxNotes),
      );
    }
  });

  group('Play release notes', () {
    final dir = Directory('docs/store/whatsnew');
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('whatsnew-'))
        .toList();

    test('exist, use "- " lines and stay within 500 characters', () {
      expect(
        files.map((f) => f.uri.pathSegments.last),
        containsAll(['whatsnew-id', 'whatsnew-en-US']),
      );
      for (final file in files) {
        final text = file.readAsStringSync();
        expect(text.runes.length, lessThanOrEqualTo(500), reason: file.path);
        final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
        expect(lines, isNotEmpty, reason: file.path);
        for (final line in lines) {
          expect(line.startsWith('- '), isTrue, reason: '${file.path}: $line');
        }
      }
    });

    test('feature release: card notes equal whatsnew-id', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(r'^version:\s*([0-9.]+)', multiLine: true)
          .firstMatch(pubspec)!
          .group(1)!;
      final patch = int.parse(version.split('.')[2]);
      if (patch != 0) {
        markTestSkipped('$version is a fix release; card notes unchanged');
        return;
      }
      final idLines = File('docs/store/whatsnew/whatsnew-id')
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.substring(2).trim())
          .toList();
      expect(AppLocalizations.getWhatsNewNotes('id'), idLines);
    });
  });
}
