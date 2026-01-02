# Quran Offline

A production-ready, offline-first Quran reader app built with Flutter, featuring Material 3 design, comprehensive reading modes, and advanced features for an enhanced Quranic reading experience.

## ✨ Features

### 📖 Reading Modes
- **Read by Surah**: Navigate through all 114 surahs with word-by-word translation
- **Read by Juz**: Read by 30 juz divisions
- **Read by Pages (Mushaf)**: Traditional page-by-page reading (604 pages)
- **Last Read**: Automatically saves and resumes your reading position
- **Swipe Navigation**: Effortlessly swipe between Surah, Juz, and Page modes

### 🎨 Tajweed Color Coding
- **8 Tajweed Rules**: Visual color coding for proper Quranic recitation
  - Ikhfa (Concealment)
  - Idgham (Merging)
  - Iqlab (Conversion)
  - Ghunnah (Nasalization)
  - Qalqalah (Echo)
  - Laam Shamsiyah (Solar Lam)
  - Madd (Elongation)
  - Ham Wasl (Connecting Hamza)
- **Interactive Color Guide**: Tap info icon to view detailed tajweed guide
- **100% Offline**: All tajweed data stored locally
- **Toggle Support**: Enable/disable tajweed from Settings or Text Settings

### 📚 My Library
- **Unified Library**: All personal content in one place with tab navigation
  - **Bookmarks**: Save and organize favorite verses with bulk delete support
  - **Notes**: Add personal notes to any verse with search and navigation
  - **Highlights**: Color-code verses with 8 highlight colors (Favorite, Inspiring, Love, etc.)
- **Card-Based Design**: Beautiful card layout with verse previews
- **Arabic & Translation Preview**: See verse content directly in lists
- **Global Search**: Search across all bookmarks, notes, and highlights

### 🔍 Search & Navigation
- **Quick Search**: Inline search in Read screen for Surah, Juz, or Page
- **Advanced Search**: Full-text search through translations
- **Instant Results**: Quick navigation to search results

### 🌍 Localization
- **4 Languages**: Full support for Indonesian, English, Chinese, and Japanese
- **Complete UI Localization**: All UI elements properly localized
- **Tajweed Guide Localized**: Interactive guide in all supported languages

### ⚙️ Customization
- **Font Sizes**: Adjustable Arabic and translation font sizes independently
- **Transliteration**: Optional transliteration display
- **Theme**: System, Light, or Dark mode support
- **Text Settings**: Quick access to text customization

### 📤 Sharing
- **Share Verses**: Share verses with others via system share dialog

### 🎯 Additional Features
- **Offline-First**: Fully functional without internet connection
- **Material 3 Design**: Modern, accessible UI following Material You guidelines
- **Privacy-First**: No analytics or tracking by default
- **Performance Optimized**: Smooth scrolling and fast navigation

## 📋 Requirements

- Flutter SDK >=3.0.0
- Dart SDK >=3.0.0

## 🚀 Installation

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

## 📁 Project Structure

```
lib/
├── app/                 # App initialization
├── core/
│   ├── database/        # Drift database schema and importer
│   ├── models/         # Data models
│   ├── providers/      # Riverpod providers
│   ├── utils/          # Utilities (localization, helpers)
│   └── widgets/        # Core widgets (TajweedText, etc.)
└── features/
    ├── bookmarks/      # Bookmarks feature
    ├── highlights/     # Highlights feature
    ├── home/           # Main navigation
    ├── library/        # My Library (unified screen)
    ├── notes/          # Notes feature
    ├── read/           # Reading modes (Surah/Juz/Pages)
    ├── reader/         # Verse reader screen
    ├── search/         # Search functionality
    └── settings/       # App settings
```

## 📊 Data Format

The app uses Quran.com v4 style JSON format:
- `manifest_multi.json`: Dataset metadata
- `s###.json`: Individual surah files (s001.json to s114.json)
  - Each file contains: Arabic text, Tajweed HTML (`tj`), Transliteration, Translations (EN/ID/ZH/JA)
- `index_juz.json`: Juz index mapping
- `index_pages.json`: Page index mapping
- `surah_names/`: Localized surah names

## 💾 Database

The app uses Drift (SQLite) for local storage:
- **Verses Table**: Stores all verses with translations and tajweed data
- **Bookmarks Table**: Stores user bookmarks
- **Notes Table**: Stores user notes per verse
- **Highlights Table**: Stores user highlights with color codes
- Data is imported from JSON assets on first launch

## ⚙️ Settings

- **Language**: Switch between Indonesian, English, Chinese, Japanese
- **Show Tajweed**: Toggle color-coded tajweed rules with interactive guide
- **Transliteration**: Toggle transliteration display
- **Font Sizes**: Adjust Arabic and translation font sizes independently
- **Theme**: System, Light, or Dark mode

## 🧪 Testing

Quick start:
```bash
# Generate required code first
flutter pub run build_runner build --delete-conflicting-outputs

# Run on connected device/emulator
flutter run
```

## 📦 Building for Release

### Android

```bash
flutter build appbundle
```

The AAB file will be generated at: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios
flutter build ipa
```

## 🔒 Privacy

This app:
- Works fully offline
- Does not collect analytics
- Does not track users
- Stores all data locally
- No internet connection required

## 📝 Version

**Current Version**: 1.0.0 (Build 5)

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Credits

- **Quran Data**: Quran Foundation / Quran.com v4
- **Tajweed Data**: Quran Foundation
- **Fonts**: 
  - Uthmanic HAFS V22
  - KFGQPC Uthmanic Script
  - Scheherazade New

## 🛠️ Technical Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Database**: Drift (SQLite)
- **Localization**: Custom AppLocalizations
- **Design**: Material 3
