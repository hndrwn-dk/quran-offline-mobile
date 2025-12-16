import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/importer.dart';
import 'package:quran_offline/core/providers/import_progress_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/features/home/home_screen.dart';
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
  bool _isInitialized = false;

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
      // Check if data is already imported before showing progress bar
      final prefs = await SharedPreferences.getInstance();
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
          setState(() {
            _isInitialized = true;
          });
          ref.read(importProgressProvider.notifier).state = null;
          // Navigate to HomeScreen, removing SplashScreen from stack
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        ref.read(importProgressProvider.notifier).state = null;
        // Navigate to HomeScreen even on error
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                  // App icon
                  _buildSplashIcon(120),
                  const SizedBox(height: 32),
                  // App title
                  Text(
                    'Quran Offline',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Read the Quran offline by Surah, Juz, or Page with translation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Only show loading message and progress bar when actually importing
                  if (isInitializing) ...[
                    const SizedBox(height: 48),
                    Text(
                      'Please wait, getting things ready…',
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


