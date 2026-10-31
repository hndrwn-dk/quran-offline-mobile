"""Audit: stripped tajweed HTML vs JSON `ar` (tatweel-only normalisation).

Each sNNN.json is a JSON array of verse objects (not {"verses": [...]}).
This script reports mismatches only; it does not rewrite data.
"""

from __future__ import annotations

import glob
import json
import re
import sys
import unicodedata
from collections import Counter

TAGS = re.compile(r"<[^>]+>")


def load_verses(path: str) -> list:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        verses = data.get("verses")
        if isinstance(verses, list):
            return verses
    raise SystemExit(f"unexpected JSON shape in {path}: {type(data).__name__}")


def snippet_around(text: str, index: int, radius: int = 6) -> str:
    start = max(0, index - radius)
    return text[start : index + radius + 1]


def first_mismatch_snippet(plain: str, ar: str) -> tuple[str, str]:
    body_plain = re.sub(r"[\u0660-\u0669]+\s*$", "", plain).rstrip()
    n = min(len(body_plain), len(ar))
    i = 0
    while i < n and body_plain[i] == ar[i]:
        i += 1
    return snippet_around(body_plain, min(i, len(body_plain) - 1)), snippet_around(
        ar, min(i, len(ar) - 1)
    )


def wavy_vs_ar_snippet(plain: str, ar: str) -> tuple[str, str]:
    i = plain.find("\u0672")
    j = ar.find("\u0670")
    return snippet_around(plain, i if i >= 0 else 0), snippet_around(
        ar, j if j >= 0 else 0
    )


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")

    files = sorted(glob.glob("assets/quran/s[0-9][0-9][0-9].json"))
    if not files:
        raise SystemExit("no assets/quran/s*.json files found")

    sample = load_verses(files[0])
    print(f"shape: {files[0]} is a JSON array of {len(sample)} verse objects")
    print(f"files: {len(files)}")

    total = 0
    with_tj = 0
    bad: list[tuple[object, object]] = []
    extra: Counter[str] = Counter()
    missing: Counter[str] = Counter()
    per_surah: Counter[int] = Counter()
    per_surah_body: Counter[int] = Counter()
    examples: dict[int, tuple[object, object, str, str]] = {}
    wavy_example: tuple[object, object, str, str] | None = None
    body_bad = 0

    for path in files:
        verses = load_verses(path)
        for v in verses:
            total += 1
            tj = v.get("tj")
            ar = v.get("ar", "")
            if not tj:
                continue
            with_tj += 1
            plain = TAGS.sub("", tj).replace("\u0640", "")
            if plain != ar:
                s = v.get("s")
                a = v.get("a")
                bad.append((s, a))
                body_plain = re.sub(r"[\u0660-\u0669]+\s*$", "", plain).rstrip()
                body_differs = body_plain != ar
                if body_differs:
                    body_bad += 1
                if isinstance(s, int):
                    per_surah[s] += 1
                    if body_differs:
                        per_surah_body[s] += 1
                    if s not in examples and body_differs:
                        examples[s] = (s, a, *first_mismatch_snippet(plain, ar))
                    if wavy_example is None and "\u0672" in plain:
                        wavy_example = (s, a, *wavy_vs_ar_snippet(plain, ar))
                for c in set(plain) - set(ar):
                    extra[c] += 1
                for c in set(ar) - set(plain):
                    missing[c] += 1

    print(f"total {total} | ada tj {with_tj} | melanggar {len(bad)}")
    print(
        f"(info) masih beda setelah buang nomor ayat di ujung tj: {body_bad}"
    )
    print("contoh:", bad[:20])

    print("\n-- ada di tj, tidak ada di ar --")
    for c, n in extra.most_common(15):
        print(f"  U+{ord(c):04X} {unicodedata.name(c, '?')} x{n}")

    print("\n-- ada di ar, tidak ada di tj --")
    for c, n in missing.most_common(15):
        print(f"  U+{ord(c):04X} {unicodedata.name(c, '?')} x{n}")

    print("\n-- 3 surah terburuk (jumlah ayat yang masih beda di tubuh teks) --")
    for sid, count in per_surah_body.most_common(3):
        s, a, tj_word, ar_word = examples[sid]
        print(f"  surah {sid}: {count} ayat (semua {per_surah[sid]} ayat beda jika termasuk nomor ayat tj)")
        print(f"    contoh {s}:{a}")
        print(f"    tj snippet: {tj_word}")
        print(f"    ar snippet: {ar_word}")
        print(f"    tj cps: {[hex(ord(c)) for c in tj_word]}")
        print(f"    ar cps: {[hex(ord(c)) for c in ar_word]}")

    if wavy_example is not None:
        s, a, tj_word, ar_word = wavy_example
        print("\n-- contoh pertama yang memuat U+0672 di tj --")
        print(f"  {s}:{a}")
        print(f"    tj snippet: {tj_word}")
        print(f"    ar snippet: {ar_word}")
        print(f"    tj cps: {[hex(ord(c)) for c in tj_word]}")
        print(f"    ar cps: {[hex(ord(c)) for c in ar_word]}")


if __name__ == "__main__":
    main()
