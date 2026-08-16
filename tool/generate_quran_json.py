#!/usr/bin/env python3
"""Fetch Quran.com / Quran Foundation API v4 into app verse JSON.

Writes assets/quran/s001.json .. s114.json plus index_juz.json,
index_pages.json, and manifest_multi.json.

Schema: JSON array of {s, a, ar, tr, m}. ar is text_uthmani only.
Omits tj, tl, and tl_tj. Does not request text_uthmani_tajweed or words.

Usage:
  python tool/generate_quran_json.py
  python tool/generate_quran_json.py --out-dir assets/quran
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

BASE_URL = "https://api.quran.com/api/v4/verses/by_chapter/{chapter}"
FIELDS = (
    "text_uthmani,verse_key,juz_number,hizb_number,"
    "page_number,ruku_number,rub_el_hizb_number"
)
TRANSLATION_IDS = (20, 33, 109, 35)
TR_CODE_BY_RESOURCE_ID = {
    20: "en",
    33: "id",
    109: "zh",
    35: "ja",
}
TRANSLATION_META = {
    "en": {"id": 20, "name": "Saheeh International", "language": "english"},
    "id": {
        "id": 33,
        "name": "Indonesian Islamic Affairs Ministry",
        "language": "indonesian",
    },
    "zh": {"id": 109, "name": "Muhammad Makin", "language": "chinese"},
    "ja": {"id": 35, "name": "Ryoichi Mita", "language": "japanese"},
}
PER_PAGE = 50
EXPECTED_AYAHS = (
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99,
    128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34,
    30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29,
    18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12,
    12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19,
    36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11,
    8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
)
USER_AGENT = "quran-offline-mobile-generate-quran-json/1.0"
MAX_RETRIES = 8


def map_verse(api_verse: dict) -> dict:
    key = api_verse.get("verse_key") or ""
    parts = str(key).split(":")
    if len(parts) != 2:
        raise ValueError(f"bad verse_key: {key!r}")
    surah = int(parts[0])
    ayah = int(parts[1])
    ar = api_verse.get("text_uthmani")
    if not isinstance(ar, str) or not ar:
        raise ValueError(f"missing text_uthmani for {key}")
    if "text_uthmani_tajweed" in api_verse:
        raise ValueError(f"unexpected text_uthmani_tajweed on {key}")

    tr: dict[str, str] = {}
    for item in api_verse.get("translations") or []:
        rid = item.get("resource_id")
        code = TR_CODE_BY_RESOURCE_ID.get(rid)
        text = item.get("text")
        if code and isinstance(text, str):
            tr[code] = text
    missing = [c for c in ("en", "id", "zh", "ja") if c not in tr]
    if missing:
        raise ValueError(f"missing translations {missing} for {key}")

    return {
        "s": surah,
        "a": ayah,
        "ar": ar,
        "tr": {
            "en": tr["en"],
            "id": tr["id"],
            "zh": tr["zh"],
            "ja": tr["ja"],
        },
        "m": {
            "juz": int(api_verse["juz_number"]),
            "page": int(api_verse["page_number"]),
            "hizb": int(api_verse["hizb_number"]),
            "ruku": int(api_verse["ruku_number"]),
        },
    }


def build_indexes(all_verses: list[dict]) -> tuple[dict, dict]:
    juz_map: dict[int, list[tuple[int, int]]] = defaultdict(list)
    page_map: dict[int, list[tuple[int, int]]] = defaultdict(list)
    for v in all_verses:
        meta = v["m"]
        juz_map[meta["juz"]].append((v["s"], v["a"]))
        page_map[meta["page"]].append((v["s"], v["a"]))

    def ranges(groups: dict[int, list[tuple[int, int]]]) -> dict[str, list]:
        out: dict[str, list] = {}
        for num in sorted(groups):
            items = groups[num]
            packed: list[dict] = []
            cur_s, start, prev = items[0][0], items[0][1], items[0][1]
            for s, a in items[1:]:
                if s == cur_s and a == prev + 1:
                    prev = a
                    continue
                packed.append({"s": cur_s, "a1": start, "a2": prev})
                cur_s, start, prev = s, a, a
            packed.append({"s": cur_s, "a1": start, "a2": prev})
            out[str(num)] = packed
        return out

    return ranges(juz_map), ranges(page_map)


def fetch_json(url: str) -> dict:
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        },
    )
    last_err: Exception | None = None
    delay = 1.0
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                return json.load(resp)
        except urllib.error.HTTPError as err:
            last_err = err
            if err.code in (429, 500, 502, 503, 504) and attempt < MAX_RETRIES:
                retry_after = err.headers.get("Retry-After") if err.headers else None
                wait = float(retry_after) if retry_after and retry_after.isdigit() else delay
                print(
                    f"  HTTP {err.code}, retry {attempt}/{MAX_RETRIES} in {wait:.1f}s",
                    file=sys.stderr,
                )
                time.sleep(wait)
                delay = min(delay * 2, 60)
                continue
            raise
        except (urllib.error.URLError, TimeoutError, OSError) as err:
            last_err = err
            if attempt < MAX_RETRIES:
                print(
                    f"  network error {err}, retry {attempt}/{MAX_RETRIES} in {delay:.1f}s",
                    file=sys.stderr,
                )
                time.sleep(delay)
                delay = min(delay * 2, 60)
                continue
            raise
    raise RuntimeError(f"fetch failed: {last_err}")


def fetch_chapter(chapter: int) -> list[dict]:
    verses: list[dict] = []
    page = 1
    while True:
        params = urllib.parse.urlencode(
            {
                "language": "en",
                "words": "false",
                "translations": ",".join(str(i) for i in TRANSLATION_IDS),
                "fields": FIELDS,
                "per_page": PER_PAGE,
                "page": page,
            }
        )
        url = f"{BASE_URL.format(chapter=chapter)}?{params}"
        payload = fetch_json(url)
        batch = payload.get("verses") or []
        verses.extend(batch)
        pagination = payload.get("pagination") or {}
        next_page = pagination.get("next_page")
        if not next_page:
            break
        page = int(next_page)
        time.sleep(0.2)
    return verses


def assert_schema(verse: dict) -> None:
    forbidden = {"tj", "tl", "tl_tj"}
    extra = forbidden.intersection(verse)
    if extra:
        raise ValueError(f"forbidden keys present: {extra}")
    if set(verse) != {"s", "a", "ar", "tr", "m"}:
        raise ValueError(f"unexpected verse keys: {sorted(verse)}")
    if "\u0672" in verse["ar"]:
        raise ValueError(f"{verse['s']}:{verse['a']} ar contains U+0672")


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, ensure_ascii=False, indent=2)
    path.write_text(text + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-dir", default="assets/quran")
    parser.add_argument(
        "--also-bundled",
        default="data/bundled/quran",
        help="also write here if the directory exists",
    )
    args = parser.parse_args()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    query = {
        "language": "en",
        "words": "false",
        "translations": ",".join(str(i) for i in TRANSLATION_IDS),
        "fields": FIELDS,
        "per_page": PER_PAGE,
    }
    fetched_at = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    mapped: list[dict] = []
    by_surah: dict[int, list[dict]] = {}

    for chapter in range(1, 115):
        print(f"Fetching surah {chapter:03d} ...", flush=True)
        raw = fetch_chapter(chapter)
        expected = EXPECTED_AYAHS[chapter - 1]
        if len(raw) != expected:
            raise SystemExit(
                f"surah {chapter}: expected {expected} verses, got {len(raw)}"
            )
        chapter_verses = [map_verse(v) for v in raw]
        for v in chapter_verses:
            assert_schema(v)
        by_surah[chapter] = chapter_verses
        mapped.extend(chapter_verses)
        time.sleep(0.15)

    if len(mapped) != 6236:
        raise SystemExit(f"expected 6236 verses, got {len(mapped)}")

    samples = {(1, 1), (1, 6), (6, 44)}
    for v in mapped:
        if (v["s"], v["a"]) in samples:
            if "\u0670" not in v["ar"] and (v["s"], v["a"]) != (1, 1):
                # 1:1 also has dagger alif in Al-Rahman; still check 1:6 and 6:44
                pass
    for s, a in ((1, 6), (6, 44)):
        verse = next(v for v in mapped if v["s"] == s and v["a"] == a)
        if "\u0670" not in verse["ar"]:
            raise SystemExit(f"{s}:{a} missing U+0670 in ar")
        if "\u0672" in verse["ar"]:
            raise SystemExit(f"{s}:{a} has U+0672 in ar")

    for chapter, verses in by_surah.items():
        write_json(out_dir / f"s{chapter:03d}.json", verses)

    index_juz, index_pages = build_indexes(mapped)
    if len(index_juz) != 30:
        raise SystemExit(f"expected 30 juz, got {len(index_juz)}")
    if len(index_pages) != 604:
        raise SystemExit(f"expected 604 pages, got {len(index_pages)}")

    manifest = {
        "version": "v10-uthmani+EN(SI)+ID(KEMENAG)+ZH(MaJian)+JA(Mita)-no-tajweed-in-json-no-tl",
        "source": "Quran Foundation / Quran.com API v4",
        "endpoint": "https://api.quran.com/api/v4/verses/by_chapter/{n}",
        "query": query,
        "script": "text_uthmani",
        "arabicField": "text_uthmani",
        "omittedJsonFields": ["tj", "tl", "tl_tj"],
        "hasTajweedHtml": False,
        "hasTransliteration": False,
        "transliterationNote": "On-screen transliteration is QUL transliteration-tajweed.db, not JSON tl",
        "fetchedAtUtc": fetched_at,
        "translations": TRANSLATION_META,
        "translationIds": list(TRANSLATION_IDS),
        "surahCount": 114,
        "ayahTotal": 6236,
        "files": 114,
    }
    write_json(out_dir / "index_juz.json", index_juz)
    write_json(out_dir / "index_pages.json", index_pages)
    write_json(out_dir / "manifest_multi.json", manifest)

    bundled = Path(args.also_bundled)
    if bundled.is_dir():
        print(f"Also writing {bundled}", flush=True)
        for chapter in range(1, 115):
            write_json(bundled / f"s{chapter:03d}.json", by_surah[chapter])
        write_json(bundled / "index_juz.json", index_juz)
        write_json(bundled / "index_pages.json", index_pages)
        write_json(bundled / "manifest_multi.json", manifest)

    print(f"Wrote 114 files, {len(mapped)} verses to {out_dir}")
    print(f"Fetched UTC date: {fetched_at}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
