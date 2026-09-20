# Cursor prompts — AI Search & Doa Sesuai Kebutuhan

Copy one block per Cursor session (Agent mode). Do not merge two tasks into one prompt.
Spec: `docs/ai_search/ai-search-spec.md`. Rules: `.cursor/rules/ai-search.mdc`.

---

## Branch plan

```
main
└── feat/ai-search                 ← integration branch for the whole feature
    ├── feat/ai-search-phase-a     ← A1–A5   doa-ayat extraction, catalog, model
    ├── feat/ai-search-phase-b     ← B0–B4   normaliser + unified index
    ├── feat/ai-search-phase-c     ← C1–C2   Tanya Al-Qur'an (keyword)
    ├── feat/ai-search-phase-e     ← E1–E2   Doa sesuai kebutuhan
    ├── feat/ai-search-phase-f     ← F1      Jelajah terkait
    └── feat/ai-search-phase-g     ← G1      evaluation
```

You (not Cursor) create, merge, and push branches. Cursor only commits on the branch it finds checked out.

```bash
git checkout main && git pull
git checkout -b feat/ai-search
git checkout -b feat/ai-search-phase-a          # per phase
# after a phase is accepted:
git checkout feat/ai-search && git merge --no-ff feat/ai-search-phase-a
```

Nothing merges into `main` until Phase G is done and `kAiSearchEnabled` is flipped.

---

## What is gitignored in this repo (important)

- `data/` is ignored → `data/review/dua_ayat.review.json` (your doa review decisions) is **not** in git. Back it up yourself; it is hours of scholar review.
- `docs/*` is ignored except `QURAN_TEXT_INTEGRITY.md` → the spec and this prompt file need a `.gitignore` exception (task A0).
- Generated assets stay out of git, matching how `assets/duas/*.json` is handled today.

---

## Known-red tests (read before any task)

Two tests fail on `main` already, documented in `docs/followup-reflection-tests.md`:

| Test | Failure | Item |
|------|---------|------|
| `test/reflection_distribution_test.dart` | Friday lens count 36 vs expected >= 45 | C |
| `test/reflection_provider_test.dart` | flaky calendar-entry assertion (~4/10) | B |

Acceptance in every task below means **no new failures beyond these two**. Capture a baseline
before starting so "new" is measurable:

```powershell
flutter test --reporter compact 2>&1 |
  Select-String -Pattern "\[E\]|Some tests failed|All tests passed" |
  Out-File ..\test-baseline-before-ai-search.txt
```

Cursor must never touch those tests or the reflection selector/provider/catalogs (rules 18-19).

---

## Session 0 — kickoff (run once per new Cursor chat)

```
Read docs/ai_search/ai-search-spec.md and .cursor/rules/ai-search.mdc in full before doing anything.
Then reply with:
1. the hard rules R1–R13 in one line each, in your own words,
2. the task IDs in order and which ones are GATEs,
3. the current branch (run: git rev-parse --abbrev-ref HEAD),
4. the two known-red tests from rule 18, and what "acceptance passes" means given them.
Do not write or modify any file in this reply.
```

---

## A0 — branch hygiene and .gitignore exceptions

