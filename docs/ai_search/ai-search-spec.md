# Spec: AI Search & Doa Sesuai Kebutuhan (Quran Offline)

Status: approved for implementation, phase by phase
Owner: Hendrawan (maintainer)
Executor: Cursor agent, following `.cursor/rules/ai-search.mdc`

---

## 0. How to use this spec (read first, agent)

1. Implement **one task at a time**, in the order listed. Each task has an ID (e.g. `B2`).
2. Only create or modify the files listed under the task's **Files**. If another file must change, **stop and ask**.
3. A task is done only when every **Acceptance** item passes. Run the listed commands and report output.
4. Tasks marked **GATE** require a maintainer decision. Do not start work past a gate until the maintainer writes the decision into §9 of this file.
5. If anything in this spec is ambiguous or conflicts with the code, **stop and ask**. Do not guess.
6. Do not refactor, rename, or "improve" code outside the task.

---

## 1. Goal

Make everything already inside the app easier to find and learn from:

- **Temukan di Al-Qur'an**: one natural-language search across ayat, terjemahan, tafsir, arti/tentang surat, Asmaul Husna, Doa Nabi, Sains, Tema Hidup.
- **Doa sesuai kebutuhan**: user describes a need, app returns doa that exist in the app or in the Quran, with honest labels.
- **Jelajah terkait**: from any ayat or catalog entry, show related content from the app's own data.

"AI" here means **understanding and ranking only**. It never writes content.

---

## 2. Hard rules (non-negotiable)

| # | Rule |
|---|------|
| R1 | **No generated religious text.** No LLM, no text generation, no summarisation of Quran, tafsir, or doa. Results are cards pointing at existing data. |
| R2 | **No external data.** Only files already in `assets/` (see `DATA_SOURCES.md`) plus maintainer-curated files created by this spec. |
| R3 | **No network** for any feature in this spec, at build time or runtime. |
| R4 | **Arabic is rendered only from the existing `verses` table** through existing widgets. Never copy Arabic into new catalogs or indexes for display. Follow `docs/QURAN_TEXT_INTEGRITY.md`. |
| R5 | Normalisation is for **matching only**. Never alter stored `ar`, translations, or tafsir. |
| R6 | **Every result shows its source** (e.g. `QS 2:201`, `Tafsir As-Sa'di 2:201`, `Asmaul Husna #17`). |
| R7 | **No weak matches.** Below the score threshold, show the "tidak ditemukan" empty state. Never pad results. |
| R8 | **A non-doa ayat is never labelled as doa.** Only entries in `duas_catalog.json` or approved entries in `quran_dua_ayat_catalog.json` get a doa label. |
| R9 | Sains and Tema Hidup results carry the label **"Penjelasan kurasi"** so users can tell wahyu from explanation. |
| R10 | Agent must not author religious content: need descriptions, tags, synonyms, doa decisions, eval answers are **maintainer-curated**. Agent creates schemas, loaders, validators, and empty/example files only. |
| R11 | Feature is behind `kAiSearchEnabled` until maintainer flips it. |
| R13 | Two tests are already red on `main` (`reflection_distribution_test.dart` Item C, `reflection_provider_test.dart` Item B — see `docs/followup-reflection-tests.md`). Acceptance means **no new failures beyond those two**. Never edit, skip, or "fix" them, or any reflection selector/provider/catalog, inside an AI search task. |
| R12 | All new user-facing strings exist in `id`, `en`, `zh`, `ja` via `lib/core/utils/app_localizations.dart`, matching existing patterns. |

---

## 3. Existing code to reuse (do not duplicate)

