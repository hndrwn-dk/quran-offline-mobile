#!/usr/bin/env python3
"""Indonesian/English query normaliser (matching only). Version 1.

Mirrors docs/ai_search/ai-search-spec.md §6.1 steps 1–4.
Synonym expansion is query-time only and is not applied here.
"""

from __future__ import annotations

import re

NORMALIZER_VERSION = 1

_HTML = re.compile(r"<[^>]+>")
_NON_ALNUM = re.compile(r"[^\w]+", re.UNICODE)
_MULTI_SPACE = re.compile(r"\s+")
_ARABIC = re.compile(r"[\u0600-\u06FF]")
_TASHKEEL = re.compile(r"[\u064B-\u065F\u0670\u06D6-\u06ED]")
_ALIF_VARIANTS = re.compile(r"[\u0622\u0623\u0625\u0671]")

# Inflectional suffixes first, then prefixes, then derivational suffixes.
# Applying -kan/-an/-i before prefixes overstems dimakan (example in B1).
_SUFFIXES_INFLECT = ("nya", "lah", "kah")
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
    "pe",
    "ber",
    "ter",
    "di",
    "ke",
    "se",
)
_SUFFIXES_DERIV = ("kan", "an", "i")
_MIN_STEM = 3


def _strip_tashkeel_like(text: str) -> str:
    s = _TASHKEEL.sub("", text)
    s = s.replace("\u0640", "")
    s = _ALIF_VARIANTS.sub("\u0627", s)
    s = s.replace("\u0649", "\u064A")
    s = s.replace("\u06DF", "").replace("\u06DD", "")
    return s


def _strip_one_suffix(token: str, suffixes: tuple[str, ...]) -> str:
    for suffix in suffixes:
        if token.endswith(suffix):
            stem = token[: -len(suffix)]
            # -kan on "makan" would leave "ma"; do not fall through to -an.
            min_len = 4 if suffix == "kan" else _MIN_STEM
            if len(stem) >= min_len:
                return stem
            return token
    return token


def _strip_one_prefix(token: str) -> str:
    for prefix in _PREFIXES:
        if token.startswith(prefix):
            stem = token[len(prefix) :]
            if len(stem) >= _MIN_STEM:
                return stem
    return token


def _stem_latin(token: str) -> str:
    token = _strip_one_suffix(token, _SUFFIXES_INFLECT)
    token = _strip_one_prefix(token)
    token = _strip_one_suffix(token, _SUFFIXES_DERIV)
    return token


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
    out: list[str] = []
    for token in s.split(" "):
        if not token:
            continue
        if _ARABIC.search(token):
            out.append(token)
        else:
            out.append(_stem_latin(token))
    return " ".join(out)
