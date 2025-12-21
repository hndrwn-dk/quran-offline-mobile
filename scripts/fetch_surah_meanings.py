#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Fetch surah translated names (meanings) for multiple languages from Quran.com v4 API.
Generates: assets/quran/surah_meanings.json

This script uses PUBLIC endpoint:
  https://api.quran.com/api/v4/chapters?language=<lang>

No OAuth/token required.

Run:
  python scripts/fetch_surah_meanings.py
"""

import json
import sys
import io
from pathlib import Path

import requests

# Fix encoding for Windows console
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')


API_BASE_URL = "https://api.quran.com/api/v4"
LANGS = ["en", "id", "zh", "ja"]  # match your supported translation languages


def fetch_chapters(language: str) -> list[dict]:
    url = f"{API_BASE_URL}/chapters"
    r = requests.get(url, params={"language": language}, timeout=20)
    r.raise_for_status()
    data = r.json()
    chapters = data.get("chapters", [])
    if not chapters:
        raise RuntimeError(f"No chapters returned for language={language}. Response keys={list(data.keys())}")
    return chapters


def extract_surah_meanings(chapters: list[dict]) -> dict[str, str]:
    """
    Returns mapping: {"1": "The Opening", ..., "114": "..."}
    """
    out: dict[str, str] = {}
    for ch in chapters:
        cid = ch.get("id")
        tname = (ch.get("translated_name") or {}).get("name", "")
        if cid is None:
            continue
        out[str(cid)] = (tname or "").strip()
    return out


def main() -> int:
    print("=" * 60)
    print("Quran.com v4 - Surah Meanings Fetcher (Public Chapters API)")
    print("=" * 60)

    all_lang_maps: dict[str, dict[str, str]] = {}
    for lang in LANGS:
        print(f"Fetching chapters for language={lang} ...", end=" ")
        chapters = fetch_chapters(lang)
        if len(chapters) != 114:
            print("FAIL")
            raise RuntimeError(f"Expected 114 chapters, got {len(chapters)} for language={lang}")
        lang_map = extract_surah_meanings(chapters)

        # Sanity check: ensure not all empty
        non_empty = sum(1 for v in lang_map.values() if v)
        print(f"OK ({len(chapters)} chapters, non-empty meanings={non_empty})")
        
        # Check if API actually returned the requested language or fallback to English
        if lang != "en" and non_empty > 0:
            # Check first chapter to see if language matches
            first_ch = chapters[0] if chapters else None
            if first_ch:
                trans_name = first_ch.get("translated_name", {})
                resp_lang = trans_name.get("language_name", "").lower()
                if "english" in resp_lang or resp_lang == "en":
                    print(f"  Warning: API returned English instead of {lang}, using English as fallback")
                    # Use English as fallback for unsupported languages
                    if "en" in all_lang_maps:
                        lang_map = all_lang_maps["en"].copy()

        all_lang_maps[lang] = lang_map

    # Merge into final structure: {"1": {"en": "...", "id": "...", ...}, ...}
    merged: dict[str, dict[str, str]] = {}
    for surah_id in range(1, 115):
        sid = str(surah_id)
        merged[sid] = {lang: all_lang_maps[lang].get(sid, "") for lang in LANGS}

    # Validate: each surah should have at least English
    missing_en = [sid for sid in merged.keys() if not merged[sid].get("en")]
    if missing_en:
        raise RuntimeError(f"Missing English translated_name for surah IDs: {missing_en[:10]} ...")

    # Write to assets/quran/surah_meanings.json (relative to repo root)
    repo_root = Path(__file__).resolve().parents[1]  # scripts/.. -> repo root
    output_path = repo_root / "assets" / "quran" / "surah_meanings.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    print(f"\nDONE: wrote {output_path}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        raise
