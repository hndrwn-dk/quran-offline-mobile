# Tajwid coloring on Reader and Juz

Status: design only. Not implemented.

Date: 2026-10-06

Related: [docs/QURAN_TEXT_INTEGRITY.md](../../QURAN_TEXT_INTEGRITY.md), [DATA_SOURCES.md](../../../DATA_SOURCES.md)

## Goal

Optional colored tajwid on **Reader and Juz** Arabic, using the **current Digital Khatt V2** face and the **same** Uthmani `ar` string already on screen. Default off. Mushaf unchanged.

Success:

- With the toggle off, Arabic is identical to today (one Digital Khatt string, `onSurface`).
- With the toggle on, letters that have a trusted rule show a distinct color; letters without a rule stay `onSurface`.
- Concatenation of painted substrings equals `ar` exactly. No U+25CC. No U+0672 introduced into display.
- Share cards stay uncolored plain `ar`.

## Current surface

Reader and Juz are one list: `ReaderScreen` (`JuzSource` / `SurahInJuzSource` / surah) builds `AyahCard`.

`AyahCard._buildPlainArabicText` uses `QuranArabicText` as a single `SelectableText` of `verse.arabic`.

| Piece | Today |
|-------|--------|
| Font | `DigitalKhattV2` (`assets/fonts/DigitalKhattV2.otf`, QUL #247). Unicode OpenType, not COLR. Color is Flutter `TextStyle.color`. |
| Text | Quran Foundation `text_uthmani` in JSON `ar`. Codepoint-for-codepoint. |
| Size | `arabicFontSize` (16–48, default 30), Reader applies `* 1.15`. No user font-family switch. |
| Highlights | Whole-card chrome (audio / user highlight). No per-letter spans. |
| Latin | QUL `transliteration-tajweed.db` — pronunciation, not Arabic color. |
| Mushaf | QPC V2 page fonts, monochrome. Out of scope. |

`QuranArabicText` contract: no letter rewriting, no span coalescing, no sukun substitution.

## Why Quran.com HTML is not the displayed text

`text_uthmani_tajweed` is a different character lineage than `ar`. Example 1:6: `ar` has U+0670; tajweed HTML has U+0672. Overlaying stripped HTML onto `ar` produced dotted circles and wrong letters.

`tool/generate_quran_json.py` rejects `text_uthmani_tajweed`. `VerseModel` has no `tj`. Drift schema v6 dropped `verses.tajweed`. Do not restore either.

Integrity tests (`test/quran_text_integrity_test.dart`) forbid U+25CC and U+0672 in bundled `ar`.

## Decision: sidecar ranges, not HTML in JSON

Keep `ar` as the only Arabic source of truth. Color is a separate index into that string.

Rejected:

- Displaying QF HTML as the on-screen Arabic.
- Putting `tj` back into `s###.json` or SQLite.
- Runtime-only rule engine as the primary dataset (incomplete madd/ikhfa; allowed only as a later fallback for unaligned ayahs).
- Coloring Mushaf QPC V2 glyphs.
- Coloring Latin instead of Arabic.

## Data

### Sidecar (canonical, gitignored like other bundled data)

Path (proposed):

- Canonical: `data/bundled/quran/tajweed/tajweed_spans.json` (or per-surah `tajweed/s001.json` if one file is too large)
- Sync: `assets/quran/tajweed/` via `qo sync`
- Verify: add to the `qo` required-file list (today 738 files)

Not committed. Not merged into `s###.json`.

### Record shape

Per ayah:

```json
{
  "s": 2,
  "a": 2,
  "arHash": "<sha256 of exact ar string>",
  "spans": [
    { "start": 3, "end": 5, "rule": "ghunnah" }
  ]
}
```

- `start` / `end` are Unicode **extended grapheme cluster** indices into that ayah’s `ar` (half-open `[start, end)`).
- A cluster is a base letter plus following combining marks. Waqf/saktah (U+06D6–U+06DC) plus the following space they attach to (Digital Khatt GPOS) is one cluster and must not be split.
- `arHash` must match the imported `ar`. Mismatch → ignore spans, paint plain.
- Missing ayah → paint plain. Never rewrite `ar` to force a match.

### Build-time alignment

QF `text_uthmani_tajweed` HTML is a **hint only**.

1. Fetch HTML (local leftover `scripts/fetch_tajweed_data.py` may help; output must not land in verse JSON).
2. Strip tags. Align stripped text to `ar` (LCS / token aligner). Extend `tool/audit_tj_ar.py` from report-only to emit ranges or skip.
3. Map CSS classes onto `rule` ids. Drop any alignment that would display U+0672 or change letters.
4. If alignment is not 1:1 on letters (tatweel-only differences may be skipped in the hint stream, not inserted into `ar`), omit that ayah.

Coverage may be less than 6236 ayahs. Incomplete coverage is acceptable; wrong letters are not.

### Rule ids (v1)

Stable ids used in sidecar and theme:

| id | Meaning |
|----|---------|
| `ghunnah` | Ghunnah |
| `idgham` | Idgham |
| `ikhfa` | Ikhfa |
| `iqlab` | Iqlab |
| `qalqalah` | Qalqalah |
| `madd` | Madd (collapse madda_normal / permissible / necessary for v1 legend) |
| `ham_wasl` | Hamzat al-wasl |
| `laam_shamsiyah` | Lam shamsiyah |

Unknown ids in the sidecar are ignored (paint `onSurface`).

v1 may ship a subset if alignment is weak for some classes. Legend only lists rules that actually appear in the sidecar.

## Rendering

Font stays `DigitalKhattV2` with the same fallbacks, size, height `1.7`, `locale: ar`, RTL.

When the toggle is on and spans are valid:

- `QuranArabicText` optional rich path: `SelectableText.rich` / `Text.rich`.
- Adjacent `TextSpan`s share font, size, height, locale. **Only `color` differs.** No fontWeight, letterSpacing, or backgroundColor on letter spans (those break Arabic joining).
- Span texts concatenated in order equal `ar`.
- Clusters with no rule use `colorScheme.onSurface`.

When the toggle is off, spans missing, or `arHash` fails: current single-style `SelectableText`.

Bismillah block: same toggle if a sidecar row exists for that string; otherwise plain.

### Theme

Map `rule` → semantic colors via theme tokens / `ColorScheme` tints. No raw hex in widgets. Same roles in Light and Forest; contrast must hold on both.

## UI

- Setting: boolean, persisted, **default false**. Place with Reader text settings (`TextSettingsDialog`), not Mushaf settings.
- When on: compact legend under the first visible ayah or in the text-settings sheet (ghunnah, idgham, ikhfa, iqlab, qalqalah, madd — plus extras if present).
- Share PNG / share text: always plain `ar`.
- Explore sheets that reuse `QuranArabicText`: follow the same toggle if they show a full ayah; do not special-case Mushaf.

## Integrity constraints (non-negotiable)

1. Do not rewrite `ar` (no sukun U+0652 → U+06E1, no U+0670 → U+0672).
2. Do not display QF HTML as Arabic.
3. Do not restore `verses.tajweed` or JSON `tj`.
4. Do not split a base letter from harakat; do not split waqf-mark + attaching space.
5. Do not color QPC V2 Mushaf pages in this feature.

## Tests (when implemented)

- Concatenation of rich spans equals `ar` for every ayah that has sidecar rows.
- `arHash` mismatch paints plain.
- Corpus still has no U+25CC / U+0672 in `ar`.
- Goldens: 1:1, 1:6 (must keep U+0670), 2:1.
- Joining smoke: lam-alif and shadda+haraka with a color change on a neighboring letter.
- Toggle off: widget tree uses the single-style path.

## Docs to update at implementation time

- [docs/QURAN_TEXT_INTEGRITY.md](../../QURAN_TEXT_INTEGRITY.md) — colored display is sidecar-on-`ar`, not QF HTML overlay; span split is color-only and cluster-safe.
- [DATA_SOURCES.md](../../../DATA_SOURCES.md) — sidecar path, license/source of the hint HTML, still “HTML is not imported into verse JSON”.
- `qo` verify count when the sidecar is added.

## Out of scope

Mushaf QPC V2 coloring, changing the Reader Arabic font, putting tajweed HTML in verse JSON, rewriting sukun, making Latin coloring a substitute for Arabic coloring, hafalan scoring changes.
