import 'package:flutter/material.dart';
import 'package:quran_offline/core/constants/app_colors.dart';

/// App-wide Material theme. Colors come from [AppColors]; nothing here is
/// screen specific.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Roboto';

  /// Corner radius for cards and grouped lists.
  static const double cardRadius = 22;

  /// Corner radius for the top of bottom sheets and for dialogs.
  static const double sheetRadius = 28;

  static ThemeData light() => _build(AppColors.lightColorScheme());

  static ThemeData dark() => _build(AppColors.darkColorScheme());

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
    );
    final isDark = scheme.brightness == Brightness.dark;
    final filledBackground =
        isDark ? AppColors.warmPrimaryLight : AppColors.warmPrimary;
    final filledForeground = isDark ? AppColors.onPrimaryDark : Colors.white;

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: filledBackground,
          foregroundColor: filledForeground,
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: filledBackground),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontFamily: fontFamily),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.canvas,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sheetRadius),
        ),
      ),
    );
  }

  /// Material 3 sizes, with heavier and tighter titles. Body sizes are left
  /// alone so reading text does not move.
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }
}

/// Semantic surfaces on top of [ColorScheme].
extension AppSurfaces on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  /// Background of tab roots, settings pages and sheets. Cards sit on it.
  Color get canvas => _isDark ? surface : surfaceContainer;

  /// Fill of cards and grouped lists on [canvas].
  Color get card => _isDark ? surfaceContainer : surfaceContainerLowest;

  /// Soft fill for badges, tonal buttons and the selected tab.
  Color get tint => _isDark ? surfaceContainerHigh : surfaceContainerHighest;

  /// Text and icons on [tint]. Primary is too dim on the dark tint.
  Color get onTint => _isDark ? onPrimaryContainer : primary;

  /// 1px separator inside cards.
  Color get hairline => onSurface.withValues(alpha: _isDark ? 0.14 : 0.10);
}
