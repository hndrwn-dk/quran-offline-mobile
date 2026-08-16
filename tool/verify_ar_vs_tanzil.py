"""Compare bundled JSON `ar` to Tanzil Uthmani, codepoint by codepoint.

Tanzil source (Uthmani, text with aya numbers, surah|ayah|text):
  URL: https://tanzil.net/pub/download/index.php?quranType=uthmani&outType=txt-2
  Official UI: https://tanzil.net/download/ (text type Uthmani, format Text)
  Downloaded: 2026-08-16
  Local path (gitignored, do not commit): data/tanzil/quran-uthmani.txt

JSON: assets/quran/s[0-9][0-9][0-9].json as a JSON ARRAY of verse objects
with keys s, a, ar. No NFC, fold, or letter rewriting. Report only.
"""

from __future__ import annotations

import glob
import json
import os
import sys
import unicodedata
import urllib.request
from collections import Counter

TANZIL_URL = (
    "https://tanzil.net/pub/download/index.php?quranType=uthmani&outType=txt-2"
)
TANZIL_DOWNLOADED = "2026-08-16"
DEFAULT_TANZIL_PATH = os.path.join("data", "tanzil", "quran-uthmani.txt")


def load_verses(path: str) -> list:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, list):
        return data
    raise SystemExit(f"unexpected JSON shape in {path}: {type(data).__name__}")


def load_tanzil(path: str) -> dict[tuple[int, int], str]:
    out: dict[tuple[int, int], str] = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            parts = line.split("|", 2)
            if len(parts) != 3:
                continue
            s, a, text = int(parts[0]), int(parts[1]), parts[2]
            out[(s, a)] = text
    return out


def ensure_tanzil(path: str) -> None:
    if os.path.isfile(path):
        return
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    req = urllib.request.Request(TANZIL_URL, headers={"User-Agent": "quran-offline-verify"})
    with urllib.request.urlopen(req) as resp:
        data = resp.read()
    with open(path, "wb") as f:
        f.write(data)


def cp_name(ch: str) -> str:
    return unicodedata.name(ch, "?")


def is_combining(ch: str) -> bool:
    return unicodedata.combining(ch) != 0


def strip_combining(text: str) -> str:
    return "".join(ch for ch in text if not is_combining(ch))


PAUSE_OR_SIGN = set("\u06d6\u06d7\u06d8\u06d9\u06da\u06db\u06dc\u06de\u06e9")
ZERO_MARKS = set("\u06df\u06e0")


def strip_layout_signs(text: str) -> str:
    return "".join(
        ch for ch in text if ch not in PAUSE_OR_SIGN and ch != "\u0640"
    )


def local_diffs(ar: str, tz: str) -> list[tuple[str, str]]:
    """Greedy mismatch regions: substitution / insert / delete until resync."""
    i = 0
    j = 0
    out: list[tuple[str, str]] = []
    n, m = len(ar), len(tz)
    while i < n and j < m:
        if ar[i] == tz[j]:
            i += 1
            j += 1
            continue
        i0, j0 = i, j
        found = False
        for span in range(1, 24):
            for di in range(0, span + 1):
                dj = span - di
                ni, nj = i + di, j + dj
                if ni <= n and nj <= m:
                    if ni < n and nj < m and ar[ni] == tz[nj]:
                        # require two matching chars when possible
                        if ni + 1 < n and nj + 1 < m and ar[ni + 1] != tz[nj + 1]:
                            continue
                        out.append((ar[i0:ni], tz[j0:nj]))
                        i, j = ni, nj
                        found = True
                        break
                    if ni == n and nj == m:
                        out.append((ar[i0:], tz[j0:]))
                        i, j = n, m
                        found = True
                        break
            if found:
                break
        if not found:
            out.append((ar[i0:], tz[j0:]))
            break
    if i < n or j < m:
        if not out or out[-1] != (ar[i:], tz[j:]):
            out.append((ar[i:], tz[j:]))
    return out


def cps(s: str) -> str:
    return " ".join(f"U+{ord(c):04X}" for c in s)


def classify(ar_part: str, tz_part: str) -> str:
    ar_set = set(ar_part)
    tz_set = set(tz_part)
    if (ar_set & ZERO_MARKS) or (tz_set & ZERO_MARKS):
        return "B"
    leftover_ar = "".join(
        ch for ch in ar_part if ch not in PAUSE_OR_SIGN and ch not in " \u0640"
    )
    leftover_tz = "".join(
        ch for ch in tz_part if ch not in PAUSE_OR_SIGN and ch not in " \u0640"
    )
    if leftover_ar == leftover_tz:
        return "A"
    ar_letters = strip_combining(ar_part)
    tz_letters = strip_combining(tz_part)
    if ar_letters != tz_letters:
        return "C"
    return "A"


def snippet(text: str, i: int, radius: int = 8) -> str:
    start = max(0, i - radius)
    return text[start : i + radius + 1]


