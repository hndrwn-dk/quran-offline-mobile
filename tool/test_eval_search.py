#!/usr/bin/env python3
"""unittest for tool/eval_search.py metric maths on a fixture index."""

from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

from eval_search import evaluate, keyword_search, load_queries, mrr, recall_at_k


def _fixture_index(path: Path) -> None:
    con = sqlite3.connect(path)
    con.execute(
        "CREATE TABLE docs (doc_id TEXT PRIMARY KEY, type TEXT, lang TEXT, ref_key TEXT, surah INTEGER, ayah_from INTEGER, ayah_to INTEGER, title TEXT, body_norm TEXT)"
    )
    con.execute(
        "CREATE VIRTUAL TABLE docs_fts USING fts5(title, body_norm, content='docs', content_rowid='rowid')"
    )

    def add(doc_id: str, type_: str, body: str) -> None:
        con.execute(
            "INSERT INTO docs(doc_id, type, lang, ref_key, surah, ayah_from, ayah_to, title, body_norm) VALUES (?,?,?,?,?,?,?,?,?)",
            (doc_id, type_, "id", doc_id, 1, 1, 1, doc_id, body),
        )
        rowid = con.execute("SELECT last_insert_rowid()").fetchone()[0]
        con.execute(
            "INSERT INTO docs_fts(rowid, title, body_norm) VALUES (?,?,?)",
            (rowid, doc_id, body),
        )

    add("ayah:1:1:id", "ayah", "alpha alpha alpha unique")
    add("ayah:1:2:id", "ayah", "alpha alpha shared")
    add("ayah:1:3:id", "ayah", "alpha")
    add("dua:one:id", "dua", "beta only")
    con.commit()
    con.close()


class MetricMathTest(unittest.TestCase):
    def test_recall_and_mrr_known_ranking(self) -> None:
        ranked = ["ayah:1:1:id", "ayah:1:2:id"]
        self.assertEqual(recall_at_k(ranked, ["ayah:1:1:id"]), 1.0)
        self.assertEqual(mrr(ranked, ["ayah:1:1:id"]), 1.0)
        self.assertEqual(mrr(ranked, ["ayah:1:2:id"]), 0.5)
        self.assertEqual(recall_at_k(ranked, ["missing"]), 0.0)
        self.assertEqual(mrr(ranked, ["missing"]), 0.0)
        self.assertEqual(recall_at_k([], []), 1.0)
        self.assertEqual(mrr(["ayah:1:1:id"], []), 0.0)

    def test_evaluate_aggregates(self) -> None:
        queries = [
            {"q": "a", "lang": "id", "expect": ["ayah:1:1:id"]},
            {"q": "b", "lang": "id", "expect": ["ayah:1:2:id"]},
            {"q": "c", "lang": "id", "expect": ["missing"]},
        ]
        ranked = [
            [("ayah:1:1:id", "ayah", 1.0)],
            [("ayah:1:1:id", "ayah", 1.0), ("ayah:1:2:id", "ayah", 0.5)],
            [],
        ]
        report = evaluate(queries, ranked)
        self.assertEqual(report["n"], 3)
        self.assertAlmostEqual(report["recall@5"], (1.0 + 1.0 + 0.0) / 3)
        self.assertAlmostEqual(report["mrr"], (1.0 + 0.5 + 0.0) / 3)
        self.assertAlmostEqual(report["empty_state_rate"], 1.0 / 3)
        self.assertEqual(report["per_type"]["ayah"]["queries"], 2)
        self.assertEqual(len(report["worst_misses"]), 1)
        self.assertEqual(report["worst_misses"][0]["q"], "c")


class FixtureIndexTest(unittest.TestCase):
    def test_keyword_search_ranks_stronger_match_first(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "fix.sqlite"
            _fixture_index(db)
            con = sqlite3.connect(db)
            try:
                hits = keyword_search(con, "alpha", "id")
            finally:
                con.close()
            self.assertGreaterEqual(len(hits), 2)
            ids = [h[0] for h in hits]
            self.assertEqual(ids[0], "ayah:1:1:id")
            self.assertIn("ayah:1:2:id", ids)
            self.assertTrue(all(h[2] >= 0.25 for h in hits))

    def test_below_threshold_and_empty_query(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "fix.sqlite"
            _fixture_index(db)
            con = sqlite3.connect(db)
            try:
                self.assertEqual(keyword_search(con, "zzz-nomatch", "id"), [])
                self.assertEqual(keyword_search(con, "   ", "id"), [])
            finally:
                con.close()


class QueriesFileTest(unittest.TestCase):
    def test_example_queries_schema(self) -> None:
        path = Path(__file__).resolve().parent / "eval" / "queries.json"
        rows = load_queries(path)
        self.assertEqual(len(rows), 3)
        for row in rows:
            self.assertIn("q", row)
            self.assertIn("lang", row)
            self.assertIn("expect", row)
            self.assertIsInstance(row["expect"], list)
