# Assets layout

Place the files below under `assets/`. See [DATA_SOURCES.md](../DATA_SOURCES.md) for official sources and licenses.

## Required for a working app

```
assets/
├── quran/
│   ├── manifest_multi.json
│   ├── index_juz.json
│   ├── index_pages.json
│   ├── surah_meanings.json
│   ├── s001.json … s114.json          # one JSON array per surah
│   ├── surah_info/
│   │   ├── en_surah_info.sqlite
│   │   └── id_surah_info.sqlite
│   └── surah_names/                   # optional if using SurahNameV2 font only
│       ├── manifest.json
│       └── s001.svg … s114.svg
├── tafsir/
│   ├── en_ibn_kathir.sqlite
│   ├── id_as_saadi.sqlite
│   ├── zh_mokhtasar.sqlite
│   └── ja_mokhtasar.sqlite
└── fonts/
    ├── uthmanic_hafs_v22.ttf
    ├── KFGQPC Uthmanic Script HAFS Regular.otf
    ├── ScheherazadeNew-Regular.ttf
    └── surah_name_v2.ttf
```

## App catalogs & icons

| Path | Description |
|------|-------------|
| `assets/icon/` | Launcher, splash, nav icons |
| `assets/duas/` | Dua catalog (app content) |
| `assets/science/` | Science & Quran catalog |
| `assets/themes/` | Life themes catalog |
| `assets/reflection/` | Reflection / calendar catalogs |
| `assets/asma/` | Asmaul Husna catalog |

## Verse JSON quick reference (`s###.json`)

Array of objects:

```json
{
  "s": 1,
  "a": 1,
  "ar": "…",
  "tj": "…",
  "tl": "…",
  "tl_tj": "…",
  "tr": { "en": "…", "id": "…", "zh": "…", "ja": "…" },
  "m": { "juz": 1, "page": 1, "hizb": 1, "ruku": 1 }
}
```

Parser: `lib/core/models/verse_model.dart`  
Import version string: `lib/core/database/importer.dart` → `DataImporter.currentVersion`

## Verify

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

On first launch the app imports `assets/quran/s*.json` into a local SQLite database. Missing files cause import errors or an empty reader.
