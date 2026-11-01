#!/usr/bin/env python3
"""Regenerate lib/core/mushaf/surah_name_glyph_metrics.dart.

The SurahNameV2 decoration font maps "surah001" ... "surah114" through GSUB
ligatures to one ornament glyph per surah. Those glyphs have large empty
ascent/descent, so sizing them by the font line box makes the visible ink much
smaller than the slot. The Mushaf header is sized by INK bounds instead, which
this table provides.

Surah 33 is special: the font has no "surah033" ligature (only "033").

Usage:
    python tools/generate_surah_name_glyph_metrics.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
FONT_PATH = ROOT / "assets" / "fonts" / "surah_name_v2.ttf"
OUT_PATH = ROOT / "lib" / "core" / "mushaf" / "surah_name_glyph_metrics.dart"

# Surahs whose ligature sequence is not "surahNNN" in SurahNameV2.
TEXT_OVERRIDES = {33: "033"}


def glyph_text(surah_id: int) -> str:
    return TEXT_OVERRIDES.get(surah_id, f"surah{surah_id:03d}")


def load_ligatures(font: TTFont) -> dict[str, str]:
    """text -> ligature glyph name (only 8/3 character ornament sequences)."""
    cmap = font.getBestCmap()
    reverse = {name: chr(cp) for cp, name in cmap.items()}
    sub = font["GSUB"].table.LookupList.Lookup[0].SubTable[0]
    by_text: dict[str, str] = {}
    for first_glyph, ligatures in sub.ligatures.items():
        for ligature in ligatures:
            components = [ligature.Component[i] for i in range(len(ligature.Component))]
            text = "".join(
                [reverse.get(first_glyph, first_glyph)]
                + [reverse.get(c, c) for c in components]
            )
            by_text[text] = ligature.LigGlyph
    return by_text


def main() -> int:
    if not FONT_PATH.exists():
        print(f"ERROR: missing font {FONT_PATH}", file=sys.stderr)
        return 1

    font = TTFont(str(FONT_PATH))
    units_per_em = font["head"].unitsPerEm
    glyf = font["glyf"]
    ligatures = load_ligatures(font)

    rows: list[tuple[int, int, int, int, int]] = []
    missing: list[int] = []
    for surah_id in range(1, 115):
        text = glyph_text(surah_id)
        glyph_name = ligatures.get(text)
        if glyph_name is None:
            missing.append(surah_id)
            continue
        glyph = glyf[glyph_name]
        glyph.recalcBounds(glyf)
        rows.append(
            (
                surah_id,
                glyph.xMin,
                glyph.yMin,
                glyph.xMax,
                glyph.yMax,
            )
        )

    if missing:
        print(f"ERROR: no ligature for surahs {missing}", file=sys.stderr)
        return 1

    lines = [
        "// GENERATED FILE - do not edit by hand.",
        "// Regenerate with: python tools/generate_surah_name_glyph_metrics.py",
        "//",
        "// Ink bounds of the SurahNameV2 ornament ligatures, in font units.",
        "// SurahNameV2 has large empty ascent/descent; the Mushaf header sizes the",
        "// glyph by these ink bounds so every surah name has the same visual height.",
        "",
        f"const double kSurahNameGlyphUnitsPerEm = {units_per_em};",
        "",
        "/// Ink box of one surah-name ligature, in font units.",
        "///",
        "/// [yMax] and [yMin] are measured from the baseline (font y-up). This font",
        "/// keeps the whole ink above the baseline, so both are positive.",
        "class SurahNameGlyphInk {",
        "  const SurahNameGlyphInk({",
        "    required this.surahId,",
        "    required this.xMin,",
        "    required this.yMin,",
        "    required this.xMax,",
        "    required this.yMax,",
        "  });",
        "",
        "  final int surahId;",
        "  final int xMin;",
        "  final int yMin;",
        "  final int xMax;",
        "  final int yMax;",
        "",
        "  double get inkWidthUnits => (xMax - xMin).toDouble();",
        "",
        "  double get inkHeightUnits => (yMax - yMin).toDouble();",
        "}",
        "",
        "/// Text sequence that ligates to the surah ornament.",
        "///",
        "/// Surah 33 is the only surah whose ligature is not `surahNNN`.",
        "String surahNameGlyphText(int surahId) {",
        "  if (surahId == 33) return '033';",
        "  return 'surah${surahId.toString().padLeft(3, '0')}';",
        "}",
        "",
        "/// Indexed by `surahId - 1`.",
        "const List<SurahNameGlyphInk> kSurahNameGlyphInk = [",
    ]
    for surah_id, x_min, y_min, x_max, y_max in rows:
        lines.append(
            "  SurahNameGlyphInk("
            f"surahId: {surah_id}, xMin: {x_min}, yMin: {y_min}, "
            f"xMax: {x_max}, yMax: {y_max}),"
        )
    lines += [
        "];",
        "",
        "/// Ink metrics for [surahId], or null outside 1..114.",
        "SurahNameGlyphInk? surahNameGlyphInkFor(int surahId) {",
        "  if (surahId < 1 || surahId > kSurahNameGlyphInk.length) return null;",
        "  return kSurahNameGlyphInk[surahId - 1];",
        "}",
        "",
    ]

    OUT_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT_PATH} ({len(rows)} surahs, upem {units_per_em})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
