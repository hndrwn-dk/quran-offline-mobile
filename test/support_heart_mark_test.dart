import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/features/support/support_heart_mark.dart';

void main() {
  testWidgets('app bar mark is a support icon in a primaryContainer circle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: AppColors.lightColorScheme()),
        home: const Scaffold(
          body: SupportHeartMark(circleSize: 36, iconSize: 20, dimInDark: true),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.volunteer_activism_rounded));
    expect(icon.size, 20);
    expect(icon.color, AppColors.lightColorScheme().primary);

    final decoration = _markDecoration(tester);
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, AppColors.lightColorScheme().primaryContainer);
    expect(tester.getSize(find.byType(SupportHeartMark)), const Size(36, 36));
  });

  testWidgets('dark app bar mark softens primaryContainer to 60% opacity', (
    tester,
  ) async {
    final dark = AppColors.darkColorScheme();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: dark),
        home: const Scaffold(
          body: SupportHeartMark(circleSize: 36, iconSize: 20, dimInDark: true),
        ),
      ),
    );

    expect(
      _markDecoration(tester).color,
      dark.primaryContainer.withValues(alpha: 0.6),
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.volunteer_activism_rounded)).color,
      dark.primary,
    );
  });

  testWidgets('thanks heart uses a solid 72 circle in dark mode',
      (tester) async {
    final dark = AppColors.darkColorScheme();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: dark),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: SupportThanksHeart()),
        ),
      ),
    );

    expect(_markDecoration(tester).color, dark.primaryContainer);
    expect(tester.getSize(find.byType(SupportHeartMark)), const Size(72, 72));
    expect(tester.widget<Icon>(find.byIcon(Icons.volunteer_activism_rounded)).size, 36);
  });

  testWidgets('thanks heart skips the pop when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: AppColors.lightColorScheme()),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: SupportThanksHeart()),
        ),
      ),
    );
    await tester.pump();

    expect(_scale(tester), 1);
    expect(_opacity(tester), 1);
  });

  testWidgets('thanks heart pops from 0.6 through 1.08 to 1', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: AppColors.lightColorScheme()),
        home: const Scaffold(body: SupportThanksHeart()),
      ),
    );

    expect(_scale(tester), closeTo(0.6, 0.001));
    expect(_opacity(tester), closeTo(0, 0.001));

    await tester.pump(const Duration(milliseconds: 260));
    expect(_scale(tester), greaterThan(1));

    await tester.pump(const Duration(milliseconds: 140));
    expect(_scale(tester), closeTo(1, 0.02));
    expect(_opacity(tester), closeTo(1, 0.02));
  });

  testWidgets('app bar button keeps a 48 touch target and tooltip',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: AppColors.lightColorScheme()),
        home: Scaffold(
          body:
              SupportAppBarButton(tooltip: 'Dukung aplikasi', onPressed: () {}),
        ),
      ),
    );

    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.tooltip, 'Dukung aplikasi');
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
    expect(find.byIcon(Icons.volunteer_activism_rounded), findsOneWidget);
  });
}

BoxDecoration _markDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(SupportHeartMark),
      matching: find.byType(DecoratedBox),
    ),
  );
  return box.decoration as BoxDecoration;
}

double _scale(WidgetTester tester) {
  return tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(SupportThanksHeart),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;
}

double _opacity(WidgetTester tester) {
  return tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byType(SupportThanksHeart),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;
}
