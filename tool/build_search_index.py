#!/usr/bin/env python3
"""Build assets/ai/search_index.sqlite from local bundled sources. Offline, stdlib only."""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

from id_normalizer import NORMALIZER_VERSION, normalize

SIZE_BUDGET_BYTES = 20 * 1024 * 1024
SCHEMA_VERSION = "1"

_HTML = re.compile(r"<[^>]+>")
_SUP = re.compile(r"<sup\b[^>]*>.*?</sup>", re.IGNORECASE | re.DOTALL)
_LEADING_NUM = re.compile(r"^\d+\.\s*")


def strip_html(text: str) -> str:
    return _HTML.sub(" ", text or "")


def clean_translation(text: str | None) -> str:
    if not text:
        return ""
    s = _SUP.sub("", text)
    s = _LEADING_NUM.sub("", s)
    return s.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _warn_skip(path: Path) -> None:
    print(f"warning: missing {path}, skipping", file=sys.stderr)


def _insert_doc(
    cur: sqlite3.Cursor,
    *,
    doc_id: str,
    type_: str,
    lang: str,
    ref_key: str,
    surah: int | None,
    ayah_from: int | None,
    ayah_to: int | None,
    title: str,
    body: str,
    refs: list[tuple[int, int]],
) -> None:
    title_n = normalize(title)
    body_n = normalize(body)
    cur.execute(
        """
        INSERT INTO docs (
          doc_id, type, lang, ref_key, surah, ayah_from, ayah_to, title, body_norm
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (doc_id, type_, lang, ref_key, surah, ayah_from, ayah_to, title_n, body_n),
    )
    rowid = cur.lastrowid
    cur.execute(
        "INSERT INTO docs_fts(rowid, title, body_norm) VALUES (?, ?, ?)",
        (rowid, title_n, body_n),
    )
    for s, a in refs:
        cur.execute(
            "INSERT INTO doc_refs(doc_id, surah, ayah) VALUES (?, ?, ?)",
            (doc_id, s, a),
        )


def _init_db(path: Path) -> sqlite3.Connection:
    if path.exists():
        path.unlink()
    path.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(path)
    cur = con.cursor()
    cur.execute(
        "CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)"
    )
    cur.execute(
        """
        CREATE TABLE docs (
          doc_id     TEXT PRIMARY KEY,
          type       TEXT NOT NULL,
          lang       TEXT NOT NULL,
          ref_key    TEXT NOT NULL,
          surah      INTEGER,
          ayah_from  INTEGER,
          ayah_to    INTEGER,
          title      TEXT NOT NULL,
          body_norm  TEXT NOT NULL
        )
        """
    )
    cur.execute(
        """
        CREATE VIRTUAL TABLE docs_fts USING fts5(
          title,
          body_norm,
          content='docs',
          content_rowid='rowid',
          tokenize='unicode61 remove_diacritics 2'
        )
        """
    )
    cur.execute(
        """
        CREATE TABLE doc_refs (
          doc_id TEXT NOT NULL,
          surah INTEGER NOT NULL,
          ayah INTEGER NOT NULL
        )
        """
    )
    cur.execute("CREATE INDEX idx_doc_refs_sa ON doc_refs(surah, ayah)")
    con.commit()
    return con


def _add_ayahs(cur: sqlite3.Cursor, quran_dir: Path) -> int:
    count = 0
    found = 0
    for s in range(1, 115):
        path = quran_dir / f"s{s:03d}.json"
        if not path.is_file():
            continue
        found += 1
        verses = load_json(path)
        for v in verses:
            surah = int(v["s"])
            ayah = int(v["a"])
            tr = v.get("tr") or {}
            for lang in ("id", "en"):
                body = clean_translation(tr.get(lang))
                if not body:
                    continue
                ref = f"{surah}:{ayah}"
                _insert_doc(
                    cur,
                    doc_id=f"ayah:{surah}:{ayah}:{lang}",
                    type_="ayah",
                    lang=lang,
                    ref_key=ref,
                    surah=surah,
                    ayah_from=ayah,
                    ayah_to=ayah,
                    title=ref,
                    body=body,
                    refs=[(surah, ayah)],
                )
                count += 1
    if found == 0:
        raise SystemExit(f"no s###.json files in {quran_dir}")
    if found < 114:
        print(f"warning: found {found}/114 surah JSON files", file=sys.stderr)
    return count


def _parse_ayah_key(key: str) -> tuple[int, int] | None:
    parts = (key or "").split(":")
    if len(parts) != 2:
        return None
    try:
        return int(parts[0]), int(parts[1])
    except ValueError:
        return None


def _add_tafsir(cur: sqlite3.Cursor, path: Path, lang: str) -> int:
    con = sqlite3.connect(path)
    rows = list(
        con.execute("SELECT ayah_key, group_ayah_key, text FROM tafsir")
    )
    con.close()
    groups: dict[str, list[tuple[str, str]]] = {}
    for ayah_key, group_key, text in rows:
        g = group_key or ayah_key
        groups.setdefault(g, []).append((ayah_key, text or ""))
    count = 0
    for group_key, items in groups.items():
        refs: list[tuple[int, int]] = []
        bodies: list[str] = []
        for ayah_key, text in items:
            parsed = _parse_ayah_key(ayah_key)
            if parsed:
                refs.append(parsed)
            bodies.append(strip_html(text))
        if not refs:
            parsed = _parse_ayah_key(group_key)
            if parsed:
                refs.append(parsed)
        if not refs:
            continue
        refs = sorted(set(refs))
        surah = refs[0][0]
        ayah_from = min(a for _, a in refs)
        ayah_to = max(a for _, a in refs)
        body = " ".join(bodies)
        _insert_doc(
            cur,
            doc_id=f"tafsir:{lang}:{surah}:{ayah_from}",
            type_="tafsir",
            lang=lang,
            ref_key=f"{surah}:{ayah_from}",
            surah=surah,
            ayah_from=ayah_from,
            ayah_to=ayah_to,
            title=f"{surah}:{ayah_from}-{ayah_to}",
            body=body,
            refs=refs,
        )
        count += 1
    return count


def _add_surah_info(cur: sqlite3.Cursor, path: Path, lang: str) -> int:
    con = sqlite3.connect(path)
    rows = list(
        con.execute("SELECT surah_number, text, short_text FROM surah_infos")
    )
    con.close()
    count = 0
    for surah, text, short in rows:
        body = strip_html((text or "") + " " + (short or ""))
        if not body.strip():
            continue
        _insert_doc(
            cur,
            doc_id=f"surah:{int(surah)}:{lang}",
            type_="surah_info",
            lang=lang,
            ref_key=str(int(surah)),
            surah=int(surah),
            ayah_from=None,
            ayah_to=None,
            title=f"surah {int(surah)}",
            body=body,
            refs=[],
        )
        count += 1
    return count


def _loc(obj: dict, lang: str) -> str:
    if not isinstance(obj, dict):
        return ""
    return str(obj.get(lang) or obj.get("en") or obj.get("id") or "")


def _refs_from_entry(entry: dict) -> list[tuple[int, int]]:
    refs: list[tuple[int, int]] = []
    raw = entry.get("ayahRefs") or []
    for r in raw:
        surah = int(r["surah"])
        frm = int(r["from"])
        to = int(r.get("to") or frm)
        for a in range(frm, to + 1):
            refs.append((surah, a))
    if not refs and "surah" in entry:
        surah = int(entry["surah"])
        frm = int(entry.get("from") or 1)
        to = int(entry.get("to") or frm)
        for a in range(frm, to + 1):
            refs.append((surah, a))
    return refs


def _add_localized_catalog(
    cur: sqlite3.Cursor,
    path: Path,
    *,
    type_: str,
    id_prefix: str,
    langs: tuple[str, ...],
    extra_fields: tuple[str, ...] = (),
) -> int:
    data = load_json(path)
    count = 0
    for entry in data.get("entries", []):
        eid = str(entry["id"])
        refs = _refs_from_entry(entry)
        surah = refs[0][0] if refs else None
        ayah_from = min(a for _, a in refs) if refs else None
        ayah_to = max(a for _, a in refs) if refs else None
        for lang in langs:
            title = _loc(entry.get("title") or {}, lang)
            parts = [
                title,
                _loc(entry.get("summary") or {}, lang),
            ]
            for field in extra_fields:
                parts.append(_loc(entry.get(field) or {}, lang))
            body = " ".join(p for p in parts if p)
            if not body.strip():
                continue
            _insert_doc(
                cur,
                doc_id=f"{id_prefix}:{eid}:{lang}",
                type_=type_,
                lang=lang,
                ref_key=eid,
                surah=surah,
                ayah_from=ayah_from,
                ayah_to=ayah_to,
                title=title or eid,
                body=body,
                refs=refs,
            )
            count += 1
    return count


def _add_asma(cur: sqlite3.Cursor, path: Path) -> int:
    data = load_json(path)
    count = 0
    for entry in data.get("entries", []):
        eid = str(entry.get("id") or entry.get("number"))
        number = entry.get("number")
        refs = _refs_from_entry(entry)
        surah = refs[0][0] if refs else None
        ayah_from = min(a for _, a in refs) if refs else None
        ayah_to = max(a for _, a in refs) if refs else None
        for lang in ("id", "en"):
            title = _loc(entry.get("title") or {}, lang)
            body = " ".join(
                [
                    title,
                    _loc(entry.get("summary") or {}, lang),
                    _loc(entry.get("reflection") or {}, lang),
                    str(number or ""),
                    str(entry.get("transliteration") or ""),
                ]
            )
            doc_id = f"asma:{number}:{lang}" if number is not None else f"asma:{eid}:{lang}"
            _insert_doc(
                cur,
                doc_id=doc_id,
                type_="asma",
                lang=lang,
                ref_key=str(number or eid),
                surah=surah,
                ayah_from=ayah_from,
                ayah_to=ayah_to,
                title=title or str(number or eid),
                body=body,
                refs=refs,
            )
            count += 1
    return count


def _verse_translations(quran_dir: Path) -> dict[tuple[int, int, str], str]:
    out: dict[tuple[int, int, str], str] = {}
    for s in range(1, 115):
        path = quran_dir / f"s{s:03d}.json"
        if not path.is_file():
            continue
        for v in load_json(path):
            surah = int(v["s"])
            ayah = int(v["a"])
            tr = v.get("tr") or {}
            for lang in ("id", "en"):
                text = clean_translation(tr.get(lang))
                if text:
                    out[(surah, ayah, lang)] = text
    return out


def _add_quran_dua(
    cur: sqlite3.Cursor,
    path: Path,
    verse_tr: dict[tuple[int, int, str], str],
) -> int:
    data = load_json(path)
    count = 0
    for entry in data.get("entries", []):
        eid = str(entry["id"])
        surah = int(entry["surah"])
        frm = int(entry["from"])
        to = int(entry.get("to") or frm)
        refs = [(surah, a) for a in range(frm, to + 1)]
        need = entry.get("need") or {}
        tags = entry.get("tags") or []
        for lang in ("id", "en"):
            title = str(need.get(lang) or need.get("en") or eid)
            verses = [
                verse_tr[(surah, a, lang)]
                for a in range(frm, to + 1)
                if (surah, a, lang) in verse_tr
            ]
            body = " ".join(
                [title, " ".join(str(t) for t in tags), " ".join(verses)]
            )
            _insert_doc(
                cur,
                doc_id=f"qdua:{eid}:{lang}",
                type_="quran_dua",
                lang=lang,
                ref_key=eid,
                surah=surah,
                ayah_from=frm,
                ayah_to=to,
                title=title,
                body=body,
                refs=refs,
            )
            count += 1
    return count


def build_index(
    *,
    quran_dir: Path,
    out_path: Path,
    id_tafsir: Path | None = None,
    en_tafsir: Path | None = None,
    include_en_tafsir: bool = False,
    id_surah_info: Path | None = None,
    en_surah_info: Path | None = None,
    dua_catalog: Path | None = None,
    asma_catalog: Path | None = None,
    science_catalog: Path | None = None,
    theme_catalog: Path | None = None,
    quran_dua_catalog: Path | None = None,
    max_bytes: int = SIZE_BUDGET_BYTES,
) -> dict:
    if not quran_dir.is_dir():
        raise SystemExit(f"missing quran dir {quran_dir}")
    con = _init_db(out_path)
    cur = con.cursor()
    counts: dict[str, int] = {}

    n = _add_ayahs(cur, quran_dir)
    if n:
        counts["ayah"] = n

    if id_tafsir is not None:
        if id_tafsir.is_file():
            counts["tafsir"] = counts.get("tafsir", 0) + _add_tafsir(cur, id_tafsir, "id")
        else:
            _warn_skip(id_tafsir)
    if include_en_tafsir and en_tafsir is not None:
        if en_tafsir.is_file():
            counts["tafsir"] = counts.get("tafsir", 0) + _add_tafsir(cur, en_tafsir, "en")
        else:
            _warn_skip(en_tafsir)

    if id_surah_info is not None:
        if id_surah_info.is_file():
            counts["surah_info"] = counts.get("surah_info", 0) + _add_surah_info(
                cur, id_surah_info, "id"
            )
        else:
            _warn_skip(id_surah_info)
    if en_surah_info is not None:
        if en_surah_info.is_file():
            counts["surah_info"] = counts.get("surah_info", 0) + _add_surah_info(
                cur, en_surah_info, "en"
            )
        else:
            _warn_skip(en_surah_info)

    if dua_catalog is not None:
        if dua_catalog.is_file():
            counts["dua"] = _add_localized_catalog(
                cur, dua_catalog, type_="dua", id_prefix="dua", langs=("id", "en")
            )
        else:
            _warn_skip(dua_catalog)
    if asma_catalog is not None:
        if asma_catalog.is_file():
            counts["asma"] = _add_asma(cur, asma_catalog)
        else:
            _warn_skip(asma_catalog)
    if science_catalog is not None:
        if science_catalog.is_file():
            counts["science"] = _add_localized_catalog(
                cur,
                science_catalog,
                type_="science",
                id_prefix="sci",
                langs=("id", "en"),
                extra_fields=("scienceNote",),
            )
        else:
            _warn_skip(science_catalog)
    if theme_catalog is not None:
        if theme_catalog.is_file():
            counts["theme"] = _add_localized_catalog(
                cur,
                theme_catalog,
                type_="theme",
                id_prefix="theme",
                langs=("id", "en"),
                extra_fields=("reflection",),
            )
        else:
            _warn_skip(theme_catalog)
    if quran_dua_catalog is not None:
        if quran_dua_catalog.is_file():
            counts["quran_dua"] = _add_quran_dua(
                cur, quran_dua_catalog, _verse_translations(quran_dir)
            )
        else:
            _warn_skip(quran_dua_catalog)

    manifest = quran_dir / "manifest_multi.json"
    manifest_version = ""
    if manifest.is_file():
        manifest_version = str(load_json(manifest).get("version") or "")
    built = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    for key, value in (
        ("schema_version", SCHEMA_VERSION),
        ("built_at_utc", built),
        ("quran_manifest_version", manifest_version),
        ("normalizer_version", str(NORMALIZER_VERSION)),
    ):
        cur.execute("INSERT INTO meta(key, value) VALUES (?, ?)", (key, value))

    con.commit()
    con.close()
    size = out_path.stat().st_size
    if size > max_bytes:
        out_path.unlink(missing_ok=True)
        raise SystemExit(
            f"search index exceeds {SIZE_BUDGET_BYTES} bytes (got {size})"
        )
    stats = {"counts": counts, "size": size, "path": str(out_path)}
    print("doc counts:", counts)
    print(f"index size: {size} bytes")
    return stats


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--quran-dir", default="assets/quran")
    parser.add_argument("--out", default="assets/ai/search_index.sqlite")
    parser.add_argument("--include-en-tafsir", action="store_true")
    args = parser.parse_args(argv)
    root = Path(".")
    build_index(
        quran_dir=Path(args.quran_dir),
        out_path=Path(args.out),
        id_tafsir=root / "assets/tafsir/id_as_saadi.sqlite",
        en_tafsir=root / "assets/tafsir/en_ibn_kathir.sqlite",
        include_en_tafsir=args.include_en_tafsir,
        id_surah_info=root / "assets/quran/surah_info/id_surah_info.sqlite",
        en_surah_info=root / "assets/quran/surah_info/en_surah_info.sqlite",
        dua_catalog=root / "assets/duas/duas_catalog.json",
        asma_catalog=root / "assets/asma/asmaul_husna_catalog.json",
        science_catalog=root / "assets/science/science_catalog.json",
        theme_catalog=root / "assets/themes/life_themes_catalog.json",
        quran_dua_catalog=root / "assets/ai/quran_dua_ayat_catalog.json",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
