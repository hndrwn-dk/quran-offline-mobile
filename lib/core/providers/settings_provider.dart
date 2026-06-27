import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String language; // For translation
  final String appLanguage; // For UI/menu
  final bool showTransliteration;
  final bool showTranslation;
  final bool showTafsir;
  final bool showTajweed;
  final double arabicFontSize;
  final double translationFontSize;
  final double mushafFontSize;
  final ThemeMode themeMode;

  AppSettings({
    this.language = 'en',
    this.appLanguage = 'en',
    this.showTransliteration = true,
    this.showTranslation = true, // Default to true since translations are currently always shown
    this.showTafsir = true,
    this.showTajweed = true,
    this.arabicFontSize = 30.0,
    this.translationFontSize = 16.0,
    this.mushafFontSize = 38.0,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    String? language,
    String? appLanguage,
    bool? showTransliteration,
    bool? showTranslation,
    bool? showTafsir,
    bool? showTajweed,
    double? arabicFontSize,
    double? translationFontSize,
    double? mushafFontSize,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      language: language ?? this.language,
      appLanguage: appLanguage ?? this.appLanguage,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showTranslation: showTranslation ?? this.showTranslation,
      showTafsir: showTafsir ?? this.showTafsir,
      showTajweed: showTajweed ?? this.showTajweed,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      mushafFontSize: mushafFontSize ?? this.mushafFontSize,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'appLanguage': appLanguage,
      'showTransliteration': showTransliteration,
      'showTranslation': showTranslation,
      'showTafsir': showTafsir,
      'showTajweed': showTajweed,
      'arabicFontSize': arabicFontSize,
      'translationFontSize': translationFontSize,
      'mushafFontSize': mushafFontSize,
      'themeMode': themeMode.name,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final language = json['language'] as String? ?? 'en';
    return AppSettings(
      language: language,
      appLanguage: json['appLanguage'] as String? ?? language, // Default to language for backward compatibility
      showTransliteration: json['showTransliteration'] as bool? ?? true,
      showTranslation: json['showTranslation'] as bool? ?? true, // Default to true for backward compatibility
      showTafsir: json['showTafsir'] as bool? ?? true,
      showTajweed: json['showTajweed'] as bool? ?? true,
      arabicFontSize: (json['arabicFontSize'] as num?)?.toDouble() ?? 30.0,
      translationFontSize: (json['translationFontSize'] as num?)?.toDouble() ?? 16.0,
      mushafFontSize: (json['mushafFontSize'] as num?)?.toDouble() ?? 38.0,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
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
    final showTajweed = prefs.getBool('showTajweed') ?? true;
    final arabicFontSize = prefs.getDouble('arabicFontSize') ?? 30.0;
    final translationFontSize = prefs.getDouble('translationFontSize') ?? 16.0;
    final mushafFontSize = prefs.getDouble('mushafFontSize') ?? 38.0;
    final themeModeStr = prefs.getString('themeMode') ?? 'system';
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeModeStr,
      orElse: () => ThemeMode.system,
    );

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
      showTajweed: showTajweed,
      arabicFontSize: arabicFontSize,
      translationFontSize: translationFontSize,
      mushafFontSize: mushafFontSize,
      themeMode: themeMode,
    );
  }

  /// Sets menu UI and Qur'an content language together.
  Future<void> updateLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale);
    await prefs.setString('appLanguage', locale);
    state = state.copyWith(language: locale, appLanguage: locale);
  }

  Future<void> updateLanguage(String language) async {
    await updateLocale(language);
  }

  Future<void> updateAppLanguage(String appLanguage) async {
    await updateLocale(appLanguage);
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

  Future<void> updateShowTajweed(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTajweed', show);
    state = state.copyWith(showTajweed: show);
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
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