| Concern | Existing location |
|---------|-------------------|
| Verse JSON schema `{s,a,ar,tr,m}` | `tool/generate_quran_json.py`, `DATA_SOURCES.md` §1 |
| Verses DB (drift) | `lib/core/database/database.dart`, `importer.dart` |
| Arabic match normaliser | `lib/core/utils/arabic_search_normalizer.dart` |
| Translation footnote cleaner | `lib/core/utils/translation_cleaner.dart` |
| Current verse search | `lib/core/providers/enhanced_search_provider.dart`, `lib/features/search/search_screen.dart` |
| Explore catalog search | `lib/features/dua/explore_search.dart` |
| Tema hidup categories | `lib/features/dua/life_situation.dart` (`lifeSituationCategoryOrder`) |
| Catalog models | `lib/core/models/{dua,asma,science,theme}_entry.dart` (`LocalizedText`, `DuaAyahRef`) |
| Asset SQLite copy/open pattern | `lib/core/tafsir/tafsir_repository.dart` |
| Tafsir SQLite | `assets/tafsir/id_as_saadi.sqlite`, `en_ibn_kathir.sqlite` (table `tafsir`: `ayah_key`, `group_ayah_key`, `text`) |
| Surah info SQLite | `assets/quran/surah_info/{id,en}_surah_info.sqlite` (table `surah_infos`) |
| Catalog test pattern (skip if asset missing) | `test/dua_catalog_test.dart`, `test/quran_text_integrity_test.dart` |
| Python tool test pattern | `tool/test_generate_quran_json.py` (unittest) |

---

## 4. Architecture

```
BUILD TIME (maintainer machine, Python stdlib, offline)
  assets/quran/s###.json ─┐
  assets/tafsir/*.sqlite ─┤
  assets/quran/surah_info ┤
  assets/*/…_catalog.json ┤──► tool/build_search_index.py ──► assets/ai/search_index.sqlite
  assets/ai/quran_dua_ayat_catalog.json ┘                        (docs + FTS5 + links)
  data/review/dua_ayat.review.json ──► tool/extract_dua_ayat.py build ──► assets/ai/quran_dua_ayat_catalog.json

RUNTIME (device, offline)
  query ─► IdQueryNormalizer ─► FTS5 (bm25) ─┐
                             [Phase D] vector ┤─► ranker ─► threshold ─► grouped result cards
                                               └─ source refs ─► verses table renders Arabic
```

---

## 5. Data contracts

### 5.1 `assets/ai/quran_dua_ayat_catalog.json` (built by `tool/extract_dua_ayat.py build`)

```json
{
  "version": 1,
  "generatedAtUtc": "…",
  "quranManifestVersion": "…",
  "note": "References only…",
  "entries": [
    {
      "id": "qd_003_191_194",
      "surah": 3, "from": 191, "to": 194,
      "category": "forgiveness",
      "tags": ["ampunan", "akhirat"],
      "need": { "id": "…", "en": "…" },
      "recommendedToRecite": true,
      "inDuaCatalog": false,
      "duaCatalogIds": [],
      "source": "extractor"
    }
  ]
}
```
No Arabic, no translation text. `need` is used for matching, not displayed as doa text.

### 5.2 `assets/ai/search_index.sqlite` (built by `tool/build_search_index.py`)

```sql
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- keys: schema_version, built_at_utc, quran_manifest_version, normalizer_version

CREATE TABLE docs (
  doc_id     TEXT PRIMARY KEY,   -- e.g. ayah:2:201:id, tafsir:id:2:201, asma:17, dua:<id>, qdua:<id>, sci:<id>, theme:<id>, surah:2:id
  type       TEXT NOT NULL,      -- ayah | tafsir | surah_info | asma | dua | quran_dua | science | theme
  lang       TEXT NOT NULL,      -- id | en
  ref_key    TEXT NOT NULL,      -- catalog id or "s:a"
  surah      INTEGER,            -- nullable for asma without primary ref
  ayah_from  INTEGER,
  ayah_to    INTEGER,
  title      TEXT NOT NULL,      -- short label for matching, never Arabic
  body_norm  TEXT NOT NULL       -- normalised text used only for matching
);
CREATE VIRTUAL TABLE docs_fts USING fts5(title, body_norm, content='docs', content_rowid='rowid', tokenize='unicode61 remove_diacritics 2');

CREATE TABLE doc_refs (doc_id TEXT NOT NULL, surah INTEGER NOT NULL, ayah INTEGER NOT NULL);
CREATE INDEX idx_doc_refs_sa ON doc_refs(surah, ayah);
-- Jelajah terkait = docs sharing (surah, ayah). Deterministic, no similarity.
```
Display text is always loaded from the original source (verses table, tafsir SQLite, catalog JSON) by `doc_id`/`ref_key`, never from `body_norm`.

