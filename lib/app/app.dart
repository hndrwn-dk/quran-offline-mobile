import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/support_provider.dart';
import 'package:quran_offline/features/splash/splash_screen.dart';

class QuranOfflineApp extends ConsumerStatefulWidget {
  const QuranOfflineApp({super.key});

  @override
  ConsumerState<QuranOfflineApp> createState() => _QuranOfflineAppState();
}

class _QuranOfflineAppState extends ConsumerState<QuranOfflineApp> {
  @override
  void initState() {
    super.initState();
    ref.read(supportPurchaseProvider).start();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Quran Offline',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      // Always start with SplashScreen (Import/Loading screen)
      // It will handle navigation to HomeScreen when ready
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

