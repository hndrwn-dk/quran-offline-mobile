# Quran Offline

A production-ready, offline-first Quran reader built with Flutter and Material 3 — Surah, Juz, and Mushaf reading with tajweed, tafsir, recitation, and a personal library.

**Current version:** 1.0.5 (build 31)

## Features

### Reading

- **Surah / Juz / Mushaf (604 pages)** with swipe between modes
- **Last read** resume across Surah, Juz, and page
- **Reader** with per-ayah translation, transliteration, and tajweed
- **QUL surah header** — decorative SurahNameV2 glyph plus **Tentang surat** (QUL surah info, EN/ID)
- **Mushaf** flowing layout with tajweed, tap-to-play ayah, long-press for meaning/bookmark/share
- **QUL surah titles** in Mushaf (SurahNameV2 font, sized for page layout)

### Audio recitation

- **Per-ayah playback** with global mini player (background-friendly)
- **Offline download** per surah or full reciter catalog (EveryAyah)
- Follow-along scroll while reciting

### Tafsir

- Inline **tafsir panel** per ayah (toggle in text settings)
- Bundled QUL SQLite: Ibn Kathir (EN), As-Sa'di (ID), Mokhtasar (ZH/JA)

### Tajweed

- Eight color-coded rules (Ikhfa, Idgham, Iqlab, Ghunnah, Qalqalah, Laam Shamsiyah, Madd, Ham Wasl)
- Interactive guide (localized)
- Toggle from Settings or reader text settings

### Search

- **Quick search** on Read tab (Surah / Juz / Page)
- **Full search** tab — surah, juz, page, ayat reference, Arabic verse text, translation
- **QUL name glyphs** (SurahNameV2) in surah search results

### My Library

- **Bookmarks**, **notes**, and **highlights** in one screen
- Arabic + translation previews, global search, jump back to reader or Mushaf

### Explore & reflection

- **Dua** catalog, **science & Quran**, **life themes** (local JSON — see [DATA_SOURCES.md](DATA_SOURCES.md))
- **Weekly reflection** and calendar lenses on Read tab
- **Asmaul Husna** names

### Localization & settings

- **4 UI languages:** Indonesian, English, Chinese, Japanese
- **Single Bahasa setting** — menu, terjemahan, tafsir, and surah info follow one locale
- Transliteration, tajweed, tafsir, and font size toggles
- System / light / dark theme
- **Data sources** credits (Quran Foundation, QUL, EveryAyah)

### Privacy

- Offline-first core experience
- No analytics or tracking by default
- User data stored locally

## Requirements

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

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

3. Add data under `assets/` — see [DATA_SOURCES.md](DATA_SOURCES.md) and [assets/README.md](assets/README.md).

4. Generate code (Drift + JSON):

```bash
dart run build_runner build --delete-conflicting-outputs
```

5. Run the app:

```bash
flutter run
```

## Project structure

```
lib/
├── app/
├── core/
│   ├── database/       # Drift schema + verse importer
│   ├── surah_info/     # QUL surah info SQLite
│   ├── tafsir/         # QUL tafsir SQLite
│   ├── providers/
│   ├── utils/
│   └── widgets/        # TajweedText, SurahNameGlyph, NavReadIcon, …
└── features/
    ├── audio/          # Global recitation bar, offline downloads
    ├── read/           # Surah / Juz / Mushaf lists + page view
    ├── reader/         # Verse reader, tafsir panel, surah header
    ├── search/
    ├── library/
    ├── settings/
    └── …
test/                   # Unit and widget tests
```

## Data

Verse JSON, tafsir, and surah-info SQLite paths are documented in [DATA_SOURCES.md](DATA_SOURCES.md).

On first launch the app imports `assets/quran/s*.json` into a local Drift database. Audio is streamed or cached from EveryAyah at runtime (not under `assets/`).

## Testing

```bash
flutter test
```

Manual QA before Play upload: see `bundles_release/play-console/QA_CHECKLIST_1.0.3+27.md` (local; folder gitignored).

Local dev dumps (`.ui_*.xml`, `.audio_test_shots/`, `.regression_shots/`) are gitignored — safe to delete anytime.

## Building for release

Place all required assets locally before building (see [DATA_SOURCES.md](DATA_SOURCES.md)).

### Android

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

APK:

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios
flutter build ipa
```

## License

- **Source code:** MIT — see [LICENSE](LICENSE)
- **Quran / translation / tafsir / surah-info data:** see [DATA_SOURCES.md](DATA_SOURCES.md); each source has its own terms

## Credits

- **Quran text & translations:** Quran Foundation / [Quran.com](https://quran.com/) API v4
- **Surah info & tafsir:** [QUL](https://qul.tarteel.ai/) (Quranic Universal Library)
- **Recitation audio:** [EveryAyah](https://everyayah.com/)
- **Surah name font:** QUL SurahNameV2
- **Arabic fonts:** King Fahd Complex (Uthmanic HAFS), SIL Scheherazade New

## Technical stack

- Flutter 3.x, Material 3
- Riverpod
- Drift (SQLite)
- just_audio + background playback
- Custom AppLocalizations (ID / EN / ZH / JA)
