#!/usr/bin/env python3
"""unittest for tool/build_search_index.py — fixtures only, never real assets."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from build_search_index import SIZE_BUDGET_BYTES, build_index


def _write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")


def _make_quran(root: Path) -> None:
    quran = root / "quran"
    quran.mkdir()
    _write_json(
        quran / "s001.json",
        [
            {
                "s": 1,
                "a": 1,
                "ar": "X",
                "tr": {
                    "id": "1. Pujian kepada tuhan",
                    "en": "1. Praise to the lord",
                },
            },
            {
                "s": 1,
                "a": 2,
                "ar": "Y",
                "tr": {"id": "Pemilik hari pembalasan", "en": "Master of the day"},
            },
        ],
    )
    _write_json(quran / "manifest_multi.json", {"version": "fixture-v1"})


def _make_tafsir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(path)
    con.execute(
        "CREATE TABLE tafsir (ayah_key TEXT, group_ayah_key TEXT, text TEXT)"
    )
    con.execute(
        "INSERT INTO tafsir VALUES ('1:1','1:1','<p>Grouped tafsir one</p>')"
    )
    con.execute(
        "INSERT INTO tafsir VALUES ('1:2','1:1','<p>Grouped tafsir two</p>')"
    )
    con.commit()
    con.close()


def _make_surah_info(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(path)
    con.execute(
        "CREATE TABLE surah_infos (surah_number INTEGER, text TEXT, short_text TEXT)"
    )
    con.execute(
        "INSERT INTO surah_infos VALUES (1, '<b>About surah</b>', 'short')"
    )
    con.commit()
    con.close()


def _make_dua(path: Path) -> None:
    _write_json(
        path,
        {
            "version": 1,
            "entries": [
                {
                    "id": "fixture_dua",
                    "title": {"id": "Judul doa", "en": "Dua title"},
                    "summary": {"id": "Ringkasan doa", "en": "Dua summary"},
                    "ayahRefs": [{"surah": 1, "from": 1, "to": 2}],
                }
            ],
        },
    )


class BuildIndexTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        _make_quran(self.root)
        self.out = self.root / "search_index.sqlite"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_ayah_docs_id_and_en(self) -> None:
        stats = build_index(
            quran_dir=self.root / "quran",
            out_path=self.out,
        )
        self.assertEqual(stats["counts"]["ayah"], 4)
        con = sqlite3.connect(self.out)
        ids = {
            row[0]
            for row in con.execute("SELECT doc_id FROM docs WHERE type='ayah'")
        }
        self.assertIn("ayah:1:1:id", ids)
        self.assertIn("ayah:1:1:en", ids)
        body = con.execute(
            "SELECT body_norm FROM docs WHERE doc_id='ayah:1:1:id'"
        ).fetchone()[0]
        self.assertNotIn("<", body)
        self.assertTrue(body.startswith("puji") or "puji" in body or "tuhan" in body)
        refs = con.execute(
            "SELECT COUNT(*) FROM doc_refs WHERE doc_id='ayah:1:1:id'"
        ).fetchone()[0]
        self.assertEqual(refs, 1)
        meta = dict(con.execute("SELECT key, value FROM meta"))
        self.assertEqual(meta["schema_version"], "1")
        self.assertEqual(meta["normalizer_version"], "3")
        self.assertEqual(meta["quran_manifest_version"], "fixture-v1")
        self.assertIn("built_at_utc", meta)
        n = con.execute(
            "SELECT count(*) FROM docs_fts WHERE docs_fts MATCH 'puji'"
        ).fetchone()[0]
        self.assertGreaterEqual(n, 1)
        con.close()

    def test_missing_optional_skipped(self) -> None:
        stats = build_index(
            quran_dir=self.root / "quran",
            out_path=self.out,
            dua_catalog=self.root / "missing_duas.json",
        )
        self.assertNotIn("dua", stats["counts"])

    def test_tafsir_groups_into_one_doc(self) -> None:
        tafsir = self.root / "tafsir" / "id_as_saadi.sqlite"
        _make_tafsir(tafsir)
        stats = build_index(
            quran_dir=self.root / "quran",
            out_path=self.out,
            id_tafsir=tafsir,
        )
        self.assertEqual(stats["counts"]["tafsir"], 1)
        con = sqlite3.connect(self.out)
        row = con.execute(
            "SELECT ayah_from, ayah_to, body_norm FROM docs WHERE type='tafsir'"
        ).fetchone()
        self.assertEqual(row[0], 1)
        self.assertEqual(row[1], 2)
        self.assertNotIn("<p>", row[2])
        ref_count = con.execute(
            "SELECT COUNT(*) FROM doc_refs WHERE doc_id LIKE 'tafsir:%'"
        ).fetchone()[0]
        self.assertEqual(ref_count, 2)
        con.close()

    def test_catalogs_and_surah_info(self) -> None:
        _make_dua(self.root / "duas.json")
        _make_surah_info(self.root / "id_surah_info.sqlite")
        stats = build_index(
            quran_dir=self.root / "quran",
            out_path=self.out,
            dua_catalog=self.root / "duas.json",
            id_surah_info=self.root / "id_surah_info.sqlite",
        )
        self.assertEqual(stats["counts"]["dua"], 2)
        self.assertEqual(stats["counts"]["surah_info"], 1)
        con = sqlite3.connect(self.out)
        refs = con.execute(
            "SELECT COUNT(*) FROM doc_refs WHERE doc_id LIKE 'dua:%'"
        ).fetchone()[0]
        self.assertEqual(refs, 4)
        con.close()

    def test_en_tafsir_default_off(self) -> None:
        en = self.root / "en_ibn_kathir.sqlite"
        _make_tafsir(en)
        stats = build_index(
            quran_dir=self.root / "quran",
            out_path=self.out,
            en_tafsir=en,
            include_en_tafsir=False,
        )
        self.assertNotIn("tafsir", stats["counts"])

    def test_quran_dua_body_includes_kemenag_translation(self) -> None:
        _write_json(
            self.root / "quran_dua.json",
            {
                "version": 1,
                "entries": [
                    {
                        "id": "qd_001_001_002",
                        "surah": 1,
                        "from": 1,
                        "to": 2,
                        "category": "faith",
                        "tags": ["pujian"],
                        "need": {
                            "id": "Saat memuji tuhan.",
                            "en": "When praising the lord.",
                        },
                        "recommendedToRecite": True,
                        "inDuaCatalog": False,
                    }
                ],
            },
        )
        stats = build_index(
            quran_dir=self.root / "quran",
            out_path=self.out,
            quran_dua_catalog=self.root / "quran_dua.json",
        )
        self.assertEqual(stats["counts"]["quran_dua"], 2)
        con = sqlite3.connect(self.out)
        body = con.execute(
            "SELECT body_norm FROM docs WHERE doc_id='qdua:qd_001_001_002:id'"
        ).fetchone()[0]
        self.assertIn("puji", body)
        self.assertIn("tuhan", body)
        self.assertIn("hari", body)
        n = con.execute(
            "SELECT count(*) FROM docs_fts WHERE docs_fts MATCH 'hari'"
        ).fetchone()[0]
        self.assertGreaterEqual(n, 1)
        con.close()

    def test_size_budget(self) -> None:
        with self.assertRaises(SystemExit) as ctx:
            build_index(
                quran_dir=self.root / "quran",
                out_path=self.out,
                max_bytes=10,
            )
        self.assertIn("20", str(SIZE_BUDGET_BYTES) + str(ctx.exception))
        self.assertIn("exceeds", str(ctx.exception).lower())


if __name__ == "__main__":
    unittest.main()