### 5.3 Maintainer-curated files (agent creates schema + empty example only)

| File | Purpose |
|------|---------|
| `assets/ai/synonyms_id.json` | `{ "version": 1, "groups": [["rezeki","rizki"], …] }` spelling variants and same-meaning Indonesian words |
| `tool/fixtures/id_normalizer_vectors.json` | `[{"in": "…", "out": "…"}]` shared by Python and Dart tests (parity) |
| `tool/eval/queries.json` | `[{"q": "…", "lang": "id", "expect": ["qdua:qd_003_191_194", "ayah:39:53:id"]}]` |

---

## 6. Search behaviour

### 6.1 Indonesian/English query normalisation (`normalizer_version = 2`)
Applied identically in `tool/build_search_index.py` and `lib/core/ai_search/id_query_normalizer.dart`:
1. Lowercase; strip HTML tags; replace non-letter/digit with space; collapse spaces.
2. Arabic script: apply `ArabicSearchNormalizer.normalizeForSearch` rules.
3. Indonesian suffix strip, in order, once each, keep stem length ≥ 3: `-nya`, `-lah`, `-kah`, `-kan`, `-an`, `-i`.
4. Indonesian prefix strip, once, keep stem length ≥ 3: `meng-`, `meny-`, `mem-`, `men-`, `me-`, `peng-`, `peny-`, `pem-`, `pen-`, `pe-`, `ber-`, `ter-`, `di-`, `ke-`, `se-`.
5. Drop stopwords after affix stripping. Indonesian: `untuk, yang, dan, di, ke, dari, dengan, kepada, pada, saat, ketika, agar, supaya, bagi, itu, ini, ada, atau, juga, akan, sudah, telah, oleh, dalam`. English: `the, a, an, of, for, to, in, on, and, or, with, when, is, are`. If every token is a stopword, keep the original tokens.
6. Synonym expansion from `synonyms_id.json` at query time only (FTS `OR` group).
Parity is proven by both test suites passing the same `id_normalizer_vectors.json`.

### 6.2 Ranking
- Phase C: FTS match is **any-term** (`OR`), ranked by `bm25`. Documents matching more terms rank higher. `score = normalised_bm25` in [0,1] per query (min-max over top 100).
- Phase D (after GATE D0): `score = 0.4 * bm25_norm + 0.6 * cosine`.
- Type boost (added, then clamp to 1.0): `quran_dua` and `dua` +0.05 when in Doa mode; otherwise none.
- Threshold constants in `lib/core/ai_search/ai_search_config.dart`: `kMinScoreKeyword = 0.25`, `kMinScoreHybrid = 0.45`, `kMaxResultsPerType = 5`. Tuned only via Phase G eval, by maintainer.

### 6.3 Doa sesuai kebutuhan: tiers
Evaluate in order; stop filling a tier once `kMaxResultsPerType` reached; show all non-empty tiers:

