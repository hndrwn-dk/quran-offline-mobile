import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/core/providers/app_version_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';
import 'package:quran_offline/features/home/home_screen.dart';

String _splashLogoAsset(bool isDark) => isDark
    ? 'assets/icon/splash_logo_cream.png'
    : 'assets/icon/splash_logo_green.png';

const String _prefKeyLanguageDone = kLanguageSelectionDoneKey;

const List<_Option> _languageOptions = [
  _Option(lang: 'id', label: 'Bahasa Indonesia', code: 'ID', subtitle: 'Indonesian'),
  _Option(lang: 'en', label: 'English', code: 'EN', subtitle: 'International'),
  _Option(lang: 'zh', label: '中文', code: 'ZH', subtitle: 'Chinese'),
  _Option(lang: 'ja', label: '日本語', code: 'JA', subtitle: 'Japanese'),
];

Future<bool> _hasCompletedLanguageSelection() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_prefKeyLanguageDone) ?? false;
}

/// For users upgrading: if they already had app language set, mark selection done so they don't see the picker.
Future<void> _migrateLegacyIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool(_prefKeyLanguageDone);
  if (done == true) return;
  final hasAppLanguage = prefs.getString('appLanguage') != null;
  if (hasAppLanguage) await prefs.setBool(_prefKeyLanguageDone, true);
}

Future<void> _onLanguageSelected(
  BuildContext context,
  WidgetRef ref,
  String lang,
) async {
  await ref.read(settingsProvider.notifier).updateLocale(lang);
  // Marks setup done and saves the current version as seen, so a new
  // install never shows the What's new card.
  await ref
      .read(settingsProvider.notifier)
      .completeOnboarding(ref.read(appVersionProvider));
  if (context.mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

/// Shown on first launch. User picks one language; it sets both app UI and translation language.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  static Future<bool> hasCompletedSelection() => _hasCompletedLanguageSelection();

  /// Call before hasCompletedSelection so upgraders with existing appLanguage skip the picker.
  static Future<void> migrateLegacyIfNeeded() => _migrateLegacyIfNeeded();

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _heroFade;
  late final List<Animation<double>> _cardSlides;
  late final List<Animation<double>> _cardFades;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _heroFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
    );

    _cardSlides = List.generate(_languageOptions.length, (index) {
      final start = 0.18 + index * 0.1;
      final end = (start + 0.42).clamp(0.0, 1.0);
      return Tween<double>(begin: 28, end: 0).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _cardFades = List.generate(_languageOptions.length, (index) {
      final start = 0.18 + index * 0.1;
      final end = (start + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _entranceController.forward();
    MushafWarmup.beginSession();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final hintLang = AppLocalizations.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      backgroundColor: colorScheme.canvas,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeTransition(
                          opacity: _heroFade,
                          child: Column(
                            children: [
                              _buildLogo(colorScheme, isDark),
                              const SizedBox(height: 20),
                              Text(
                                'Quran Offline'.toUpperCase(),
                                style: textTheme.labelMedium?.copyWith(
                                  letterSpacing: 0.7,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onTint,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppLocalizations.getOnboardingWelcome(hintLang),
                                style: textTheme.headlineLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.getOnboardingLanguageHeadline(
                                  hintLang,
                                ),
                                style: textTheme.bodyLarge?.copyWith(
                                  fontSize: 15,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.getOnboardingMultilingualLine(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.2,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedBuilder(
                          animation: _entranceController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _cardSlides.first.value),
                              child: Opacity(
                                opacity: _cardFades.first.value,
                                child: child,
                              ),
                            );
                          },
                          child: AppGroupedCard(
                            children: [
                              for (final opt in _languageOptions)
                                _LanguageTile(
                                  option: opt,
                                  onTap: () => _onLanguageSelected(
                                    context,
                                    ref,
                                    opt.lang,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _heroFade,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              AppLocalizations.getOnboardingSettingsHint(
                                hintLang,
                              ),
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme, bool isDark) {
    const size = 104.0;
    return Image.asset(
      _splashLogoAsset(isDark),
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      errorBuilder: (_, __, ___) => Icon(
        Icons.menu_book_rounded,
        size: 48,
        color: colorScheme.primary,
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.option, required this.onTap});

  final _Option option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              AppBadge(label: option.code, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.tint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: colorScheme.onTint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option {
  final String lang;
  final String label;
  final String code;
  final String subtitle;

  const _Option({
    required this.lang,
    required this.label,
    required this.code,
    required this.subtitle,
  });
}
