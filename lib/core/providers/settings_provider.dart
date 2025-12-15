import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String language;
  final bool showTransliteration;
  final double arabicFontSize;
  final double translationFontSize;
  final double mushafFontSize;
  final ThemeMode themeMode;

  AppSettings({
    this.language = 'id',
    this.showTransliteration = false,
    this.arabicFontSize = 24.0,
    this.translationFontSize = 16.0,
    this.mushafFontSize = 28.0,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    String? language,
    bool? showTransliteration,
    double? arabicFontSize,
    double? translationFontSize,
    double? mushafFontSize,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      language: language ?? this.language,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      mushafFontSize: mushafFontSize ?? this.mushafFontSize,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'showTransliteration': showTransliteration,
      'arabicFontSize': arabicFontSize,
      'translationFontSize': translationFontSize,
      'mushafFontSize': mushafFontSize,
      'themeMode': themeMode.name,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] as String? ?? 'id',
      showTransliteration: json['showTransliteration'] as bool? ?? false,
      arabicFontSize: (json['arabicFontSize'] as num?)?.toDouble() ?? 24.0,
      translationFontSize: (json['translationFontSize'] as num?)?.toDouble() ?? 16.0,
      mushafFontSize: (json['mushafFontSize'] as num?)?.toDouble() ?? 28.0,
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
    final language = prefs.getString('language') ?? 'id';
    final showTransliteration = prefs.getBool('showTransliteration') ?? false;
    final arabicFontSize = prefs.getDouble('arabicFontSize') ?? 24.0;
    final translationFontSize = prefs.getDouble('translationFontSize') ?? 16.0;
    final mushafFontSize = prefs.getDouble('mushafFontSize') ?? 28.0;
    final themeModeStr = prefs.getString('themeMode') ?? 'system';
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeModeStr,
      orElse: () => ThemeMode.system,
    );

    state = AppSettings(
      language: language,
      showTransliteration: showTransliteration,
      arabicFontSize: arabicFontSize,
      translationFontSize: translationFontSize,
      mushafFontSize: mushafFontSize,
      themeMode: themeMode,
    );
  }

  Future<void> updateLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    state = state.copyWith(language: language);
  }

  Future<void> updateShowTransliteration(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showTransliteration', show);
    state = state.copyWith(showTransliteration: show);
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

