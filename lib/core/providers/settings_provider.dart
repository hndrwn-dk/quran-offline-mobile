import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/notifications/weekly_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How Mushaf pages turn. [curl] is the printed-book leaf turn.
enum MushafPageTurn { curl, slide, none }

/// Page turn when the reader has not chosen one: the book turn where pages
/// sit on paper sheets (window >= 600dp), the slide on phones and the cover.
MushafPageTurn defaultMushafPageTurn({required bool framed}) =>
    framed ? MushafPageTurn.curl : MushafPageTurn.slide;

/// Set when first-run setup (the language picker) has finished.
const String kLanguageSelectionDoneKey = 'language_selection_done';

MushafPageTurn? _parsePageTurn(Object? name) {
  for (final turn in MushafPageTurn.values) {
    if (turn.name == name) return turn;
  }
  return null;
}
class AppSettings {
  final String language; // For translation
  final String appLanguage; // For UI/menu
  final bool showTransliteration;
  final bool showTranslation;
  final bool showTafsir;
  final double arabicFontSize;
  final double translationFontSize;
  final double mushafFontSize;
  final bool mushafTwoPageSpread;
  /// The reader's explicit choice (applies everywhere); null = per-window
  /// default, see [pageTurnFor].
  final MushafPageTurn? mushafPageTurn;

  /// Page turn in effect for a framed (>= 600dp) or phone window.
  MushafPageTurn pageTurnFor({required bool framed}) =>
      mushafPageTurn ?? defaultMushafPageTurn(framed: framed);
  final ThemeMode themeMode;
  final bool weeklyReminderEnabled;
  final int weeklyReminderHour;
  final int weeklyReminderMinute;

  /// Last app version (`APP_VERSION`) whose What's new card the reader saw
  /// or closed. '' = never (also builds made before the card existed).
  final String seenVersion;

  /// First-run setup finished ([kLanguageSelectionDoneKey], or a legacy
  /// install that already had a language). Read-only here: it is not part of
  /// [toJson]; the onboarding key is the source of truth.
  final bool onboarded;

  AppSettings({
    this.language = 'en',
    this.appLanguage = 'en',
    this.showTransliteration = true,
    this.showTranslation = true, // Default to true since translations are currently always shown
    this.showTafsir = true,
    this.arabicFontSize = 30.0,
    this.translationFontSize = 16.0,
    this.mushafFontSize = 38.0,
    this.mushafTwoPageSpread = true,
    this.mushafPageTurn,
    this.themeMode = ThemeMode.system,
    this.weeklyReminderEnabled = false,
    this.weeklyReminderHour = 15,
    this.weeklyReminderMinute = 30,
    this.seenVersion = '',
    this.onboarded = false,
  });