| Tier | Source | Label (id) |
|------|--------|------------|
| 1 | `duas_catalog.json` entries (Doa Nabi + daily) | "Doa Nabi" / category label (existing) |
| 2 | `quran_dua_ayat_catalog.json` entries with `recommendedToRecite = true`, excluding those with `inDuaCatalog = true` (already shown in tier 1) | "Doa dari Al-Qur'an" |
| 3 | `ayah` docs, only if tiers 1–2 are empty | "Ayat terkait — bukan lafaz doa" |
| 3b | `asma` docs matching the need (any tier state) | "Asmaul Husna terkait" |
| 4 | nothing above threshold | "Belum ditemukan doa untuk kebutuhan ini" + link to Doa Nabi list |

Entries with `recommendedToRecite = false` never appear in Doa mode. They may appear in general search as `ayah` results without doa label.

---

## 7. Phases and tasks

### Phase A — Doa-ayat extraction & review (script delivered)

**A1. Add extractor to repo**
- Files: `tool/extract_dua_ayat.py`, `tool/test_extract_dua_ayat.py`
- Acceptance: `python -m unittest discover -s tool -p "test_extract_dua_ayat.py"` passes (12 tests).

**A2. Run extraction on real data** (maintainer runs, agent may assist)
- Command: `python tool/extract_dua_ayat.py extract`
- Output: `data/review/dua_ayat.review.json`
- Acceptance: stats printed; spot check that 2:201, 2:286, 3:8, 14:40–41, 25:74 appear; 1:2 does not.
- Note: detection is pattern-based. Doa without `rabb`/`allahumma` (e.g. 21:87) will be missed. Maintainer adds them to `manual_additions`.

**A3. Human review** (maintainer + ustadz, no agent)
- For each group: decision, `is_doa_lafaz`, `recommended_to_recite`, `category`, `tags`, `need.id`, `need.en`, `reviewer`. Verify context with tafsir; `hints` are not decisions.
- Re-running `extract` keeps decisions (matched by `group_key`); changed groups land in `orphaned_reviews`.

**A4. Build catalog**
- Command: `python tool/extract_dua_ayat.py build` (use `--allow-pending` only for dev builds)
- Output: `assets/ai/quran_dua_ayat_catalog.json`
- Acceptance: exits 0; file has no Arabic or translation text.

**A5. Dart model + catalog test**
- Files: `lib/core/models/quran_dua_ayat_entry.dart`, `lib/core/providers/quran_dua_ayat_catalog_provider.dart`, `test/quran_dua_ayat_catalog_test.dart`, `pubspec.yaml` (add `assets/ai/quran_dua_ayat_catalog.json`)
- Follow `dua_entry.dart` / `dua_catalog_provider.dart` patterns. Reuse `DuaAyahRef` for ranges.
- Test (skip if asset missing): unique ids; ranges within surah bounds using `assets/quran/s###.json`; category in `lifeSituationCategoryOrder` or null; no Arabic codepoints `[\u0600-\u06FF]` anywhere in the file.
- Acceptance: `flutter test test/quran_dua_ayat_catalog_test.dart` passes.

### Phase B — Unified local index

**B0. GATE: FTS5 availability**
- Agent writes `test/fts5_available_test.dart` that opens an in-memory DB via the same sqlite library the app uses and runs `CREATE VIRTUAL TABLE t USING fts5(x)`.
- Maintainer runs it on a real Android device/emulator build and records result in §9. If FTS5 is unavailable, stop; maintainer decides fallback.

**B1. Shared normaliser vectors**
- Files: `tool/fixtures/id_normalizer_vectors.json` (agent adds only mechanical cases: casing, punctuation, affixes on non-religious words like `pekerjaan→kerja`, `dimakan→makan`; maintainer extends), `tool/id_normalizer.py`, `tool/test_id_normalizer.py`
- Acceptance: Python tests pass on all vectors.

**B2. Dart normaliser**
- Files: `lib/core/ai_search/id_query_normalizer.dart`, `test/id_query_normalizer_test.dart`
- Acceptance: Dart test loads the same vectors file and passes all cases.

