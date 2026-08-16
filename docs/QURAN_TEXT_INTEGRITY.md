# Quran text integrity

## Source

Reader and Juz Arabic comes from Quran Foundation `text_uthmani`, stored in bundled per-surah JSON as `ar`.

The app displays that string **codepoint-for-codepoint**. There is no normalisation, letter rewriting, sukun substitution (including U+0652 → U+06E1), or span-splitting of Arabic for coloring.

## Why colored tajweed is not shipped

Quran Foundation `text_uthmani_tajweed` is a **different lineage** from `text_uthmani`. Aligning colored HTML onto `ar` required rewriting or dropping marks.

Example: ayah 1:6 uses superscript alef U+0670 in `text_uthmani`, while `uthmani_tajweed` uses U+0672 (alef with wavy hamza below) in the corresponding place. Mixing those streams produced dotted circles (U+25CC) and wrong letters.

QPC V2 Mushaf page fonts and the QUL `transliteration-tajweed.db` Latin database are unrelated to this color-HTML path and remain in the app.

## Sukun (U+0652)

Circular sukun U+0652 is correct for this `text_uthmani` source. Rendering depends on the Uthmanic font, not on replacing the codepoint.

## Checks

`test/quran_text_integrity_test.dart` (skipped if `assets/quran/s001.json` is missing):

- No U+25CC (dotted circle) and no U+0672 in the bundled `ar` corpus
- U+0670, U+0640, U+06D6, and U+06DA occur at least once
- `QuranArabicText` for 1:1 shows the same `ar` string
