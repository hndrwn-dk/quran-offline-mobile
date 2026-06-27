import 'package:flutter/material.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

/// Material outlined icons for Jelajahi hub sections and category grids.
class ExploreIcons {
  ExploreIcons._();

  static const hubSectionAssets = <String, String>{
    'prophet': 'assets/icon/explore/explore_hub_prophet.png',
    'science': 'assets/icon/explore/explore_hub_science.png',
    'asma': 'assets/icon/explore/explore_hub_asma.png',
    'life_theme': 'assets/icon/explore/explore_hub_life_theme.png',
  };

  /// Bundled PNG for hub rows; null falls back to [hubSection] Material icon.
  static String? hubSectionAsset(String section) => hubSectionAssets[section];

  static IconData hubSection(String section) {
    return switch (section) {
      'prophet' => Icons.people_outline,
      'science' => Icons.biotech_outlined,
      'asma' => Icons.auto_awesome_outlined,
      'life_theme' => Icons.self_improvement_outlined,
      _ => Icons.category_outlined,
    };
  }

  static IconData scienceCategory(String key) {
    return switch (key) {
      'cosmos' => Icons.public_outlined,
      'biology' => Icons.biotech_outlined,
      'earth' => Icons.terrain_outlined,
      'physics' => Icons.science_outlined,
      _ => Icons.lightbulb_outline,
    };
  }

  static const themeCategoryAssets = <String, String>{
    'forgiveness': 'assets/icon/explore/explore_daily_forgiveness.png',
    'faith': 'assets/icon/explore/explore_daily_faith.png',
    'patience': 'assets/icon/explore/explore_theme_patience.png',
    'trials': 'assets/icon/explore/explore_daily_trials.png',
    'protection': 'assets/icon/explore/explore_daily_protection.png',
    'provision': 'assets/icon/explore/explore_daily_provision.png',
    'family': 'assets/icon/explore/explore_daily_family.png',
    'gratitude': 'assets/icon/explore/explore_daily_gratitude.png',
    'hope': 'assets/icon/explore/explore_theme_hope.png',
    'character': 'assets/icon/explore/explore_theme_character.png',
    'world_hereafter': 'assets/icon/explore/explore_daily_world_hereafter.png',
  };

  static String? themeCategoryAsset(String key) {
    final normalized =
        AppLocalizations.normalizeLifeSituationCategoryKey(key);
    return themeCategoryAssets[normalized];
  }

  static IconData themeCategory(String key) {
    final normalized =
        AppLocalizations.normalizeLifeSituationCategoryKey(key);
    return switch (normalized) {
      'forgiveness' => Icons.healing_outlined,
      'faith' => Icons.favorite_border,
      'patience' => Icons.hourglass_empty_outlined,
      'trials' => Icons.landscape_outlined,
      'protection' => Icons.shield_outlined,
      'provision' => Icons.explore_outlined,
      'family' => Icons.family_restroom_outlined,
      'gratitude' => Icons.volunteer_activism_outlined,
      'hope' => Icons.wb_sunny_outlined,
      'character' => Icons.psychology_outlined,
      'world_hereafter' => Icons.auto_awesome_outlined,
      _ => Icons.bookmark_border_outlined,
    };
  }

  static const prophetAssets = <String, String>{
    'muhammad': 'assets/icon/explore/explore_prophet_muhammad.png',
  };

  static String? prophetAsset(String key) => prophetAssets[key];

  static IconData prophet(String key) {
    return switch (key) {
      'ibrahim' || 'ismail' || 'ishaq' || 'yaqub' => Icons.volunteer_activism_outlined,
      'musa' || 'harun' => Icons.water_outlined,
      'isa' => Icons.healing_outlined,
      'muhammad' => Icons.mosque_outlined,
      _ => Icons.person_outline,
    };
  }
}