**B3. Index builder**
- Files: `tool/build_search_index.py`, `tool/test_build_search_index.py`
- Inputs: all sources in §3; missing optional source → warning, skipped. `id` language required; `en` included for ayah/asma/dua/science/theme; `en` tafsir (Ibn Kathir) behind `--include-en-tafsir` flag, default off.
- Strip HTML from tafsir/surah info before normalising. Tafsir grouped rows (`group_ayah_key`) become one doc with range `ayah_from..ayah_to`.
- Output: `assets/ai/search_index.sqlite` per §5.2, `meta` filled.
- Acceptance: unit tests on fixtures pass; on real data prints doc counts per type and file size. **Size budget: ≤ 20 MB**, else fail with message.

**B4. Runtime index repository**
- Files: `lib/core/ai_search/search_index_repository.dart`, `lib/core/ai_search/ai_search_config.dart`, `pubspec.yaml` (add `assets/ai/search_index.sqlite`)
- Copy/open read-only following `tafsir_repository.dart`. Re-copy when `meta.built_at_utc` differs from stored pref.
- API: `Future<List<IndexHit>> keywordSearch(String query, {Set<String>? types, String lang, int limit})`, `Future<List<String>> relatedDocIds(int surah, int ayah)`.
- Acceptance: widget-free test with a fixture sqlite passes; `kAiSearchEnabled = false` by default.

### Phase C — Temukan di Al-Qur'an (keyword)

**C1. Provider**
- Files: `lib/core/providers/ai_search_provider.dart`, `test/ai_search_provider_test.dart`
- Uses normaliser + synonyms + `keywordSearch`, applies §6.2 threshold, groups by `type`, max per type.
- Acceptance: tests cover threshold empty state and grouping.

