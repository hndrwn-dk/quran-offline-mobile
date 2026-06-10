# Data sources

The **application source code** is licensed under the [MIT License](LICENSE).

Quran text, translations, tafsir, surah info, and related datasets come from the official sources below. Place them under `assets/` as described in [assets/README.md](assets/README.md).

You are responsible for complying with each provider's terms and license when obtaining and using their data.

---

## 1. Quran verses (required)

Core reading data: Arabic Uthmani text, tajweed markup, transliteration, and translations.

| Field | Value |
|-------|--------|
| **Output paths** | `assets/quran/s001.json` … `s114.json`, plus `manifest_multi.json`, `index_juz.json`, `index_pages.json` |
| **Primary API** | [Quran.com API v4](https://api.quran.com/api/v4) (Quran Foundation) |
| **Docs** | https://api-docs.quran.com/ |
| **Compatible import version** | See `DataImporter.currentVersion` in `lib/core/database/importer.dart` |

### Per-surah JSON (`s###.json`)

Each file is a JSON **array** of verse objects. Fields used by the app:

| Key | Meaning |
|-----|---------|
| `s` | Surah id (1–114) |
| `a` | Ayah number |
| `ar` | Arabic text (`text_uthmani`) |
| `tj` | Tajweed HTML (optional; from `uthmani_tajweed` endpoint) |
| `tl` | Transliteration (optional) |
| `tl_tj` | Tajweed-aligned transliteration (optional) |
| `tr` | Map of translation codes: `en`, `id`, `zh`, `ja` |
| `m` | Metadata: `juz`, `page`, `hizb`, `ruku` |

### Translations used by this app

| Code | Source (Quran.com resource id) | Name |
|------|--------------------------------|------|
| `en` | 20 | Saheeh International |
| `id` | 33 | Indonesian Islamic Affairs Ministry (Kemenag) |
| `zh` | 109 | Muhammad Makin |
| `ja` | 35 | Ryoichi Mita |

Use the Quran.com v4 API to fetch verses and translations per surah, then shape files to match the schema above. Tajweed can be fetched from:

`GET https://api.quran.com/api/v4/quran/verses/uthmani_tajweed?verse_key={surah}:{ayah}`

### Index files

| File | Purpose |
|------|---------|
| `manifest_multi.json` | Dataset metadata (version, translation ids, ayah count) |
| `index_juz.json` | Juz → surah/ayah ranges |
| `index_pages.json` | Mushaf page (1–604) → surah/ayah ranges |

Obtain or build these to match the app's layout (604-page Madani mushaf). The app reads page/juz indices from `assets/quran/index_pages.json` and `assets/quran/index_juz.json`.

### License

Quran text and Quran.com API data are provided by **Quran Foundation**. Review their terms before redistribution:

- https://quran.foundation/
- https://quran.com/

---

## 2. Surah meanings (required)

Localized surah titles/meanings for lists and UI.

| Field | Value |
|-------|--------|
| **Output path** | `assets/quran/surah_meanings.json` |
| **API** | `GET https://api.quran.com/api/v4/chapters?language={lang}` |
| **Languages** | `en`, `id`, `zh`, `ja` |

JSON shape: top-level keys `"1"` … `"114"`, each value an object with language codes and the translated surah name string.

### License

Same as Quran.com / Quran Foundation (see section 1).

---

## 3. Surah display names — SVG (optional)

Legacy SVG surah titles under `assets/quran/surah_names/`. The app primarily uses the QUL **SurahNameV2** font for decorative names; SVGs are optional if you only use the font glyph.

| Field | Value |
|-------|--------|
| **Output** | `assets/quran/surah_names/manifest.json`, `s001.svg` … `s114.svg` |
| **API** | Quran.com v4 chapter names / glyphs as needed |

---

## 4. Surah info — QUL (required for “Tentang surat”)

Long-form surah introductions (English and Indonesian).

| Field | Value |
|-------|--------|
| **Output paths** | `assets/quran/surah_info/en_surah_info.sqlite`, `assets/quran/surah_info/id_surah_info.sqlite` |
| **Source** | [Quranic Universal Library (QUL)](https://qul.tarteel.ai/) — Surah Info resources |
| **Runtime table** | `surah_infos` with columns `surah_number`, `text`, `short_text` |
| **Bundle version** | See `SurahInfoConfig.bundleVersion` in `lib/core/surah_info/surah_info_config.dart` |

Download or export the official QUL surah-info SQLite bundles for English and Indonesian and place them at the paths above.

### License

QUL content is subject to **QUL / Tarteel** terms. Review before use:

- https://qul.tarteel.ai/
- https://github.com/TarteelAI/quranic-universal-library

---

## 5. Tafsir — QUL (required for tafsir panel)

Per-ayah tafsir SQLite bundles.

| File | Language | Work |
|------|----------|------|
| `assets/tafsir/en_ibn_kathir.sqlite` | English | Ibn Kathir |
| `assets/tafsir/id_as_saadi.sqlite` | Indonesian | As-Sa'di |
| `assets/tafsir/zh_mokhtasar.sqlite` | Chinese | Mokhtasar |
| `assets/tafsir/ja_mokhtasar.sqlite` | Japanese | Mokhtasar |

| Field | Value |
|-------|--------|
| **Source** | [QUL Tafsir resources](https://qul.tarteel.ai/) |
| **Runtime table** | `tafsir` with `ayah_key`, `group_ayah_key`, `text`, … |
| **Bundle version** | See `TafsirConfig.bundleVersion` in `lib/core/tafsir/tafsir_config.dart` |

### License

Same as QUL (section 4). Tafsir works have their own scholarly copyrights; use only through permitted QUL exports.

---

## 6. Arabic & UI fonts (required to build)

| File | Family | Source |
|------|--------|--------|
| `assets/fonts/uthmanic_hafs_v22.ttf` | UthmanicHafsV22 | [King Fahd Complex](https://fonts.qurancomplex.gov.sa/) |
| `assets/fonts/KFGQPC Uthmanic Script HAFS Regular.otf` | KFGQPCUthmanic | King Fahd Complex |
| `assets/fonts/ScheherazadeNew-Regular.ttf` | ScheherazadeNew | [SIL](https://software.sil.org/scheherazade/) (OFL) |
| `assets/fonts/surah_name_v2.ttf` | SurahNameV2 | [QUL Surah name font v2](https://qul.tarteel.ai/) |

See also `assets/fonts/README.md`.

---

## 7. Audio recitation (not in `assets/`)

Recitation is **not** bundled. The app streams or caches MP3s at runtime.

| Field | Value |
|-------|--------|
| **Provider** | [EveryAyah.com](https://everyayah.com/) |
| **Cache location** | App documents directory (`audio/{reciterId}/`) |
| **URL pattern** | `{reciter.baseUrl}/{SSS}{AAA}.mp3` (e.g. `001001.mp3`) |

### License

EveryAyah audio is subject to EveryAyah's terms. Attribution is shown in app Settings → Sumber data.

---

## 8. App-authored catalogs

These small JSON catalogs are app content (not third-party Quran datasets):

- `assets/duas/duas_catalog.json`
- `assets/science/science_catalog.json`
- `assets/themes/life_themes_catalog.json`
- `assets/reflection/calendar_lenses_catalog.json`
- `assets/reflection/weekly_rotation_catalog.json`
- `assets/asma/asmaul_husna_catalog.json`
- `assets/icon/` — app icons and splash assets

---

## Setup checklist

1. Clone this repository.
2. `flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`
4. Fill `assets/` per [assets/README.md](assets/README.md) using the sources above.
5. `flutter run`

If verse import fails or the reader shows "No verses found", verify `s001.json`–`s114.json` exist and match `DataImporter.currentVersion`.

---

## Attribution in the app

Credits shown under **Settings → Sumber data** should remain accurate when you publish a build that includes fetched data.
