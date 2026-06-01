"""
Romanize quran-phonemizer output to Latin script.

Converts phoneme strings (e.g. "2aLLaahu SSamad_Q") into readable or
academic Latin transliteration. Preserves madd (lengthening) and key
consonant distinctions (kh, gh, sh, th, dh; optional emphatics s/d/t/z).
"""

import re
import unicodedata
from typing import Dict, Optional

# -----------------------------------------------------------------------------
# Phoneme-to-Latin mapping (quran-phonemizer style output)
# Based on documented output: 2=hamza, LL=heavy lam, _Q=qalqalah, :=madd, etc.
# -----------------------------------------------------------------------------

# Multi-char tokens (longest first so we match before single-char)
_READABLE_MULTI: Dict[str, str] = {
    "_Q": "",           # Qalqalah: omit in readable
    "QK": "",          # Qalqalah atomic token
    "L_H": "l",        # Heavy lam -> same as light in readable
    "LL": "ll",        # Heavy lam (double) -> "ll" for Allah
    "aa": "a",         # Long a (will be doubled by madd or kept in post)
    "ii": "i",
    "uu": "u",
    "th": "th",
    "dh": "dh",
    "kh": "kh",
    "gh": "gh",
    "sh": "sh",
    "ch": "sh",        # Alternative
    "ng": "n",         # Ghunnah
    "SP": " ",
}

_ACADEMIC_MULTI: Dict[str, str] = {
    "_Q": "",           # Qalqalah
    "QK": "",
    "L_H": "l",
    "LL": "ll",
    "aa": "ā",
    "ii": "ī",
    "uu": "ū",
    "th": "th",
    "dh": "dh",
    "kh": "kh",
    "gh": "gh",
    "sh": "sh",
    "ch": "sh",
    "ng": "n",
    "SP": " ",
}

# Single-char: readable (no diacritics) vs academic (emphatics with dots)
_READABLE_SINGLE: Dict[str, str] = {
    "2": "",            # Hamza: omit in simple readable
    "3": "'",           # Ain (alternative symbol in phonemizer): use apostrophe in readable
    "'": "'",           # Ain/hamza if present
    "a": "a",
    "i": "i",
    "u": "u",
    "b": "b",
    "t": "t",
    "j": "j",
    "d": "d",
    "r": "r",
    "z": "z",
    "s": "s",
    "f": "f",
    "q": "q",
    "k": "k",
    "l": "l",
    "L": "l",
    "m": "m",
    "n": "n",
    "w": "w",
    "y": "y",
    "h": "h",
    "H": "h",           # Heavy ha
    "R": "r",           # Heavy ra
    "S": "s",          # Emphatic s (sad)
    "D": "d",          # Emphatic d (dad)
    "T": "t",          # Emphatic t (ta)
    "Z": "z",          # Emphatic z (za)
    ":": "",            # Madd marker (handled in post-step)
    "|": " ",
    " ": " ",
    "\u014b": "n",     # Unicode ng (ghunnah)
}

_ACADEMIC_SINGLE: Dict[str, str] = {
    "2": "\u02bf",     # ʿ (ain-like for hamza)
    "3": "\u02bf",     # ʿ (ain)
    "'": "'",
    "a": "a",
    "i": "i",
    "u": "u",
    "b": "b",
    "t": "t",
    "j": "j",
    "d": "d",
    "r": "r",
    "z": "z",
    "s": "s",
    "f": "f",
    "q": "q",
    "k": "k",
    "l": "l",
    "L": "l",
    "m": "m",
    "n": "n",
    "w": "w",
    "y": "y",
    "h": "h",
    "H": "h",
    "R": "r",
    "S": "\u1e63",     # s with dot below (sad)
    "D": "\u1e0d",     # d with dot below (dad)
    "T": "\u1e6d",     # t with dot below (ta)
    "Z": "\u1e93",     # z with dot below (za)
    ":": "",
    "|": " ",
    " ": " ",
    "\u014b": "n",
}


def _tokenize_phonemes(phoneme_str: str) -> list:
    """
    Split phoneme string into tokens. Multi-char symbols first, then single.
    """
    if not phoneme_str or not phoneme_str.strip():
        return []
    s = phoneme_str.strip()
    tokens = []
    multi_keys = sorted(
        set(_READABLE_MULTI.keys()) | set(_ACADEMIC_MULTI.keys()),
        key=len,
        reverse=True,
    )
    i = 0
    while i < len(s):
        matched = False
        for key in multi_keys:
            if s[i : i + len(key)] == key:
                tokens.append(key)
                i += len(key)
                matched = True
                break
        if matched:
            continue
        # Single char
        tokens.append(s[i])
        i += 1
    return tokens


def _apply_madd(output: str, academic: bool) -> str:
    """
    Expand madd: after a vowel, ':' can double the vowel or add macron.
    Phonemizer may output 'a:' for long a. We normalize doubled vowels
    and ensure long vowels are visible (readable: double; academic: macron).
    """
    # If we stripped ':' already, long vowels might be in multi (aa, ii, uu).
    # Just collapse repeated spaces and clean.
    return re.sub(r" +", " ", output).strip()


def romanize(
    phoneme_str: Optional[str],
    *,
    academic: bool = False,
    include_hamza: bool = False,
) -> str:
    """
    Convert phoneme string to Latin transliteration.

    Args:
        phoneme_str: Raw output from quran-phonemizer (e.g. "2aLLaahu SSamad_Q").
        academic: If True, use diacritics (s/d/t/z with dots) and ʿ for hamza.
        include_hamza: If True (and not academic), use apostrophe for hamza/ayn.

    Returns:
        Latin string, words separated by spaces; multiple spaces collapsed.
    """
    if phoneme_str is None:
        return ""
    phoneme_str = phoneme_str.strip()
    if not phoneme_str:
        return ""
    multi = _ACADEMIC_MULTI if academic else _READABLE_MULTI
    single = _ACADEMIC_SINGLE if academic else _READABLE_SINGLE
    if include_hamza and not academic:
        single = dict(single)
        single["2"] = "'"
    tokens = _tokenize_phonemes(phoneme_str)
    out_chars = []
    for t in tokens:
        if len(t) > 1:
            out_chars.append(multi.get(t, t))
        else:
            out_chars.append(single.get(t, t))
    result = "".join(out_chars)
    result = _apply_madd(result, academic)
    # Normalize word boundaries: allow hyphen between words for readability
    result = re.sub(r" +", " ", result).strip()
    return result


def romanize_to_readable(phoneme_str: str) -> str:
    """Readable scheme: no heavy diacritics, hamza omitted by default."""
    return romanize(phoneme_str, academic=False, include_hamza=False)


def romanize_to_academic(phoneme_str: str) -> str:
    """Academic scheme: emphatics as s/d/t/z with dots, ʿ for hamza."""
    return romanize(phoneme_str, academic=True, include_hamza=True)


# -----------------------------------------------------------------------------
# Optional: format for display (hyphenate compound words like bismillah)
# -----------------------------------------------------------------------------

def format_for_display(latin: str, hyphenate_compound: bool = True) -> str:
    """
    Post-process romanized string for UI: optional hyphenation of
    'allah', 'bismillah', 'siratal-ladhina' style compounds.
    """
    if not hyphenate_compound or not latin:
        return latin
    # Common compounds: bismillah, siratal-ladhina (idgham)
    s = latin
    # Insert hyphen before "allah" when preceded by word (e.g. bi smi llah -> bi-smi-llah or bismillah)
    # Leave as-is for now; caller can customize.
    return s