**C2. UI integration**
- Files: `lib/features/search/search_screen.dart`, `lib/features/home/home_screen.dart` (nav label only), `lib/features/search/tanya_result_layout.dart`, `lib/features/search/widgets/tanya_search_results.dart`, `lib/features/search/widgets/search_result_list.dart`, `lib/features/search/ai_search_query_kind.dart`, `lib/features/search/widgets/ai_result_card.dart`, `lib/core/providers/ai_search_provider.dart` (`aiSearchEnabledProvider` for tests), `app_localizations.dart`, `test/tanya_result_layout_test.dart`, `test/tanya_search_view_test.dart`
- Card: type label, source ref (R6), "Penjelasan kurasi" badge for science/theme (R9). Tap opens existing reader/detail sheet for that source (reuse explore detail sheet and `ReaderSource`).
- When `kAiSearchEnabled` is **false**: the screen is unchanged, including the "Semua" chip and the classic result list. Grouped keyword results are not shown.
- When `kAiSearchEnabled` is **true**:
  1. Naming (R12). Bottom nav label stays "Cari" (same as flag off). Home "Akses Cepat" tile stays "Cari". Screen header title is "Temukan di Al-Qur'an" only (no subtitle). Search-field placeholder "Cari sabar, rezeki, atau 2:255".
  2. Empty-query landing: small label "Coba:" followed by four example chips in **one** horizontally scrollable row (`sabar`, `rezeki`, `doa untuk orang tua`, `hati gelisah` — UI examples only) that fill and run the query. One line of small secondary text under the chips: "Bisa juga ketik 2:255, juz 30, halaman 5, atau teks Arab." No landing card, no "Atau cari lebih spesifik" heading, and no Surah/Juz/Halaman/Ayat/Terjemahan/Teks Arab ayat cards (those browse paths already exist on the Baca tab). Generous whitespace otherwise.
  3. Results do **not** show type-filter chips. Query type is detected from the existing classic parser in `enhanced_search_provider.dart` (not rewritten):
     - Reference queries (N:N, "juz N", page matches the parser already accepts, surah name or number) → group "Langsung ke" with a single direct classic result.
     - Arabic-script queries → group "Teks Arab" using the existing Arabic search.
     - Otherwise → grouped keyword results: Ayat, then Tafsir, then remaining groups (Doa Nabi, Doa dari Al-Qur'an, Asmaul Husna, Tema Hidup, Sains, Tentang Surat) sorted by each group's best hit score, highest first. Tie-break in that listed order. Groups with no hits are hidden. Max 3 cards per group; "Lihat semua" expands that group to `kMaxResultsPerType`.
  4. "Hasil terjemahan (N)" is a **single row** that opens a full list screen of classic translation results (reuse `SearchResultList`). Do not render classic translation hits inside the grouped view.
  5. Empty state (R7) when no grouped hits: "Belum ditemukan". Button "Lihat hasil terjemahan" opens that same list when classic search has translation results; otherwise no button.
- Acceptance: widget tests for flag-on/off naming, landing layout (no subtitle, chips in one row, hint line, no cards), no chip row on results, each query type routing to the right group, translation list screen, empty-state button, fixed Ayat-then-Tafsir order, score-sorted remaining groups with tie-break, hidden empty groups, 3-card cap + Lihat semua, and flag-off unchanged behaviour. Existing search tests still pass.

### Phase D — Semantic search

**D0. GATE: model & runtime** (maintainer decides, records in §9)
- Embedding model (multilingual, Indonesian quality), quantisation, on-device runtime package, delivery (bundled vs Play on-demand asset pack), dims.
- Benchmark on `tool/eval/queries.json` before choosing.

**D1–D4** are written by the maintainer into this spec after D0. Agent must not start Phase D without them.

### Phase E — Doa sesuai kebutuhan

**E1. Doa resolver**
- Files: `lib/core/ai_search/doa_need_resolver.dart`, `test/doa_need_resolver_test.dart`
- Implements §6.3 exactly over `keywordSearch` (types `dua`, `quran_dua`, `ayah`, `asma`) + catalogs.
- Acceptance: tests for every tier, for `recommendedToRecite=false` exclusion, for tier-1/tier-2 dedupe, and that tier 3 only appears when tiers 1–2 are empty.

**E2. Screen**
- Files: `lib/features/dua/doa_need_screen.dart`, entry point in `lib/features/dua/dua_screen.dart` (single button/search field, flag-guarded), `app_localizations.dart`
- Tier headers use labels from §6.3. Arabic via existing verse rendering widgets only (R4).
- Acceptance: widget test renders each tier label; no Arabic string literals in new Dart files.

### Phase F — Jelajah terkait

**F1.** Files: `lib/features/reader/widgets/related_content_sheet.dart`, hook in reader ayat actions (flag-guarded), `app_localizations.dart`
- Uses `relatedDocIds(surah, ayah)` only (shared refs, deterministic). Groups by type, same card as C2.
- Acceptance: widget test with fixture index.

### Phase G — Evaluation

**G1.** Files: `tool/eval_search.py`, `tool/eval/queries.json` (empty example; maintainer fills ≥ 200 queries)
- Mirrors §6.1/§6.2 in Python against `search_index.sqlite`; reports recall@5, MRR, empty-state rate, per type.
- Acceptance: runs on example file; maintainer uses results to tune thresholds and flip `kAiSearchEnabled`.

---

## 8. Out of scope

LLMs or any text generation · cloud APIs · user accounts or telemetry of queries · personal/free-form doa composition · new translations or tafsir · changing existing catalog schemas · tajweed colouring · any change to `s###.json` generation.

---

## 9. Decisions log (maintainer fills)

| Gate | Date | Decision |
|------|------|----------|
| B0 FTS5 on device | 2026-09-21 | FTS5 available on Android (sqlite 3.51.1), verified on Pixel 8 Pro |
| D0 model/runtime/delivery | 2026-09-21 | deferred to post-1.x release; keyword FTS5 search only for this release |
| Thresholds after G1 | | |
| Enable `kAiSearchEnabled` | | |
