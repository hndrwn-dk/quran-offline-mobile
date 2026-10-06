# Tajwid coloring on Reader and Juz

Status: design only. Not implemented.

Date: 2026-10-06

Related: [docs/QURAN_TEXT_INTEGRITY.md](../../QURAN_TEXT_INTEGRITY.md), [DATA_SOURCES.md](../../../DATA_SOURCES.md)

## Goal

Optional colored tajwid on **Reader and Juz** using **the Arabic font already on that surface** (`DigitalKhattV2`) and the **same** Uthmani `ar` string already on screen. Default off. Mushaf unchanged.

Success:

- Toggle off: Arabic is identical to today (one Digital Khatt string, `onSurface`).
- Toggle on: letters that match a Hafs rule show a distinct color; others stay `onSurface`.
- Painted substring concatenation equals `ar` exactly. Harakat stay attached. No dotted circles. No missing or cut glyphs.
- Share cards stay uncolored plain `ar`.

## Current surface (do not change the face)

Reader and Juz share `AyahCard` → `QuranArabicText` as a single `SelectableText` of `verse.arabic`.

| Piece | Today — keep this |
|-------|-------------------|
| Font | **DigitalKhattV2** (`assets/fonts/DigitalKhattV2.otf`, QUL #247). Unicode OpenType. Not a color font. |
| Text | Bundled JSON `ar` (Uthmani Hafs). Codepoint-for-codepoint. |
| Size | `arabicFontSize` (16–48, default 30), Reader `* 1.15`. No family picker. |
| Latin | QUL `transliteration-tajweed.db` stays Latin-only. Not the Arabic color source. |
| Mushaf | QPC V2 page fonts, monochrome. Out of scope. |

Do not switch Reader to Uthmanic, KFGQPC, Scheherazade, or QPC page fonts for this feature.

## Why A, not B or C (old tajwid experience)

The old feature failed in **two** ways. They are not the same bug.

1. **Second Arabic string** — coloring data that was not our `ar` (different letters, U+0670 vs another alef, tatweel-only HTML) forced rewrite or overlay. Result: dotted circles and wrong letters.
2. **Flutter span split** — even with the right letters, `TextSpan` boundaries between a letter and its harakat (or madda `ـٰ`) made marks vanish or clip. That is the Digital Khatt + rich-text issue, not “wrong font.”

| Option | Rule source | Second corpus? | Fit to current Reader font (`DigitalKhattV2` + `ar`) |
|--------|-------------|----------------|------------------------------------------------------|
| **A — Hafs rules on `ar`** | Scholarly Hafs ‘an ‘Asim table, generated from the string we already paint | No | Best. Indices cannot drift. Renderer only has to keep clusters whole. |
| **B — QUL Unicode tajwid export** | QUL annotation tool / Digital Khatt script | Yes, unless QUL text **equals** our QF `ar` byte-for-byte | Risky. QUL Digital Khatt script is not proven identical to JSON `ar`. Alignment is the old overlay bug again. |
| **C — King Fahd / QPC coloring** | Madinah mushaf color convention | Yes if taken from QPC V4 glyphs | Wrong surface. QPC V4 is page fonts (QUL has even disabled V4 pending proofread). Reader does not use those glyphs. Taxonomy of rules can inform **A**; the font path must not. |

**Pick A.** Same Digital Khatt face, same `ar`. Colors from theme tokens. Rendering must be cluster-safe color-only spans (or word-level fallback) so harakat do not drop — that fix is required for A, B, or C.

B is only worth revisiting if a QUL dump is hashed equal to our `ar` per ayah. C’s rule *names* can be copied into A’s table; C’s glyphs must not be.

**Source of which letter gets which rule:** standard **Hafs ‘an ‘Asim** tajwid as taught for the Madinah Hafs mushaf (noon/mim sakinah, tanween, qalqalah letters ق ط ب ج د, madd, ghunnah on shadda ن/م, lam shamsiyah/qamariyah, hamzat al-wasl). Apply those rules **to our existing `ar`**.

The sidecar is **generated from `ar`**. Indices always refer to that string. There is no second Arabic corpus.

**Not used as a data source (do not revive):**

- Quran Foundation / Quran.com colored HTML as a coloring dataset
- JSON `tj` / SQLite `verses.tajweed`
- QPC V4 tajweed page fonts (wrong script; glyph-based, not Digital Khatt)
- QUL Latin `transliteration-tajweed.db` as Arabic color

QUL Digital Khatt remains the **font**. QUL Latin tajweed remains **transliteration**. Neither is the Arabic color table.

v1 rule set (applied to `ar`):

| id | Trigger on `ar` (Hafs) |
|----|------------------------|
| `izhar` | Noon sakinah / tanween before throat letters |
| `idgham` | Noon sakinah / tanween before يرملون (with/without ghunnah as sub-id if needed) |
| `iqlab` | Noon sakinah / tanween before ب |
| `ikhfa` | Noon sakinah / tanween before remaining letters |
| `ikhfa_shafawi` | Mim sakinah before ب |
| `idgham_shafawi` | Mim sakinah before م |
| `qalqalah` | ق ط ب ج د with sukun (or waqf) |
| `ghunnah` | نّ / مّ |
| `madd` | Madd letters with the usual Hafs length classes collapsed to one legend color in v1 |
| `laam_shamsiyah` | ال + sun letter |
| `ham_wasl` | U+0671 / wasl contexts |

Unknown ids ignored. Legend lists only rules that appear.

Colors are **this app’s theme tokens** (`ColorScheme` tints), not a third-party CSS sheet. Same roles in Light and Forest.

## Sidecar (generated, gitignored)

- Canonical: `data/bundled/quran/tajweed/tajweed_spans.json` (or per-surah files)
- Sync: `assets/quran/tajweed/` via `qo sync`
- Not committed. Not merged into `s###.json`. Do not restore `verses.tajweed`.

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

- `start` / `end`: extended grapheme-cluster indices into that ayah’s `ar` (`[start, end)`).
- Cluster = base letter + following combining marks (harakat, shadda, sukun, superscript alef U+0670).
- Waqf/saktah U+06D6–U+06DC plus the following space they attach to in Digital Khatt GPOS: **one cluster**.
- If a rule would split a cluster, **color the whole cluster**. Never emit a span that starts with a combining mark.
- `arHash` mismatch → plain paint. Never rewrite `ar`.

Generator: offline script that reads bundled `s###.json` `ar` only, walks letters with a Hafs rule table, writes the sidecar. Unit-test the walker on goldens (1:1, 1:6 keep U+0670, 2:1, a qalqalah ayah, an ikhfa ayah).

## Rendering on Digital Khatt (why harakat used to vanish)

Previous coloring cut glyphs and dropped harakat because Flutter **shapes each `TextSpan` separately**. If a tag split `مَ` from `ـٰ`, or a letter from its fatha, the mark was laid out without its base (see historical notes in `docs/TAJWEED_RENDERING_ANALYSIS.md`). That was a **span-boundary** bug, not a Digital Khatt bug.

This feature must keep Digital Khatt and avoid that split:

1. **One font on every span:** `DigitalKhattV2` + existing fallbacks, same size, height `1.7`, `locale: ar`. Missing family on a child span is what used to tofu U+0671.
2. **Color is the only style difference.** No fontWeight, letterSpacing, or backgroundColor on letter spans (those break joining).
3. **Never split inside a cluster.** Harakat always live in the same span as their base. If needed, color the whole word rather than cut lam-alif or shadda+haraka apart.
4. Concatenation of span texts equals `ar` exactly.
5. Toggle off / bad hash: current single `SelectableText` (proven path).

If device QA still shows joining breaks with color-only cluster spans, fall back to **word-level** color (one color per space-delimited word) rather than changing font or changing `ar`.

Bismillah: same font and same generator if we color it; otherwise leave the existing block plain.

## UI

- Persisted toggle, **default false**, in Reader `TextSettingsDialog` (not Mushaf).
- Compact legend when on.
- Share PNG / text: always plain `ar`.

## Integrity constraints

1. Do not rewrite `ar` (including no sukun substitution).
2. Do not import a second Arabic coloring corpus.
3. Do not restore JSON `tj` or SQLite `tajweed`.
4. Do not split harakat from their letter.
5. Do not color Mushaf QPC V2 in this feature.
6. Do not change Reader’s Arabic family away from Digital Khatt V2.

## Tests (when implemented)

- Span concat equals `ar`.
- No span starts with a combining mark.
- 1:6 still contains U+0670, never U+0672.
- No U+25CC in display strings.
- Joining smoke: lam-alif, shadda+haraka, waqf-on-space — with an adjacent colored cluster.
- Toggle off uses the single-style path.

## Docs to update at implementation time

- `QURAN_TEXT_INTEGRITY.md` — coloring is Hafs-rule sidecar on `ar` + Digital Khatt; cluster-safe spans.
- `DATA_SOURCES.md` — sidecar is generated from bundled `ar`; list the Hafs rule table as the scholarly baseline, not a third-party HTML dump.

## Out of scope

Mushaf coloring, QPC V4 fonts, changing Digital Khatt, Latin-as-substitute, hafalan scoring, runtime “guessing” that mutates letters.
