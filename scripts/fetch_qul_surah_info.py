#!/usr/bin/env python3
"""Fetch Surah Info (EN + ID) from QUL public preview pages into one JSON asset."""

from __future__ import annotations

import json
import re
import time
import urllib.request
from html import unescape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "quran" / "surah_info_qul.json"

EN_URL = "https://qul.tarteel.ai/resources/surah-info/3?surah={surah}"
ID_URL = "https://qul.tarteel.ai/resources/surah-info/454?surah={surah}"


def _strip_html(html: str) -> str:
    text = re.sub(r"<br\s*/?>", "\n", html, flags=re.I)
    text = re.sub(r"</p>", "\n\n", text, flags=re.I)
    text = re.sub(r"</h[1-6]>", "\n\n", text, flags=re.I)
    text = re.sub(r"</li>", "\n", text, flags=re.I)
    text = re.sub(r"<[^>]+>", "", text)
    text = unescape(text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _parse_preview(html: str) -> dict:
    match = re.search(
        r'id="tab-preview-pane"[^>]*>(.*?)</div>\s*<div[^>]*id="tab-help-pane"',
        html,
        flags=re.S,
    )
    if not match:
        return {"short": "", "sections": []}

    content = match.group(1)
    short_match = re.search(r'<p[^>]*>(.*?)</p>', content, flags=re.S)
    short = _strip_html(short_match.group(1)) if short_match else ""

    sections: list[dict[str, str]] = []
    parts = re.split(r"<h2[^>]*>(.*?)</h2>", content, flags=re.S)
    if len(parts) > 1:
        for i in range(1, len(parts), 2):
            title = _strip_html(parts[i])
            body_html = parts[i + 1] if i + 1 < len(parts) else ""
            body = _strip_html(body_html.split("<h2", 1)[0])
            if title and body:
                sections.append({"title": title, "body": body})

    if not short and sections:
        short = sections[0]["body"][:280]

    return {"short": short, "sections": sections}


def _fetch(url: str) -> str:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "quran-offline-mobile/1.0 (surah-info bundler)"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8", errors="replace")


def main() -> None:
    surahs: dict[str, dict] = {}

    for surah in range(1, 115):
        print(f"Fetching surah {surah}/114...")
        en_html = _fetch(EN_URL.format(surah=surah))
        time.sleep(0.15)
        id_html = _fetch(ID_URL.format(surah=surah))
        time.sleep(0.15)

        surahs[str(surah)] = {
            "en": _parse_preview(en_html),
            "id": _parse_preview(id_html),
        }

    payload = {
        "source": "Quranic Universal Library (Tarteel)",
        "sourceUrl": "https://qul.tarteel.ai/resources/surah-info",
        "englishResourceId": 3,
        "indonesianResourceId": 454,
        "languages": ["en", "id"],
        "surahs": surahs,
    }

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
