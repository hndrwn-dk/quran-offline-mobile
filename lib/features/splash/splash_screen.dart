import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/importer.dart';
import 'package:quran_offline/core/providers/import_progress_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/widgets/nav_read_icon.dart';
import 'package:quran_offline/features/home/home_screen.dart';
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
            if (!context.mounted) return;
            final done = await LanguageSelectionScreen.hasCompletedSelection();
            if (!context.mounted) return;
            await NavReadIcon.precache(context);
            if (!context.mounted) return;
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
        await NavReadIcon.precache(context);
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

  Widget _buildSplashIcon(double size) {
    return Image.asset(
      'assets/icon/splash_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(importProgressProvider);
    final colorScheme = Theme.of(context).colorScheme;
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
                  _buildSplashIcon(120),
                  const SizedBox(height: 32),
                  Text(
                    'Quran Offline',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.getSplashTagline(splashLang),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isInitializing) ...[
                    const SizedBox(height: 48),
                    Text(
                      AppLocalizations.getSplashPleaseWait(splashLang),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: progress.progress,
                        minHeight: 2,
                        borderRadius: BorderRadius.circular(1),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primaryContainer,
                        ),
                      ),
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