```
Task A0 (not in the spec; setup only).

Preconditions: run `git rev-parse --abbrev-ref HEAD`. If it is `main`, stop and tell me to create the branch.

Do exactly this:
1. Update .gitignore so the spec and prompt files are trackable, keeping the existing "docs/* ignored" intent:
   - after the existing `!docs/QURAN_TEXT_INTEGRITY.md` line, add `!docs/ai_search/` and `!docs/ai_search/**`
2. Add generated AI assets to .gitignore, following the existing assets pattern:
   - `assets/ai/*`
   - `!assets/ai/.gitkeep`
   and create empty `assets/ai/.gitkeep`
3. Run `git status --short` and confirm docs/ai_search/*.md and .cursor/rules/ai-search.mdc are now trackable and that nothing under data/ or assets/ai/ except .gitkeep is staged.

Files you may touch: .gitignore, assets/ai/.gitkeep
Commit: `chore(ai-search): A0 track spec files, ignore generated ai assets`
```

---

## A1 — extractor into the repo

```
Task A1 from docs/ai_search/ai-search-spec.md.

tool/extract_dua_ayat.py and tool/test_extract_dua_ayat.py are already in the working tree.
Do not rewrite them. Verify only:
1. `python -m unittest discover -s tool -p "test_extract_dua_ayat.py" -v` → all 12 tests pass. Paste the output.
2. Confirm the script makes no network calls and imports stdlib only.
3. Confirm the normalisation rules in extract_dua_ayat.py match lib/core/utils/arabic_search_normalizer.dart and lib/core/utils/translation_cleaner.dart. Report any drift; do NOT change either side without asking me.

Files you may touch: none unless a test fails (then only the two files above).
Commit: `feat(ai-search): A1 add Quranic doa-ayat extractor and tests`
```

**A2–A4 are mine, not Cursor's** (they need real assets and scholar review):

```bash
python tool/extract_dua_ayat.py extract     # → data/review/dua_ayat.review.json
# review with an ustadz, then:
python tool/extract_dua_ayat.py build       # → assets/ai/quran_dua_ayat_catalog.json
Copy-Item data\review\dua_ayat.review.json C:\Users\hendr\Backup\   # data/ is gitignored
```

---

## A5 — Dart model, provider, catalog test

```
Task A5 from docs/ai_search/ai-search-spec.md §7 Phase A.

Build the Dart side of assets/ai/quran_dua_ayat_catalog.json (schema in spec §5.1):
- lib/core/models/quran_dua_ayat_entry.dart — follow the style of lib/core/models/dua_entry.dart; reuse DuaAyahRef if it fits; `need` is {id,en} only, not LocalizedText.
- lib/core/providers/quran_dua_ayat_catalog_provider.dart — follow lib/core/providers/dua_catalog_provider.dart exactly (same loading and caching approach).
- test/quran_dua_ayat_catalog_test.dart — follow test/dua_catalog_test.dart, including the skip-if-asset-missing behaviour used in test/quran_text_integrity_test.dart. Assert: unique ids; every range within surah bounds read from assets/quran/s###.json; category is null or in lifeSituationCategoryOrder from lib/features/dua/life_situation.dart; the catalog file contains no codepoint in [\u0600-\u06FF] (rule R4).
- pubspec.yaml — add `assets/ai/quran_dua_ayat_catalog.json` to the assets list only.

Acceptance: `flutter test test/quran_dua_ayat_catalog_test.dart` passes (or skips cleanly if the asset is absent), and `flutter analyze` is clean for the new files. Paste both outputs.

Files you may touch: the four listed above. Nothing else.
Commit: `feat(ai-search): A5 add quran dua ayat catalog model, provider and test`
```

---

## B0 — GATE: FTS5 on device

```
Task B0 from docs/ai_search/ai-search-spec.md — GATE. Write the probe only; do not start B1.

Create test/fts5_available_test.dart that opens a database through the same sqlite stack the app already uses (see lib/core/database/database.dart and lib/core/tafsir/tafsir_repository.dart) and executes:
  CREATE VIRTUAL TABLE fts_probe USING fts5(x);
  INSERT INTO fts_probe(x) VALUES ('rezeki');
  SELECT count(*) FROM fts_probe WHERE fts_probe MATCH 'rezeki';
The test must fail with a clear message if FTS5 is unavailable.

Then tell me the exact command to run it on a real Android device/emulator. Do not edit docs/ai_search/ai-search-spec.md §9 — I record the gate result myself.

Files you may touch: test/fts5_available_test.dart
Commit: `test(ai-search): B0 probe fts5 availability on device`
```

---

## B1 — Python normaliser + shared vectors

```
Task B1 from docs/ai_search/ai-search-spec.md, implementing §6.1 exactly (steps 1–4; synonyms are query-time only and NOT part of this task).

- tool/id_normalizer.py — stdlib only, function `normalize(text: str) -> str`, plus `NORMALIZER_VERSION = 1`. Arabic input follows the same rules as lib/core/utils/arabic_search_normalizer.dart.
- tool/fixtures/id_normalizer_vectors.json — list of {"in","out"} cases. Add MECHANICAL cases only: casing, punctuation, whitespace, digits, and affixes on ordinary words (pekerjaan→kerja, dimakan→makan, sabarlah→sabar, kesabaran→sabar, bukunya→buku). No religious phrasing, no synonyms — I add those.
- tool/test_id_normalizer.py — unittest, drives every vector from the fixtures file, plus edge cases (empty string, min stem length 3, prefix+suffix together).

Acceptance: `python -m unittest discover -s tool -p "test_id_normalizer.py" -v` passes. Paste output and the final vectors file.

Files you may touch: the three listed above.
Commit: `feat(ai-search): B1 add indonesian query normaliser and shared vectors`
```

---

## B2 — Dart normaliser (parity)

```
Task B2 from docs/ai_search/ai-search-spec.md.

- lib/core/ai_search/id_query_normalizer.dart — port tool/id_normalizer.py rule for rule, same order, same stem-length guard, same normalizerVersion constant. Reuse ArabicSearchNormalizer for Arabic input instead of reimplementing it.
- test/id_query_normalizer_test.dart — load tool/fixtures/id_normalizer_vectors.json from disk (like test/dua_catalog_test.dart reads assets) and assert every case, so Python and Dart cannot drift.

Acceptance: `flutter test test/id_query_normalizer_test.dart` passes with the same vector count as the Python suite. Paste output.
If any vector cannot pass in Dart, STOP and report which one — do not edit the vectors file to make the test pass.

Files you may touch: the two listed above.
Commit: `feat(ai-search): B2 add dart query normaliser with python parity test`
```

---

## B3 — index builder

```
Task B3 from docs/ai_search/ai-search-spec.md. Schema is §5.2 — follow it exactly, including table and column names.

Create tool/build_search_index.py (stdlib + sqlite3 only, no network) and tool/test_build_search_index.py.

Inputs, all local and all optional except the first:
- assets/quran/s###.json → type `ayah`, langs id and en (clean translations with the same logic as lib/core/utils/translation_cleaner.dart)
- assets/tafsir/id_as_saadi.sqlite → type `tafsir`, lang id (table `tafsir`: ayah_key, group_ayah_key, text; strip HTML; grouped rows become one doc spanning ayah_from..ayah_to)
- assets/tafsir/en_ibn_kathir.sqlite → same, only with --include-en-tafsir (default off)
- assets/quran/surah_info/{id,en}_surah_info.sqlite → type `surah_info` (table `surah_infos`)
- assets/duas/duas_catalog.json → `dua`; assets/asma/asmaul_husna_catalog.json → `asma`; assets/science/science_catalog.json → `science`; assets/themes/life_themes_catalog.json → `theme`; assets/ai/quran_dua_ayat_catalog.json → `quran_dua`
Missing optional input → warn and skip. body_norm uses tool/id_normalizer.py. doc_refs gets one row per (doc, surah, ayah) covered.

Output assets/ai/search_index.sqlite with meta filled (schema_version, built_at_utc, quran_manifest_version from assets/quran/manifest_multi.json, normalizer_version).
Print doc counts per type and final file size. Fail with a clear message if the file exceeds 20 MB (spec §7 B3).

Tests run on small fixtures created in a temp dir — never on real assets.
Acceptance: `python -m unittest discover -s tool -p "test_build_search_index.py" -v` passes. Paste output.

Files you may touch: tool/build_search_index.py, tool/test_build_search_index.py
Commit: `feat(ai-search): B3 build unified offline search index`
```

---

## B4 — runtime index repository

```
Task B4 from docs/ai_search/ai-search-spec.md.

- lib/core/ai_search/ai_search_config.dart — kAiSearchEnabled = false, kMinScoreKeyword = 0.25, kMinScoreHybrid = 0.45, kMaxResultsPerType = 5, index asset path, bundle version key.
- lib/core/ai_search/search_index_repository.dart — copy the asset to the documents dir and open it READ-ONLY, following lib/core/tafsir/tafsir_repository.dart (including its re-copy-on-version-change approach, keyed on meta.built_at_utc). API per spec §7 B4: keywordSearch(...) and relatedDocIds(surah, ayah). Return refs and scores only; never text for display.
- test/search_index_repository_test.dart — build a small fixture sqlite in the test, assert ranking order, type filtering, limit, and that relatedDocIds returns docs sharing an ayah.
- pubspec.yaml — add assets/ai/search_index.sqlite to the assets list only.

Acceptance: `flutter test test/search_index_repository_test.dart` passes and `flutter analyze` is clean for new files. Paste both.

Files you may touch: the four listed above.
Commit: `feat(ai-search): B4 add offline search index repository`
```

---

## C1 — search provider

```
Task C1 from docs/ai_search/ai-search-spec.md, ranking per §6.2 (keyword formula only; hybrid comes after GATE D0).

- lib/core/providers/ai_search_provider.dart — normalise the query (B2), expand synonyms from assets/ai/synonyms_id.json if present (absent file = no expansion, never an error), call keywordSearch, drop anything below kMinScoreKeyword, group by type, cap at kMaxResultsPerType, keep source refs for every hit. Follow the Riverpod style of lib/core/providers/enhanced_search_provider.dart, including its debounce and stale-query guard.
- assets/ai/synonyms_id.json — create with {"version":1,"groups":[]} and ONE example group of pure spelling variants. I fill the rest.
- test/ai_search_provider_test.dart — cover: below-threshold query returns empty (rule R7), grouping and per-type cap, missing synonyms file, stale query discarded.

Acceptance: `flutter test test/ai_search_provider_test.dart` passes. Paste output.

Files you may touch: the three listed above, plus pubspec.yaml for the synonyms asset only.
Commit: `feat(ai-search): C1 add keyword ai search provider`
```

---

## C2 — search UI

```
Task C2 from docs/ai_search/ai-search-spec.md.

- lib/features/search/widgets/ai_result_card.dart — one card per hit: type label, title from the ORIGINAL source (verses table, tafsir db, or catalog — never body_norm), source reference (rule R6), "Penjelasan kurasi" badge for science and theme (rule R9). Tapping opens the existing destination: ReaderSource for ayat, the existing explore detail sheet for catalog entries.
- lib/features/search/search_screen.dart — render a grouped "Tanya Al-Qur'an" section BELOW the existing results, only when kAiSearchEnabled is true. Existing verse/surah/juz/page search behaviour must not change.
- lib/core/utils/app_localizations.dart — add every new string in id, en, zh, ja following the existing pattern (rule R12).
- test/ai_result_card_test.dart — widget test for labels, source ref, and the kurasi badge.

Acceptance: `flutter test` shows NO NEW failures beyond the two known ones listed in rule 18 of .cursor/rules/ai-search.mdc, existing search tests still pass, and `flutter analyze` is clean. Paste both.

Files you may touch: the four listed above.
Commit: `feat(ai-search): C2 add tanya al-quran results section`
```

---

## E1 — doa resolver

```
Task E1 from docs/ai_search/ai-search-spec.md, implementing the tier table in §6.3 EXACTLY.

- lib/core/ai_search/doa_need_resolver.dart — input: need text + lang. Query types dua, quran_dua, ayah, asma. Tier 1 duas_catalog entries; tier 2 quran_dua entries with recommendedToRecite == true and inDuaCatalog == false; tier 3 ayah hits ONLY when tiers 1 and 2 are both empty; tier 3b asma hits always; tier 4 empty state. Return a typed result carrying the tier, so the UI cannot mislabel anything (rule R8).
- test/doa_need_resolver_test.dart — one test per tier, plus: recommendedToRecite == false never appears, tier 1/tier 2 dedupe by inDuaCatalog, tier 3 suppressed when tier 1 or 2 has results, everything below threshold gives the empty state.

Acceptance: `flutter test test/doa_need_resolver_test.dart` passes. Paste output.

Files you may touch: the two listed above.
Commit: `feat(ai-search): E1 add doa-by-need tier resolver`
```

---

## E2 — doa screen

```
Task E2 from docs/ai_search/ai-search-spec.md.

- lib/features/dua/doa_need_screen.dart — a single input ("Apa yang sedang Anda butuhkan?") and tiered results using the E1 resolver and the C2 card. Tier headers exactly as in spec §6.3, including "Ayat terkait — bukan lafaz doa" for tier 3. Arabic renders only through the existing verse widgets (rule R4).
- lib/features/dua/dua_screen.dart — add ONE flag-guarded entry point. Do not restructure the screen.
- lib/core/utils/app_localizations.dart — new strings in all four languages.
- test/doa_need_screen_test.dart — widget test asserting each tier header renders and that no Arabic literal exists in the new Dart files.

Acceptance: `flutter test` shows NO NEW failures beyond the two known ones (rule 18); `flutter analyze` clean. Paste both.

Files you may touch: the four listed above.
Commit: `feat(ai-search): E2 add doa sesuai kebutuhan screen`
```

---

## F1 — jelajah terkait

```
Task F1 from docs/ai_search/ai-search-spec.md.

- lib/features/reader/widgets/related_content_sheet.dart — from an ayat, call relatedDocIds(surah, ayah) (shared refs only, deterministic — no similarity), group by type, reuse the C2 card.
- hook it into the existing ayat action menu in the reader, flag-guarded, without changing existing actions.
- lib/core/utils/app_localizations.dart — new strings in four languages.
- test/related_content_sheet_test.dart — widget test with a fixture index.

Acceptance: `flutter test` shows NO NEW failures beyond the two known ones (rule 18); `flutter analyze` clean. Paste both.

Files you may touch: the four listed above plus the single reader file holding the ayat actions — name it in your reply before editing.
Commit: `feat(ai-search): F1 add related content sheet`
```

---

## G1 — evaluation harness

```
Task G1 from docs/ai_search/ai-search-spec.md.

- tool/eval_search.py — stdlib + sqlite3. Mirrors §6.1 normalisation and §6.2 keyword ranking against assets/ai/search_index.sqlite, reads tool/eval/queries.json, reports recall@5, MRR, empty-state rate, and a per-type breakdown, plus a list of the worst misses so I can tune thresholds.
- tool/eval/queries.json — create with the schema from spec §5.3 and 3 clearly-marked EXAMPLE entries using mechanical queries only (e.g. "surah 36", "ayat kursi"). I write the real 200 queries.
- tool/test_eval_search.py — unittest over a fixture index verifying the metric maths (a known ranking gives a known recall/MRR).

Acceptance: `python -m unittest discover -s tool -p "test_eval_search.py" -v` passes, and `python tool/eval_search.py` runs on the example file. Paste both.

Files you may touch: the three listed above.
Commit: `feat(ai-search): G1 add offline search evaluation harness`
```

---

## Handy correction prompts

```
Stop. You touched files outside the task. Revert everything not listed under <TASK_ID> in docs/ai_search/ai-search-spec.md, keep the rest, and show me `git status --short`.
```

```
You are about to generate religious text, which rule R10 forbids. Replace it with an empty schema plus one mechanical example and tell me exactly which fields I need to fill.
```

```
Before continuing: print the current branch, `git status --short`, and `git log --oneline -3`. If the branch is main, stop.
```

---

## Optional — log the Friday lens finding as Item C

Run this once, on a branch that is NOT an AI search branch, before starting Phase A.

```
Append a new section "Item C — Friday lens count" to docs/followup-reflection-tests.md,
matching the existing style of Items A and B.

Record, as documentation only:
- Symptom: test/reflection_distribution_test.dart line ~320 expects fridayKahf + fridayShalat >= 45
  over 52 simulated Fridays; actual is 36 (jumat_kahf=18, jumat_shalat=18, other=16).
- It surfaced only after the Item A range was corrected, which was masking it.
- Open product question: should a Friday lens always win on Fridays unless a higher occasion
  tier (Ramadan, Muharram, Laylat) claims the day? If yes, the target is ~46-47 of 52 and the
  selector's tier priority needs investigation. If Fridays are meant to stay varied, the
  assertion should move to >= 35 with a comment.
- Status: documented only, not fixed, out of scope for the AI search feature.

Do NOT change any test, any file under lib/, or any assertion. Documentation only.
Then paste git status --short.
```

Commit: `docs: log Item C friday lens count follow-up`
