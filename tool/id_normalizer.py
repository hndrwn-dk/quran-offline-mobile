#!/usr/bin/env python3
"""Indonesian/English query normaliser (matching only). Version 4.

Mirrors docs/ai_search/ai-search-spec.md §6.1.
Synonym expansion is query-time only and is not applied here.
"""

from __future__ import annotations

import re

NORMALIZER_VERSION = 4

_HTML = re.compile(r"<[^>]+>")
_NON_ALNUM = re.compile(r"[^\w]+", re.UNICODE)
_MULTI_SPACE = re.compile(r"\s+")
_ARABIC = re.compile(r"[\u0600-\u06FF]")
_TASHKEEL = re.compile(r"[\u064B-\u065F\u0670\u06D6-\u06ED]")
_ALIF_VARIANTS = re.compile(r"[\u0622\u0623\u0625\u0671]")

# Particle suffixes first, then -kan/-an/-i. Under 4 chars keeps the longer form.
# Longer / per-ber-ter before pe-be-te so perang/pertolongan are not pe-.
_PREFIXES = (
    "meng",
    "meny",
    "mem",
    "men",
    "me",
    "peng",
    "peny",
    "pem",
    "pen",
    "per",
    "ber",
    "ter",
    "pe",
    "be",
    "te",
    "di",
    "ke",
    "se",
)
_MIN_STEM = 4
_VOWELS = set("aiueo")
_ROOT_WHITELIST = {
    "keluarga",
    "kerja",
    "kertas",
    "kepala",
    "keras",
    "kelas",
    "ketika",
    "kembali",
    "kemudian",
    "kecap",
    "perang",
    "perak",
    "pertama",
    "perlu",
    "percaya",
    "perut",
    "peta",
    "pesan",
    "pekan",
    "pena",
}
_STOPWORDS = {
    "untuk",
    "yang",
    "dan",
    "di",
    "ke",
    "dari",
    "dengan",
    "kepada",
    "pada",
    "saat",
    "ketika",
    "agar",
    "supaya",
    "bagi",
    "itu",
    "ini",
    "ada",
    "atau",
    "juga",
    "akan",
    "sudah",
    "telah",
    "oleh",
    "dalam",
    "the",
    "a",
    "an",
    "of",
    "for",
    "to",
    "in",
    "on",
    "and",
    "or",
    "with",
    "when",
    "is",
    "are",
}


def _is_stopword(original: str, stemmed: str) -> bool:
    return original in _STOPWORDS or stemmed in _STOPWORDS


def _strip_tashkeel_like(text: str) -> str:
    s = _TASHKEEL.sub("", text)
    s = s.replace("\u0640", "")
    s = _ALIF_VARIANTS.sub("\u0627", s)
    s = s.replace("\u0649", "\u064A")
    s = s.replace("\u06DF", "").replace("\u06DD", "")
    return s


def _restore_elision(prefix: str, stem: str) -> str:
    if not stem:
        return stem
    if prefix in ("peny", "meny"):
        if not stem.startswith("s"):
            return "s" + stem
    elif prefix in ("peng", "meng"):
        if stem[0] == "e" and len(stem) > 1:
            return stem[1:]
        if stem[0] in "aiou" and not stem.startswith("k"):
            return "k" + stem
    elif prefix in ("pem", "mem"):
        if stem[0] in _VOWELS:
            return "p" + stem
    elif prefix in ("pen", "men"):
        if stem[0] in _VOWELS:
            return "t" + stem
    return stem


def _try_prefix(token: str) -> str | None:
    """Apply the longest matching prefix. None means it over-stripped."""
    if token in _ROOT_WHITELIST:
        return token
    for prefix in _PREFIXES:
        if not token.startswith(prefix):
            continue
        stem = _restore_elision(prefix, token[len(prefix) :])
        if len(stem) >= _MIN_STEM or stem in _ROOT_WHITELIST:
            return stem
        return None
    return token


def _strip_particle(token: str) -> str:
    for suffix in ("nya", "lah", "kah"):
        if token.endswith(suffix):
            stem = token[: -len(suffix)]
            if len(stem) >= _MIN_STEM:
                return stem
    return token


def _apply_prefixes(token: str) -> str | None:
    current = token
    applied = False
    for _ in range(8):
        if current in _ROOT_WHITELIST:
            return current
        nxt = _try_prefix(current)
        if nxt is None:
            return current if applied else None
        if nxt == current:
            return current
        current = nxt
        applied = True
    return current


def _stem_latin(token: str) -> str:
    if token in _ROOT_WHITELIST:
        return token
    token = _strip_particle(token)
    if token in _ROOT_WHITELIST:
        return token
    for suffix in ("kan", "an", "i"):
        if not token.endswith(suffix):
            continue
        tentative = token[: -len(suffix)]
        if len(tentative) < _MIN_STEM:
            continue
        stemmed = _apply_prefixes(tentative)
        if stemmed is None:
            continue
        if len(stemmed) >= _MIN_STEM or stemmed in _ROOT_WHITELIST:
            return stemmed
    stemmed = _apply_prefixes(token)
    if stemmed is None:
        return token
    return stemmed


def normalize(text: str) -> str:
    if not text:
        return ""
    s = text.lower()
    s = _HTML.sub("", s)
    s = _NON_ALNUM.sub(" ", s)
    s = _MULTI_SPACE.sub(" ", s).strip()
    if not s:
        return ""
    s = _strip_tashkeel_like(s)
    originals: list[str] = []
    kept: list[str] = []
    all_stop = True
    for token in s.split(" "):
        if not token:
            continue
        originals.append(token)
        if _ARABIC.search(token):
            kept.append(token)
            all_stop = False
        else:
            stemmed = _stem_latin(token)
            if _is_stopword(token, stemmed):
                continue
            kept.append(stemmed)
            all_stop = False
    if not originals:
        return ""
    if all_stop:
        return " ".join(originals)
    return " ".join(kept)


def normalize_for_index(text: str) -> str:
    """Lowercase tokens plus their stems, for FTS document text."""
    if not text:
        return ""
    s = text.lower()
    s = _HTML.sub("", s)
    s = _NON_ALNUM.sub(" ", s)
    s = _MULTI_SPACE.sub(" ", s).strip()
    if not s:
        return ""
    s = _strip_tashkeel_like(s)
    originals: list[str] = []
    kept: list[str] = []
    all_stop = True
    for token in s.split(" "):
        if not token:
            continue
        originals.append(token)
        if _ARABIC.search(token):
            if token not in kept:
                kept.append(token)
            all_stop = False
            continue
        stemmed = _stem_latin(token)
        if _is_stopword(token, stemmed):
            continue
        if token not in kept:
            kept.append(token)
        if stemmed != token and stemmed not in kept:
            kept.append(stemmed)
        all_stop = False
    if not originals:
        return ""
    if all_stop:
        return " ".join(originals)
    return " ".join(kept)
