import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/providers/asma_catalog_provider.dart';
import 'package:quran_offline/core/providers/dua_catalog_provider.dart';
import 'package:quran_offline/core/providers/enhanced_search_provider.dart';
import 'package:quran_offline/core/providers/quran_dua_ayat_catalog_provider.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';
import 'package:quran_offline/core/providers/search_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/providers/theme_catalog_provider.dart';
import 'package:quran_offline/features/dua/dua_screen.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/search/search_screen.dart';
import 'package:quran_offline/features/search/widgets/search_result_list.dart';
import 'package:quran_offline/features/settings/audio_downloads_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

ColorScheme get _darkScheme => ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.dark,
    );

void _expectPinnedOverlay(WidgetTester tester, ColorScheme scheme) {
  final bar = tester.widget<AppBar>(find.byType(AppBar).first);
  final expected = HomeBackdrop.overlayStyle(scheme);
  expect(
    bar.systemOverlayStyle?.statusBarIconBrightness,
    expected.statusBarIconBrightness,
  );
  expect(
    bar.systemOverlayStyle?.statusBarBrightness,
    expected.statusBarBrightness,
  );
  expect(bar.systemOverlayStyle?.statusBarColor, isNull);
  expect(bar.systemOverlayStyle?.systemNavigationBarColor, isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Jelajahi hub AppBar pins overlayStyle and corner arc', (
    tester,
  ) async {
    final scheme = _darkScheme;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          duaCatalogProvider.overrideWith(
            (ref) async => const DuaCatalog(version: 1, entries: []),
          ),
          asmaCatalogProvider.overrideWith(
            (ref) async => const AsmaCatalog(version: 1, entries: []),
          ),
          scienceCatalogProvider.overrideWith(
            (ref) async => const ScienceCatalog(version: 1, entries: []),
          ),
          themeCatalogProvider.overrideWith(
            (ref) async => const ThemeCatalog(version: 1, entries: []),
          ),
          quranDuaAyatCatalogProvider.overrideWith(
            (ref) async => const QuranDuaAyatCatalog(version: 1, entries: []),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          home: const DuaScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    _expectPinnedOverlay(tester, scheme);
    expect(find.byKey(const Key('home_corner_arc_bar')), findsOneWidget);
  });

  testWidgets('Cari AppBar pins HomeBackdrop overlayStyle', (tester) async {
    final scheme = _darkScheme;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiSearchEnabledProvider.overrideWith((ref) => false),
          searchQueryProvider.overrideWith((ref) => ''),
          enhancedSearchResultsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    _expectPinnedOverlay(tester, scheme);
  });

  testWidgets('translation results AppBar pins HomeBackdrop overlayStyle', (
    tester,
  ) async {
    final scheme = _darkScheme;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          home: const TranslationResultsScreen(results: [], query: 'sabar'),
        ),
      ),
    );
    await tester.pump();
    _expectPinnedOverlay(tester, scheme);
  });

  testWidgets('audio downloads AppBar pins HomeBackdrop overlayStyle', (
    tester,
  ) async {
    final scheme = _darkScheme;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahNamesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          home: const AudioDownloadsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    _expectPinnedOverlay(tester, scheme);
  });
}
