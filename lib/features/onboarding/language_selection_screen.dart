import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/nav_read_icon.dart';
import 'package:quran_offline/features/home/home_screen.dart';

const String _logoAssetPath = 'assets/icon/splash_icon.png';

const String _prefKeyLanguageDone = 'language_selection_done';

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

Future<void> _markLanguageSelectionDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKeyLanguageDone, true);
}

Future<void> _onLanguageSelected(
  BuildContext context,
  WidgetRef ref,
  String lang,
) async {
  await ref.read(settingsProvider.notifier).updateLocale(lang);
  await _markLanguageSelectionDone();
  if (context.mounted) {
    await NavReadIcon.precache(context);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
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
      body: Stack(
        children: [
          const Positioned.fill(child: _OnboardingBackdrop()),
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
                              const SizedBox(height: 28),
                              Text(
                                AppLocalizations.getOnboardingWelcome(hintLang),
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Quran Offline',
                                style: textTheme.labelLarge?.copyWith(
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                AppLocalizations.getOnboardingLanguageHeadline(
                                  hintLang,
                                ),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
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
                              const SizedBox(height: 14),
                              Text(
                                AppLocalizations.getOnboardingSettingsHint(
                                  hintLang,
                                ),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.9,
                                  ),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...List.generate(_languageOptions.length, (index) {
                          final opt = _languageOptions[index];
                          return AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _cardSlides[index].value),
                                child: Opacity(
                                  opacity: _cardFades[index].value,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _languageOptions.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: _LanguageTile(
                                option: opt,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                                isDark: isDark,
                                onTap: () => _onLanguageSelected(
                                  context,
                                  ref,
                                  opt.lang,
                                ),
                              ),
                            ),
                          );
                        }),
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
    const size = 96.0;
    final ringColor = colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.14);
    final glowColor = colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.06);

    return Container(
      width: size + 36,
      height: size + 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withValues(alpha: 0.95),
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              _logoAssetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final topTint = isDark
        ? colorScheme.primary.withValues(alpha: 0.12)
        : const Color(0xFFE8EDE3);
    final bottomTint = isDark
        ? colorScheme.surface
        : colorScheme.surface.withValues(alpha: 0.98);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topTint, bottomTint],
        ),
      ),
      child: CustomPaint(
        painter: _OnboardingPatternPainter(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.06 : 0.05),
        ),
      ),
    );
  }
}

class _OnboardingPatternPainter extends CustomPainter {
  _OnboardingPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 56.0;
    for (var x = -spacing; x < size.width + spacing; x += spacing) {
      for (var y = -spacing; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 18, paint);
      }
    }

    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final arcRect = Rect.fromCircle(
      center: Offset(size.width * 0.82, size.height * 0.12),
      radius: 120,
    );
    canvas.drawArc(arcRect, 2.4, 1.2, false, arcPaint);

    final arcRect2 = Rect.fromCircle(
      center: Offset(size.width * 0.12, size.height * 0.88),
      radius: 90,
    );
    canvas.drawArc(arcRect2, -0.8, 1.0, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _OnboardingPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _LanguageTile extends StatefulWidget {
  final _Option option;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.option,
    required this.colorScheme,
    required this.textTheme,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final textTheme = widget.textTheme;

    final shadowOpacity = widget.isDark ? 0.28 : 0.08;
    final surfaceColor = widget.isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.92)
        : colorScheme.surface.withValues(alpha: 0.94);

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: shadowOpacity),
              blurRadius: _pressed ? 8 : 18,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Material(
              color: surfaceColor,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (value) => setState(() => _pressed = value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      _LanguageBadge(
                        code: widget.option.code,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.option.label,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.option.subtitle,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: widget.isDark ? 0.55 : 0.85,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: colorScheme.onPrimaryContainer,
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
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({
    required this.code,
    required this.colorScheme,
  });

  final String code;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Text(
            code,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                  letterSpacing: 0.6,
                ),
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
