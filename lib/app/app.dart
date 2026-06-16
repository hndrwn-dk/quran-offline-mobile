import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/features/splash/splash_screen.dart';

class QuranOfflineApp extends ConsumerStatefulWidget {
  const QuranOfflineApp({super.key});

  @override
  ConsumerState<QuranOfflineApp> createState() => _QuranOfflineAppState();
}

class _QuranOfflineAppState extends ConsumerState<QuranOfflineApp> {

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    final lightScheme = AppColors.lightColorScheme();
    final darkScheme = AppColors.darkColorScheme();

    return MaterialApp(
      title: 'Quran Offline',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: lightScheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warmPrimary,
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.warmPrimary),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(fontFamily: 'Roboto'),
          displayMedium: const TextStyle(fontFamily: 'Roboto'),
          displaySmall: const TextStyle(fontFamily: 'Roboto'),
          headlineLarge: const TextStyle(fontFamily: 'Roboto'),
          headlineMedium: const TextStyle(fontFamily: 'Roboto'),
          headlineSmall: const TextStyle(fontFamily: 'Roboto'),
          titleLarge: const TextStyle(fontFamily: 'Roboto'),
          titleMedium: const TextStyle(fontFamily: 'Roboto'),
          titleSmall: const TextStyle(fontFamily: 'Roboto'),
          bodyLarge: const TextStyle(fontFamily: 'Roboto'),
          bodyMedium: const TextStyle(fontFamily: 'Roboto'),
          bodySmall: const TextStyle(fontFamily: 'Roboto'),
          labelLarge: const TextStyle(fontFamily: 'Roboto'),
          labelMedium: const TextStyle(fontFamily: 'Roboto'),
          labelSmall: const TextStyle(fontFamily: 'Roboto'),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontFamily: 'Roboto'),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: darkScheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warmPrimaryLight,
            foregroundColor: const Color(0xFF1A281C),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.warmPrimaryLight),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(fontFamily: 'Roboto'),
          displayMedium: const TextStyle(fontFamily: 'Roboto'),
          displaySmall: const TextStyle(fontFamily: 'Roboto'),
          headlineLarge: const TextStyle(fontFamily: 'Roboto'),
          headlineMedium: const TextStyle(fontFamily: 'Roboto'),
          headlineSmall: const TextStyle(fontFamily: 'Roboto'),
          titleLarge: const TextStyle(fontFamily: 'Roboto'),
          titleMedium: const TextStyle(fontFamily: 'Roboto'),
          titleSmall: const TextStyle(fontFamily: 'Roboto'),
          bodyLarge: const TextStyle(fontFamily: 'Roboto'),
          bodyMedium: const TextStyle(fontFamily: 'Roboto'),
          bodySmall: const TextStyle(fontFamily: 'Roboto'),
          labelLarge: const TextStyle(fontFamily: 'Roboto'),
          labelMedium: const TextStyle(fontFamily: 'Roboto'),
          labelSmall: const TextStyle(fontFamily: 'Roboto'),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontFamily: 'Roboto'),
          ),
        ),
      ),
      themeMode: settings.themeMode,
      // Always start with SplashScreen (Import/Loading screen)
      // It will handle navigation to HomeScreen when ready
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

