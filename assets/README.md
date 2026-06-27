# Assets layout

Place files under `assets/`. Sources and licenses: [DATA_SOURCES.md](../DATA_SOURCES.md).

```
assets/
├── quran/
│   ├── manifest_multi.json
│   ├── index_juz.json
│   ├── index_pages.json
│   ├── surah_meanings.json
│   ├── s001.json … s114.json
│   ├── surah_info/
│   │   ├── en_surah_info.sqlite
│   │   └── id_surah_info.sqlite
│   ├── transliteration/
│   │   └── transliteration-tajweed.db
│   └── surah_names/
│       └── manifest.json
├── tafsir/
│   ├── en_ibn_kathir.sqlite
│   ├── id_as_saadi.sqlite
│   ├── zh_mokhtasar.sqlite
│   └── ja_mokhtasar.sqlite
├── duas/
│   └── duas_catalog.json
├── asma/
│   └── asmaul_husna_catalog.json
├── science/
│   └── science_catalog.json
├── themes/
│   └── life_themes_catalog.json
├── reflection/
│   ├── calendar_lenses_catalog.json
│   └── weekly_rotation_catalog.json
├── icon/
└── fonts/
    ├── uthmanic_hafs_v22.ttf
    ├── KFGQPC Uthmanic Script HAFS Regular.otf
    ├── ScheherazadeNew-Regular.ttf
    └── surah_name_v2.ttf
```

## Verse JSON (`s###.json`)

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
