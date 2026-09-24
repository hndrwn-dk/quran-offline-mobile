import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';

void main() {
  group('HomeBackdrop.overlayStyle', () {
    test('does not set bar colours deprecated by Android 15 edge-to-edge', () {
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: brightness,
        );
        final style = HomeBackdrop.overlayStyle(scheme);

        expect(style.statusBarColor, isNull);
        expect(style.systemNavigationBarColor, isNull);
        expect(style.systemNavigationBarDividerColor, isNull);
      }
    });

    test('keeps icon contrast so bars stay legible over the backdrop', () {
      final light = HomeBackdrop.overlayStyle(
        ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      );
      expect(light.statusBarIconBrightness, Brightness.dark);
      expect(light.statusBarBrightness, Brightness.light);

      final dark = HomeBackdrop.overlayStyle(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
      );
      expect(dark.statusBarIconBrightness, Brightness.light);
      expect(dark.statusBarBrightness, Brightness.dark);
    });
  });

  test('dark topTint is opaque so pushed Jelajahi routes do not flash', () {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.dark,
    );
    final tint = HomeBackdrop.topTint(scheme);

    expect(tint.a, 1.0);
    expect(tint, isNot(scheme.surface));
  });

  test('light topTint stays an opaque cream wash', () {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32));
    expect(HomeBackdrop.topTint(scheme).a, 1.0);
  });

  testWidgets('paints a header-only right-corner arc, not over the body', (
    tester,
  ) async {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF5A7358));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            flexibleSpace: HomeBackdrop.cornerArcFlexibleSpace(scheme),
          ),
          body: const HomeBackdrop(child: SizedBox.expand()),
        ),
      ),
    );

    expect(find.byKey(const Key('home_corner_arc_bar')), findsOneWidget);
    expect(find.byKey(const Key('home_corner_arc')), findsNothing);
  });
}
