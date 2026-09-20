#!/usr/bin/env python3
"""Extract and build Quranic doa-ayat from LOCAL Quran JSON only.

Two subcommands:

  extract  Scan assets/quran/s001.json..s114.json for ayat whose form is a
           doa (Arabic vocative patterns + translation cross-check), group
           consecutive ayat, mark overlap with assets/duas/duas_catalog.json,
           and write a human review file. Existing review decisions are kept.

  build    Read the reviewed file, validate every decision, and write
           assets/ai/quran_dua_ayat_catalog.json containing ONLY approved
           references (surah/from/to + curated need text). No Arabic or
           translation text is copied into the app catalog: the app renders
           ayat from its own verses table.

Rules (see docs/ai_search/ai-search-spec.md):
  - No network access. No external data. No generated religious text.
  - Arabic normalisation is for matching only; stored `ar` is never altered.
  - The script never approves anything. Only a human reviewer does.

Usage:
  python tool/extract_dua_ayat.py extract
  python tool/extract_dua_ayat.py build
  python tool/extract_dua_ayat.py build --allow-pending
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

SURAH_COUNT = 114
AYAH_TOTAL = 6236

DEFAULT_QURAN_DIR = "assets/quran"
DEFAULT_DUA_CATALOG = "assets/duas/duas_catalog.json"
DEFAULT_REVIEW_FILE = "data/review/dua_ayat.review.json"
DEFAULT_OUT_CATALOG = "assets/ai/quran_dua_ayat_catalog.json"

REVIEW_SCHEMA_VERSION = 1
CATALOG_SCHEMA_VERSION = 1

# Must match lifeSituationCategoryOrder in lib/features/dua/life_situation.dart
ALLOWED_CATEGORIES = (
    "forgiveness",
    "faith",
    "patience",
    "trials",
    "protection",
    "provision",
    "family",
    "gratitude",
    "hope",
    "character",
    "world_hereafter",
)

DECISIONS = ("pending", "approved", "rejected")

# ---------------------------------------------------------------------------
# Normalisation (mirror of lib/core/utils/arabic_search_normalizer.dart)
# ---------------------------------------------------------------------------

_TAG = re.compile(r"<[^>]+>")
_TASHKEEL = re.compile(r"[\u064B-\u065F\u0670\u06D6-\u06ED]")
_ALIF_VARIANTS = re.compile(r"[\u0622\u0623\u0625\u0671]")
_SUP = re.compile(r"<sup\b[^>]*>.*?</sup>", re.IGNORECASE | re.DOTALL)
_LEADING_NUM = re.compile(r"^\d+\.\s*")


def normalize_arabic(text: str) -> str:
    """Normalise Arabic for pattern matching only. Never store the result."""
    s = _TAG.sub("", text)
    s = _TASHKEEL.sub("", s)
    s = s.replace("\u0640", "")  # tatweel
    s = _ALIF_VARIANTS.sub("\u0627", s)
    s = s.replace("\u0649", "\u064A")  # alif maqsura -> yaa
    s = s.replace("\u06DF", "").replace("\u06DD", "")
    return s.strip()


def clean_translation(text: str | None) -> str:
    """Mirror of TranslationCleaner.clean (footnotes + leading numbers)."""
    if not text:
        return ""
    s = _SUP.sub("", text)
    s = _LEADING_NUM.sub("", s)
    return s.strip()


# ---------------------------------------------------------------------------
# Detection rules
# ---------------------------------------------------------------------------

# Strong Arabic doa openers (after normalisation). Optional wa/fa prefix.
AR_STRONG_TOKENS = {
    "ربنا": "ar:rabbana",
    "اللهم": "ar:allahumma",
    "يرب": "ar:ya_rabbi",  # يَٰرَبِّ -> dagger alif stripped
    "يارب": "ar:ya_rabbi",
}
# Weak: vocative "rabbi" is indistinguishable from "rabb al-..." without
# the translation, so it only counts together with a translation signal.
AR_WEAK_TOKENS = {
    "رب": "ar:rabbi",
    "ربي": "ar:rabbi",
}
_PREFIX = ("و", "ف")

TR_ID_VOCATIVE = [
    (re.compile(r"\bya\s+tuhan\s*(kami|ku)\b", re.I), "tr_id:ya_tuhan"),
    (re.compile(r"\bya\s+tuhanku\b", re.I), "tr_id:ya_tuhan"),
    (re.compile(r"\bwahai\s+tuhan\s*(kami|ku)\b", re.I), "tr_id:wahai_tuhan"),
    (re.compile(r"\bya\s+allah\b", re.I), "tr_id:ya_allah"),
]
TR_EN_VOCATIVE = [
    (re.compile(r"\bour\s+lord\b", re.I), "tr_en:our_lord"),
    (re.compile(r"\bmy\s+lord\b", re.I), "tr_en:my_lord"),
    (re.compile(r"\bo\s+allah\b", re.I), "tr_en:o_allah"),
]

# Reviewer HINTS only. They never change a decision. Context must be verified
# against tafsir by the reviewer (e.g. words spoken by Iblis or by people in
# the Hereafter are doa in form but not recommended to recite).
KNOWN_CONTEXT_HINTS = {
    (7, 38): "Cek konteks: ucapan penghuni neraka.",
    (8, 32): "Cek konteks: ucapan orang kafir yang menantang.",
    (14, 44): "Cek konteks: ucapan orang zalim saat azab.",
    (15, 36): "Cek konteks: ucapan Iblis.",
    (23, 99): "Cek konteks: ucapan orang kafir saat sakaratul maut.",
    (23, 107): "Cek konteks: ucapan penghuni neraka.",
    (32, 12): "Cek konteks: ucapan orang berdosa di akhirat.",
    (33, 67): "Cek konteks: ucapan penghuni neraka.",
    (33, 68): "Cek konteks: ucapan penghuni neraka.",
    (35, 37): "Cek konteks: ucapan penghuni neraka.",
    (38, 16): "Cek konteks: ucapan orang kafir yang mengejek.",
    (38, 79): "Cek konteks: ucapan Iblis.",
    (40, 11): "Cek konteks: ucapan penghuni neraka.",
    (41, 29): "Cek konteks: ucapan penghuni neraka.",
}
_HEREAFTER_WORDS = re.compile(r"\b(neraka|jahanam|azab)\b", re.I)


def _tokens(normalized_ar: str) -> list[str]:
    return [t for t in normalized_ar.split() if t]


def _strip_prefix(token: str) -> list[str]:
    forms = [token]
    if len(token) > 2 and token[0] in _PREFIX:
        forms.append(token[1:])
    return forms


def detect_signals(ar: str, tr_id: str, tr_en: str) -> tuple[list[str], str | None]:
    """Return (signals, confidence) where confidence is 'high', 'medium' or None."""
    signals: list[str] = []
    strong = False
    weak = False
    for tok in _tokens(normalize_arabic(ar)):
        for form in _strip_prefix(tok):
            if form in AR_STRONG_TOKENS:
                strong = True
                signals.append(AR_STRONG_TOKENS[form])
            elif form in AR_WEAK_TOKENS:
                weak = True
                signals.append(AR_WEAK_TOKENS[form])

    id_voc = False
    for pattern, name in TR_ID_VOCATIVE:
        if pattern.search(tr_id):
            id_voc = True
            signals.append(name)
    en_voc = False
    for pattern, name in TR_EN_VOCATIVE:
        if pattern.search(tr_en):
            en_voc = True
            signals.append(name)

    signals = sorted(set(signals))

    if (strong or weak) and id_voc:
        return signals, "high"
    if strong:
        return signals, "medium"
    if id_voc and en_voc:
        return signals, "medium"
    return signals, None


# ---------------------------------------------------------------------------
# IO helpers
# ---------------------------------------------------------------------------


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_quran(quran_dir: Path) -> dict[int, list[dict]]:
    by_surah: dict[int, list[dict]] = {}
    total = 0
    for s in range(1, SURAH_COUNT + 1):
        path = quran_dir / f"s{s:03d}.json"
        if not path.is_file():
            raise SystemExit(f"missing {path}. Place local Quran JSON first (DATA_SOURCES.md).")
        verses = load_json(path)
        for v in verses:
            if v.get("s") != s or not isinstance(v.get("a"), int) or not v.get("ar"):
                raise SystemExit(f"bad verse object in {path}: {str(v)[:80]}")
        by_surah[s] = sorted(verses, key=lambda v: v["a"])
        total += len(verses)
    if total != AYAH_TOTAL:
        raise SystemExit(f"expected {AYAH_TOTAL} ayat, found {total}")
    return by_surah


def manifest_version(quran_dir: Path) -> str | None:
    path = quran_dir / "manifest_multi.json"
    if path.is_file():
        return load_json(path).get("version")
    return None


def dua_catalog_coverage(catalog_path: Path) -> dict[tuple[int, int], list[str]]:
    coverage: dict[tuple[int, int], list[str]] = {}
    if not catalog_path.is_file():
        print(f"note: {catalog_path} not found, in_dua_catalog will be false", file=sys.stderr)
        return coverage
    for entry in load_json(catalog_path).get("entries", []):
        for ref in entry.get("ayahRefs", []):
            s = ref["surah"]
            frm = ref["from"]
            to = ref.get("to") or frm
            for a in range(frm, to + 1):
                coverage.setdefault((s, a), []).append(entry["id"])
    return coverage


def empty_review() -> dict:
    return {
        "decision": "pending",
        "is_doa_lafaz": None,
        "recommended_to_recite": None,
        "from": None,
        "to": None,
        "category": None,
        "tags": [],
        "need": {"id": "", "en": ""},
        "reviewer": "",
        "notes": "",
    }


# ---------------------------------------------------------------------------
# extract
# ---------------------------------------------------------------------------


def find_candidates(by_surah: dict[int, list[dict]]) -> list[dict]:
    hits: list[dict] = []
    for s in range(1, SURAH_COUNT + 1):
        for v in by_surah[s]:
            tr = v.get("tr") or {}
            tr_id = clean_translation(tr.get("id"))
            tr_en = clean_translation(tr.get("en"))
            signals, confidence = detect_signals(v["ar"], tr_id, tr_en)
            if confidence is None:
                continue
            hits.append(
                {
                    "s": s,
                    "a": v["a"],
                    "ar": v["ar"],  # copied verbatim for the reviewer only
                    "tr_id": tr_id,
                    "tr_en": tr_en,
                    "signals": signals,
                    "confidence": confidence,
                }
            )
    return hits


def group_candidates(hits: list[dict], coverage: dict[tuple[int, int], list[str]]) -> list[dict]:
    groups: list[list[dict]] = []
    for h in hits:
        if groups and groups[-1][-1]["s"] == h["s"] and groups[-1][-1]["a"] + 1 == h["a"]:
            groups[-1].append(h)
        else:
            groups.append([h])

    out: list[dict] = []
    for g in groups:
        s = g[0]["s"]
        frm = g[0]["a"]
        to = g[-1]["a"]
        ids: list[str] = []
        hints: list[str] = []
        for h in g:
            for cid in coverage.get((s, h["a"]), []):
                if cid not in ids:
                    ids.append(cid)
            hint = KNOWN_CONTEXT_HINTS.get((s, h["a"]))
            if hint and hint not in hints:
                hints.append(hint)
            if _HEREAFTER_WORDS.search(h["tr_id"]):
                generic = f"Cek konteks {s}:{h['a']}: terjemahan menyebut neraka/azab."
                if generic not in hints:
                    hints.append(generic)
        out.append(
            {
                "group_key": f"{s}:{frm}-{to}",
                "source": "extractor",
                "surah": s,
                "from": frm,
                "to": to,
                "confidence": "high" if any(h["confidence"] == "high" for h in g) else "medium",
                "in_dua_catalog": bool(ids),
                "dua_catalog_ids": ids,
                "hints": hints,
                "ayat": [
                    {k: h[k] for k in ("a", "ar", "tr_id", "tr_en", "signals", "confidence")}
                    for h in g
                ],
                "review": empty_review(),
            }
        )
    return out


def merge_previous(groups: list[dict], previous: dict | None) -> tuple[list[dict], list[dict], list[dict]]:
    """Carry reviews forward by exact group_key. Returns (groups, manual, orphaned)."""
    if not previous:
        return groups, [], []
    prev_by_key = {g["group_key"]: g for g in previous.get("groups", [])}
    current_keys = set()
    for g in groups:
        current_keys.add(g["group_key"])
        old = prev_by_key.get(g["group_key"])
        if old and isinstance(old.get("review"), dict):
            merged = empty_review()
            merged.update(old["review"])
            g["review"] = merged
    orphaned = [
        g for k, g in prev_by_key.items()
        if k not in current_keys and (g.get("review") or {}).get("decision") != "pending"
    ]
    orphaned.extend(previous.get("orphaned_reviews", []))
    manual = previous.get("manual_additions", [])
    return groups, manual, orphaned


def cmd_extract(args: argparse.Namespace) -> int:
    quran_dir = Path(args.quran_dir)
    review_path = Path(args.review_file)
    by_surah = load_quran(quran_dir)
    coverage = dua_catalog_coverage(Path(args.dua_catalog))

    hits = find_candidates(by_surah)
    groups = group_candidates(hits, coverage)

    previous = load_json(review_path) if review_path.is_file() else None
    groups, manual, orphaned = merge_previous(groups, previous)

    doc = {
        "schemaVersion": REVIEW_SCHEMA_VERSION,
        "generatedAtUtc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "quranManifestVersion": manifest_version(quran_dir),
        "instructions": (
            "Edit only the `review` object of each group, and `manual_additions`. "
            "decision: pending|approved|rejected. Approved requires is_doa_lafaz=true, "
            "recommended_to_recite (bool), need.id, need.en, tags, reviewer. "
            "Optional review.from/review.to narrow or widen the range. "
            "Verify context with tafsir; hints are not decisions."
        ),
        "allowedCategories": list(ALLOWED_CATEGORIES),
        "stats": {
            "ayatMatched": len(hits),
            "groups": len(groups),
            "high": sum(1 for g in groups if g["confidence"] == "high"),
            "medium": sum(1 for g in groups if g["confidence"] == "medium"),
            "inDuaCatalog": sum(1 for g in groups if g["in_dua_catalog"]),
            "reviewed": sum(1 for g in groups if g["review"]["decision"] != "pending"),
        },
        "groups": groups,
        "manual_additions": manual,
        "orphaned_reviews": orphaned,
    }
    write_json(review_path, doc)
    st = doc["stats"]
    print(
        f"Wrote {review_path}: {st['groups']} groups ({st['high']} high, {st['medium']} medium) "
        f"from {st['ayatMatched']} ayat; {st['inDuaCatalog']} overlap duas_catalog; "
        f"{st['reviewed']} already reviewed; {len(orphaned)} orphaned reviews."
    )
    return 0


# ---------------------------------------------------------------------------
# build
# ---------------------------------------------------------------------------


class ValidationError(Exception):
    pass


def validate_review(unit: dict, max_ayah: dict[int, int]) -> dict | None:
    """Return a catalog entry for an approved unit, None for rejected/pending."""
    key = unit.get("group_key") or f"manual:{unit.get('surah')}:{unit.get('from')}"
    review = unit.get("review")
    if not isinstance(review, dict):
        raise ValidationError(f"{key}: missing review object")
    decision = review.get("decision")
    if decision not in DECISIONS:
        raise ValidationError(f"{key}: decision must be one of {DECISIONS}")
    if decision != "approved":
        return None

    if review.get("is_doa_lafaz") is not True:
        raise ValidationError(f"{key}: approved entries must have is_doa_lafaz=true")
    if not isinstance(review.get("recommended_to_recite"), bool):
        raise ValidationError(f"{key}: recommended_to_recite must be true or false")
    need = review.get("need") or {}
    for lang in ("id", "en"):
        if not isinstance(need.get(lang), str) or not need[lang].strip():
            raise ValidationError(f"{key}: need.{lang} is required")
    tags = review.get("tags")
    if not isinstance(tags, list) or not tags or not all(isinstance(t, str) and t.strip() for t in tags):
        raise ValidationError(f"{key}: tags must be a non-empty list of strings")
    category = review.get("category")
    if category is not None and category not in ALLOWED_CATEGORIES:
        raise ValidationError(f"{key}: category {category!r} not in allowedCategories")
    if not isinstance(review.get("reviewer"), str) or not review["reviewer"].strip():
        raise ValidationError(f"{key}: reviewer is required")

    surah = unit.get("surah")
    if not isinstance(surah, int) or not 1 <= surah <= SURAH_COUNT:
        raise ValidationError(f"{key}: invalid surah")
    frm = review.get("from") if review.get("from") is not None else unit.get("from")
    to = review.get("to") if review.get("to") is not None else unit.get("to", frm)
    if not isinstance(frm, int) or not isinstance(to, int):
        raise ValidationError(f"{key}: from/to must be integers")
    if frm < 1 or to < frm or to > max_ayah[surah]:
        raise ValidationError(f"{key}: range {surah}:{frm}-{to} out of bounds (max {max_ayah[surah]})")

    return {
        "id": f"qd_{surah:03d}_{frm:03d}_{to:03d}",
        "surah": surah,
        "from": frm,
        "to": to,
        "category": category,
        "tags": sorted({t.strip() for t in tags}),
        "need": {"id": need["id"].strip(), "en": need["en"].strip()},
        "recommendedToRecite": review["recommended_to_recite"],
        "inDuaCatalog": bool(unit.get("in_dua_catalog")),
        "duaCatalogIds": list(unit.get("dua_catalog_ids") or []),
        "source": unit.get("source", "manual"),
    }


def cmd_build(args: argparse.Namespace) -> int:
    quran_dir = Path(args.quran_dir)
    review_path = Path(args.review_file)
    if not review_path.is_file():
        raise SystemExit(f"missing {review_path}; run `extract` first")
    by_surah = load_quran(quran_dir)
    max_ayah = {s: by_surah[s][-1]["a"] for s in by_surah}
    coverage = dua_catalog_coverage(Path(args.dua_catalog))

    doc = load_json(review_path)
    units = list(doc.get("groups", []))
    for m in doc.get("manual_additions", []):
        m = dict(m)
        m.setdefault("source", "manual")
        s, frm = m.get("surah"), m.get("from")
        to = m.get("to", frm)
        if isinstance(s, int) and isinstance(frm, int) and isinstance(to, int):
            ids: list[str] = []
            for a in range(frm, to + 1):
                for cid in coverage.get((s, a), []):
                    if cid not in ids:
                        ids.append(cid)
            m["in_dua_catalog"] = bool(ids)
            m["dua_catalog_ids"] = ids
        units.append(m)

    pending = [u.get("group_key", "manual") for u in units if (u.get("review") or {}).get("decision") == "pending"]
    if pending and not args.allow_pending:
        raise SystemExit(
            f"{len(pending)} units still pending (e.g. {pending[:5]}). "
            "Review them or pass --allow-pending to skip."
        )

    entries: list[dict] = []
    errors: list[str] = []
    for u in units:
        try:
            entry = validate_review(u, max_ayah)
        except ValidationError as err:
            errors.append(str(err))
            continue
        if entry:
            entries.append(entry)
    if errors:
        for e in errors:
            print(f"error: {e}", file=sys.stderr)
        raise SystemExit(f"{len(errors)} validation errors; nothing written")

    seen_ranges: dict[tuple[int, int], tuple[int, str]] = {}
    for e in sorted(entries, key=lambda x: (x["surah"], x["from"], x["to"])):
        for a in range(e["from"], e["to"] + 1):
            prior = seen_ranges.get((e["surah"], a))
            if prior:
                raise SystemExit(f"overlapping approved ranges: {prior[1]} and {e['id']} at {e['surah']}:{a}")
            seen_ranges[(e["surah"], a)] = (a, e["id"])

    entries.sort(key=lambda x: (x["surah"], x["from"]))
    catalog = {
        "version": CATALOG_SCHEMA_VERSION,
        "generatedAtUtc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "quranManifestVersion": manifest_version(quran_dir),
        "note": "References only. Arabic and translations are rendered from the app verses table.",
        "entries": entries,
    }
    out = Path(args.out)
    write_json(out, catalog)
    print(f"Wrote {out}: {len(entries)} approved doa-ayat entries; skipped {len(pending)} pending.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--quran-dir", default=DEFAULT_QURAN_DIR)
    common.add_argument("--dua-catalog", default=DEFAULT_DUA_CATALOG)
    common.add_argument("--review-file", default=DEFAULT_REVIEW_FILE)

    sub.add_parser("extract", parents=[common], help="scan local Quran JSON and write review file")
    p_build = sub.add_parser("build", parents=[common], help="validate reviews and write app catalog")
    p_build.add_argument("--out", default=DEFAULT_OUT_CATALOG)
    p_build.add_argument("--allow-pending", action="store_true")

    args = parser.parse_args(argv)
    if args.command == "extract":
        return cmd_extract(args)
    return cmd_build(args)


if __name__ == "__main__":
    raise SystemExit(main())