  AppSettings copyWith({
    String? language,
    String? appLanguage,
    bool? showTransliteration,
    bool? showTranslation,
    bool? showTafsir,
    double? arabicFontSize,
    double? translationFontSize,
    double? mushafFontSize,
    bool? mushafTwoPageSpread,
    MushafPageTurn? mushafPageTurn,
    ThemeMode? themeMode,
    bool? weeklyReminderEnabled,
    int? weeklyReminderHour,
    int? weeklyReminderMinute,
    String? seenVersion,
    bool? onboarded,
  }) {
    return AppSettings(
      language: language ?? this.language,
      appLanguage: appLanguage ?? this.appLanguage,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showTranslation: showTranslation ?? this.showTranslation,
      showTafsir: showTafsir ?? this.showTafsir,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      mushafFontSize: mushafFontSize ?? this.mushafFontSize,
      mushafTwoPageSpread: mushafTwoPageSpread ?? this.mushafTwoPageSpread,
      mushafPageTurn: mushafPageTurn ?? this.mushafPageTurn,
      themeMode: themeMode ?? this.themeMode,
      weeklyReminderEnabled: weeklyReminderEnabled ?? this.weeklyReminderEnabled,
      weeklyReminderHour: weeklyReminderHour ?? this.weeklyReminderHour,
      weeklyReminderMinute: weeklyReminderMinute ?? this.weeklyReminderMinute,
      seenVersion: seenVersion ?? this.seenVersion,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'appLanguage': appLanguage,
      'showTransliteration': showTransliteration,
      'showTranslation': showTranslation,
      'showTafsir': showTafsir,
      'arabicFontSize': arabicFontSize,
      'translationFontSize': translationFontSize,
      'mushafFontSize': mushafFontSize,
      'mushafTwoPageSpread': mushafTwoPageSpread,
      'mushafPageTurn': mushafPageTurn?.name,
      'themeMode': themeMode.name,
      'weeklyReminderEnabled': weeklyReminderEnabled,
      'weeklyReminderHour': weeklyReminderHour,
      'weeklyReminderMinute': weeklyReminderMinute,
      'seenVersion': seenVersion,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final language = json['language'] as String? ?? 'en';
    return AppSettings(
      language: language,
      appLanguage: json['appLanguage'] as String? ?? language,
      showTransliteration: json['showTransliteration'] as bool? ?? true,
      showTranslation: json['showTranslation'] as bool? ?? true,
      showTafsir: json['showTafsir'] as bool? ?? true,
      arabicFontSize: (json['arabicFontSize'] as num?)?.toDouble() ?? 30.0,
      translationFontSize: (json['translationFontSize'] as num?)?.toDouble() ?? 16.0,
      mushafFontSize: (json['mushafFontSize'] as num?)?.toDouble() ?? 38.0,
      mushafTwoPageSpread: json['mushafTwoPageSpread'] as bool? ?? true,
      mushafPageTurn: _parsePageTurn(json['mushafPageTurn']),
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      weeklyReminderEnabled: json['weeklyReminderEnabled'] as bool? ?? false,
      weeklyReminderHour: json['weeklyReminderHour'] as int? ?? 15,
      weeklyReminderMinute: json['weeklyReminderMinute'] as int? ?? 30,
      seenVersion: json['seenVersion'] as String? ?? '',
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'en';
    final appLanguage = prefs.getString('appLanguage') ?? language; // Default to language for backward compatibility
    final showTransliteration = prefs.getBool('showTransliteration') ?? true;
    final showTranslation = prefs.getBool('showTranslation') ?? true; // Default to true for backward compatibility
    final showTafsir = prefs.getBool('showTafsir') ?? true;
    final arabicFontSize = prefs.getDouble('arabicFontSize') ?? 30.0;
    final translationFontSize = prefs.getDouble('translationFontSize') ?? 16.0;
    final mushafFontSize = prefs.getDouble('mushafFontSize') ?? 38.0;
    final mushafTwoPageSpread =
        prefs.getBool('mushafTwoPageSpread') ?? true;
    final mushafPageTurn = _parsePageTurn(prefs.getString('mushafPageTurn'));
    final themeModeStr = prefs.getString('themeMode') ?? 'system';
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeModeStr,
      orElse: () => ThemeMode.system,
    );
    final weeklyReminderEnabled = prefs.getBool('weeklyReminderEnabled') ?? false;
    final weeklyReminderHour = prefs.getInt('weeklyReminderHour') ?? 15;
    final weeklyReminderMinute = prefs.getInt('weeklyReminderMinute') ?? 30;
    final seenVersion = prefs.getString('seenVersion') ?? '';
    // Same rule as the onboarding legacy migration, so upgraders count as
    // onboarded even if this runs before the splash migrates them.
    final onboarded = prefs.getBool(kLanguageSelectionDoneKey) ??
        prefs.getString('appLanguage') != null;

    final syncedLanguage = language;
    if (appLanguage != syncedLanguage) {
      await prefs.setString('appLanguage', syncedLanguage);
    }

    state = AppSettings(
      language: syncedLanguage,
      appLanguage: syncedLanguage,
      showTransliteration: showTransliteration,
      showTranslation: showTranslation,
      showTafsir: showTafsir,
      arabicFontSize: arabicFontSize,
      translationFontSize: translationFontSize,
      mushafFontSize: mushafFontSize,
      mushafTwoPageSpread: mushafTwoPageSpread,
      mushafPageTurn: mushafPageTurn,
      themeMode: themeMode,
      weeklyReminderEnabled: weeklyReminderEnabled,
      weeklyReminderHour: weeklyReminderHour,
      weeklyReminderMinute: weeklyReminderMinute,
      seenVersion: seenVersion,
      onboarded: state.onboarded || onboarded,
    );

    await _applyWeeklyReminderSchedule();
  }

  Future<void> _applyWeeklyReminderSchedule() async {
    await WeeklyReminderService.instance.rescheduleIfEnabled(
      enabled: state.weeklyReminderEnabled,
      hour: state.weeklyReminderHour,
      minute: state.weeklyReminderMinute,
      language: state.appLanguage,
    );
  }

  /// Sets menu UI and Qur'an content language together.
  Future<void> updateLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale);
    await prefs.setString('appLanguage', locale);
    state = state.copyWith(language: locale, appLanguage: locale);
    await _applyWeeklyReminderSchedule();
  }

  Future<void> updateLanguage(String language) async {
    await updateLocale(language);
  }

  Future<void> updateAppLanguage(String appLanguage) async {
    await updateLocale(appLanguage);
  }

  /// First-run setup finished. New installs record the current version as
  /// seen so they never get the What's new card for it.
  Future<void> completeOnboarding(String currentVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kLanguageSelectionDoneKey, true);
    await prefs.setString('seenVersion', currentVersion);
    state = state.copyWith(onboarded: true, seenVersion: currentVersion);
  }

  /// What's new card closed: saves the full [version] right away.
  Future<void> markWhatsNewSeen(String version) async {
    state = state.copyWith(seenVersion: version);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('seenVersion', version);
  }

  Future<void> updateShowTransliteration(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTransliteration', show);
    state = state.copyWith(showTransliteration: show);
  }

  Future<void> updateShowTranslation(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTranslation', show);
    state = state.copyWith(showTranslation: show);
  }

  Future<void> updateShowTafsir(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTafsir', show);
    state = state.copyWith(showTafsir: show);
  }

  /// Page-turn animation for the Mushaf (Lembar/Geser/Tanpa).
  Future<void> updateMushafPageTurn(MushafPageTurn turn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mushafPageTurn', turn.name);
    state = state.copyWith(mushafPageTurn: turn);
  }

  /// Two Mushaf pages side by side on wide windows (default on).
  Future<void> updateMushafTwoPageSpread(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mushafTwoPageSpread', enabled);
    state = state.copyWith(mushafTwoPageSpread: enabled);
  }

  Future<void> updateArabicFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('arabicFontSize', size);
    state = state.copyWith(arabicFontSize: size);
  }

  Future<void> updateTranslationFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('translationFontSize', size);
    state = state.copyWith(translationFontSize: size);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updateMushafFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mushafFontSize', size);
    state = state.copyWith(mushafFontSize: size);
  }

  Future<bool> updateWeeklyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      await WeeklyReminderService.instance.initialize();
      final granted = await WeeklyReminderService.instance.requestPermission();
      if (!granted) {
        return false;
      }
    }
    await prefs.setBool('weeklyReminderEnabled', enabled);
    state = state.copyWith(weeklyReminderEnabled: enabled);
    await _applyWeeklyReminderSchedule();
    return true;
  }

  Future<void> updateWeeklyReminderTime({
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weeklyReminderHour', hour);
    await prefs.setInt('weeklyReminderMinute', minute);
    state = state.copyWith(
      weeklyReminderHour: hour,
      weeklyReminderMinute: minute,
    );
    await _applyWeeklyReminderSchedule();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
