import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/importer.dart';
import 'package:quran_offline/core/providers/import_progress_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/features/home/home_screen.dart';
import 'package:quran_offline/core/utils/coachmark_prefs.dart';
import 'package:quran_offline/features/onboarding/language_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await CoachmarkPrefs.incrementAppOpenCount();
      final prefs = await SharedPreferences.getInstance();
      final lastMushafPage = MushafWarmup.readLastMushafPageFromPrefs(prefs);
      unawaited(MushafWarmup.beginSession(priorityPage: lastMushafPage));

      // Check if data is already imported before showing progress bar
      final importedVersion = prefs.getString('quran_data_version');
      final isAlreadyImported = importedVersion == DataImporter.currentVersion;
      
      final db = ref.read(databaseProvider);
      final importer = DataImporter(
        db,
        onProgress: (progress) {
          // Only show progress if data is not already imported
          if (mounted && !isAlreadyImported) {
            ref.read(importProgressProvider.notifier).state = progress;
          }
        },
      );
      await importer.ensureDataImported();
      if (mounted) {
        // Only delay if data was just imported (first time)
        if (!isAlreadyImported) {
          // Ensure splash screen shows for at least 1 second for smooth experience
          await Future.delayed(const Duration(seconds: 1));
        }
        if (mounted) {
          ref.read(importProgressProvider.notifier).state = null;
          // First launch: show language selection; otherwise go to home (upgraders with existing appLanguage skip picker)
          if (mounted) {
            await LanguageSelectionScreen.migrateLegacyIfNeeded();
            if (!mounted) return;
            final done = await LanguageSelectionScreen.hasCompletedSelection();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => done
                    ? const HomeScreen()
                    : const LanguageSelectionScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(importProgressProvider.notifier).state = null;
        // On error still check language selection for consistency
        await LanguageSelectionScreen.migrateLegacyIfNeeded();
        if (!mounted) return;
        final done = await LanguageSelectionScreen.hasCompletedSelection();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => done
                ? const HomeScreen()
                : const LanguageSelectionScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildSplashIcon(double size, String assetPath) {
    final cachePx =
        (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: cachePx,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(importProgressProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final splashLogo = colorScheme.brightness == Brightness.dark
        ? 'assets/icon/splash_logo_cream.png'
        : 'assets/icon/splash_logo_green.png';
    final isInitializing = progress != null && !progress.isComplete;
    final splashLang = AppLocalizations.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSplashIcon(120, splashLogo),
                  const SizedBox(height: 24),
                  Text(
                    'Quran Offline',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.getSplashTagline(splashLang),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isInitializing) ...[
                    const SizedBox(height: 38),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: progress.progress,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                        backgroundColor: colorScheme.tint,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.getSplashPleaseWait(splashLang),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


