# Quran Offline

A production-ready, offline-first Quran reader app built with Flutter, featuring Material 3 design and comprehensive reading modes.

## Features

- **Offline-First**: Fully functional without internet connection
- **Multiple Reading Modes**:
  - Read by Surah (114 surahs)
  - Read by Juz (30 juz)
  - Read by Pages (604 pages)
- **Multi-Language Support**: Indonesian (default), English, Chinese, Japanese
- **Bookmarks**: Save and organize your favorite verses
- **Search**: Offline search through translations
- **Customizable Text**: Adjustable font sizes for Arabic and translations
- **Transliteration**: Optional transliteration display
- **Share**: Share verses with others
- **Material 3 Design**: Modern, accessible UI following Material You guidelines
- **Privacy-First**: No analytics or tracking by default

## Requirements

- Flutter SDK >=3.0.0
- Dart SDK >=3.0.0

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd quran-offline-mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code (for Drift and JSON serialization):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

   **Note**: This step is required before running the app. It generates:
   - `lib/core/database/database.g.dart` (Drift database code)
   - `lib/core/models/verse_model.g.dart` (JSON serialization code)

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── app/                 # App initialization
├── core/
│   ├── database/        # Drift database schema and importer
│   ├── models/         # Data models
│   └── providers/      # Riverpod providers
└── features/
    ├── bookmarks/      # Bookmarks feature
    ├── home/           # Main navigation
    ├── read/           # Reading modes (Surah/Juz/Pages)
    ├── reader/         # Verse reader screen
    ├── search/         # Search functionality
    └── settings/       # App settings
```

## Data Format

The app uses Quran.com v4 style JSON format:
- `manifest_multi.json`: Dataset metadata
- `s###.json`: Individual surah files (s001.json to s114.json)
- `index_juz.json`: Juz index mapping
- `index_pages.json`: Page index mapping

## Database

The app uses Drift (SQLite) for local storage:
- **Verses Table**: Stores all verses with translations
- **Bookmarks Table**: Stores user bookmarks
- Data is imported from JSON assets on first launch

## Settings

- **Language**: Switch between Indonesian, English, Chinese, Japanese
- **Transliteration**: Toggle transliteration display
- **Font Sizes**: Adjust Arabic and translation font sizes independently
- **Theme**: System, Light, or Dark mode

## Testing

See [TESTING.md](docs/TESTING.md) for detailed testing instructions on Android and iOS.

Quick start:
```bash
# Generate required code first
flutter pub run build_runner build --delete-conflicting-outputs

# Run on connected device/emulator
flutter run
```

## Documentation

- **[TESTING.md](docs/TESTING.md)** - Testing guide for Android & iOS
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Android & iOS deployment overview
- **[IOS_BUILD_AND_APP_STORE.md](docs/IOS_BUILD_AND_APP_STORE.md)** - Comprehensive iOS build & App Store deployment guide (step-by-step, beginner-friendly)

## Building for Release

### Android
See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for Android deployment guide.

```bash
flutter build appbundle
```

### iOS
See [IOS_BUILD_AND_APP_STORE.md](docs/IOS_BUILD_AND_APP_STORE.md) for comprehensive iOS build and App Store deployment guide (step-by-step, beginner-friendly).

```bash
flutter build ios
flutter build ipa
```

**Quick Reference:**
- [DEPLOYMENT.md](docs/DEPLOYMENT.md) - Android & iOS deployment overview
- [IOS_BUILD_AND_APP_STORE.md](docs/IOS_BUILD_AND_APP_STORE.md) - Detailed iOS build & App Store guide
- [TESTING.md](docs/TESTING.md) - Testing guide for Android & iOS

## Privacy

This app:
- Works fully offline
- Does not collect analytics
- Does not track users
- Stores all data locally

## License

MIT License - see LICENSE file for details

## Credits

- Quran data: Quran Foundation / Quran.com v4
- Fonts: Uthmanic HAFS, KFGQPC Uthmanic Script, Scheherazade New