def first_mismatch_index(a: str, b: str) -> int:
    n = min(len(a), len(b))
    i = 0
    while i < n and a[i] == b[i]:
        i += 1
    return i


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    tanzil_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_TANZIL_PATH
    ensure_tanzil(tanzil_path)
    tanzil = load_tanzil(tanzil_path)

    files = sorted(glob.glob("assets/quran/s[0-9][0-9][0-9].json"))
    if not files:
        raise SystemExit("no assets/quran/s*.json files found")

    compared = 0
    identical = 0
    differing = 0
    missing_tanzil = 0
    missing_ar = 0
    extra_in_ar: Counter[str] = Counter()
    extra_in_tz: Counter[str] = Counter()
    pattern_counts: Counter[tuple[str, str]] = Counter()
    pattern_example: dict[tuple[str, str], tuple[str, str, str]] = {}
    letter_count_diff: list[str] = []
    letter_count_diff_core: list[str] = []

    for path in files:
        verses = load_verses(path)
        for v in verses:
            s = int(v["s"])
            a = int(v["a"])
            ar = v["ar"]
            key = (s, a)
            if key not in tanzil:
                missing_tanzil += 1
                continue
            tz = tanzil[key]
            compared += 1
            if ar == tz:
                identical += 1
                continue
            differing += 1
            vk = f"{s}:{a}"
            for c in set(ar) - set(tz):
                extra_in_ar[c] += ar.count(c)
            for c in set(tz) - set(ar):
                extra_in_tz[c] += tz.count(c)
            if len(strip_combining(ar)) != len(strip_combining(tz)):
                letter_count_diff.append(vk)
            ar_core = strip_combining(strip_layout_signs(ar))
            tz_core = strip_combining(strip_layout_signs(tz))
            if len(ar_core) != len(tz_core):
                letter_count_diff_core.append(vk)
            diffs = local_diffs(ar, tz)
            for ar_part, tz_part in diffs:
                pk = (ar_part, tz_part)
                pattern_counts[pk] += 1
                if pk not in pattern_example:
                    mi = first_mismatch_index(ar, tz)
                    pattern_example[pk] = (
                        vk,
                        snippet(ar, mi),
                        snippet(tz, mi),
                    )

    json_keys = set()
    for path in files:
        for v in load_verses(path):
            json_keys.add((int(v["s"]), int(v["a"])))
    missing_ar = sum(1 for k in tanzil if k not in json_keys)

    print("Tanzil vs JSON ar (raw codepoints, no NFC/fold)")
    print(f"Tanzil URL: {TANZIL_URL}")
    print(f"Downloaded: {TANZIL_DOWNLOADED}")
    print(f"Local: {tanzil_path}")
    print(f"JSON files: {len(files)}")
    print(f"Tanzil verses: {len(tanzil)}")
    print(f"verses compared: {compared}")
    print(f"identical: {identical}")
    print(f"differing: {differing}")
    print(f"JSON verses with no Tanzil row: {missing_tanzil}")
    print(f"Tanzil rows with no JSON verse: {missing_ar}")

    print("\ncodepoints in ar not in Tanzil that verse:")
    for c, n in extra_in_ar.most_common():
        print(f"  U+{ord(c):04X} {cp_name(c)} x{n}")
    if not extra_in_ar:
        print("  (none)")

    print("\ncodepoints in Tanzil not in ar that verse:")
    for c, n in extra_in_tz.most_common():
        print(f"  U+{ord(c):04X} {cp_name(c)} x{n}")
    if not extra_in_tz:
        print("  (none)")

    print("\n10 most frequent difference patterns:")
    for i, ((ar_part, tz_part), n) in enumerate(pattern_counts.most_common(10), 1):
        vk, ar_snip, tz_snip = pattern_example[(ar_part, tz_part)]
        kind = classify(ar_part, tz_part)
        label = {"A": "encoding variant", "B": "different-meaning mark 06DF/06E0", "C": "letter added/missing"}[kind]
        print(f"  {i}. x{n} class {kind} ({label})")
        print(f"     verse_key: {vk}")
        print(f"     ar_substr: {ar_part!r}  [{cps(ar_part)}]")
        print(f"     tz_substr: {tz_part!r}  [{cps(tz_part)}]")
        print(f"     ar snippet: {ar_snip}")
        print(f"     tz snippet: {tz_snip}")

    print(
        "\nverses where letter count differs after removing combining marks "
        f"(serious): {len(letter_count_diff)}"
    )
    if letter_count_diff:
        show = letter_count_diff[:40]
        print("  examples:", ", ".join(show))
        if len(letter_count_diff) > 40:
            print(f"  ... +{len(letter_count_diff) - 40} more")
    print(
        "after also removing tatweel U+0640 and pause/sajdah/hizb signs "
        f"(core letter count): {len(letter_count_diff_core)}"
    )
    if letter_count_diff_core:
        show = letter_count_diff_core[:40]
        print("  examples:", ", ".join(show))
        if len(letter_count_diff_core) > 40:
            print(f"  ... +{len(letter_count_diff_core) - 40} more")


if __name__ == "__main__":
    main()
