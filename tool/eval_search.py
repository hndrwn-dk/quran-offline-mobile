#!/usr/bin/env python3
"""Offline keyword eval harness (spec §6.1 / §6.2). Keyword-only until GATE D0."""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path

from id_normalizer import normalize

MIN_SCORE_KEYWORD = 0.25
TOP_K = 5
# TODO(D0): hybrid scoring 0.4 * bm25_norm + 0.6 * cosine.

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_QUERIES = Path(__file__).resolve().parent / "eval" / "queries.json"
DEFAULT_INDEX = ROOT / "assets" / "ai" / "search_index.sqlite"


def load_queries(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict):
        data = data.get("queries") or []
    if not isinstance(data, list):
        raise SystemExit("queries.json must be a list of {q, lang, expect}")
    out = []
    for row in data:
        if not isinstance(row, dict) or "q" not in row:
            continue
        expect = row.get("expect") or []
        out.append(
            {
                "q": str(row["q"]),
                "lang": str(row.get("lang") or "id"),
                "expect": [str(x) for x in expect],
            }
        )
    return out


def recall_at_k(ranked_ids: list[str], expect: list[str], k: int = TOP_K) -> float:
    if not expect:
        return 1.0 if not ranked_ids else 0.0
    top = set(ranked_ids[:k])
    hit = sum(1 for e in expect if e in top)
    return hit / len(expect)


def mrr(ranked_ids: list[str], expect: list[str]) -> float:
    if not expect:
        return 1.0 if not ranked_ids else 0.0
    want = set(expect)
    for i, doc_id in enumerate(ranked_ids, start=1):
        if doc_id in want:
            return 1.0 / i
    return 0.0


def keyword_search(
    con: sqlite3.Connection,
    query: str,
    lang: str,
    *,
    limit: int = 100,
) -> list[tuple[str, str, float]]:
    match = normalize(query)
    if not match:
        return []
    rows = con.execute(
        """
        SELECT
          docs.doc_id AS doc_id,
          docs.type AS type,
          bm25(docs_fts) AS rank
        FROM docs_fts
        JOIN docs ON docs.rowid = docs_fts.rowid
        WHERE docs_fts MATCH ?
          AND docs.lang = ?
        ORDER BY rank
        LIMIT 100
        """,
        (match, lang),
    ).fetchall()
    if not rows:
        return []
    raw = [-float(r[2]) for r in rows]
    lo = min(raw)
    hi = max(raw)
    span = hi - lo
    hits: list[tuple[str, str, float]] = []
    for (doc_id, type_, _), score_raw in zip(rows, raw):
        score = 1.0 if span == 0 else (score_raw - lo) / span
        if score < MIN_SCORE_KEYWORD:
            continue
        hits.append((doc_id, type_, score))
        if len(hits) >= limit:
            break
    return hits


def evaluate(
    queries: list[dict],
    ranked: list[list[tuple[str, str, float]]],
) -> dict:
    recalls: list[float] = []
    mrrs: list[float] = []
    empty = 0
    per_type: dict[str, dict[str, float]] = {}
    misses: list[dict] = []

    for q, hits in zip(queries, ranked):
        ids = [h[0] for h in hits]
        rec = recall_at_k(ids, q["expect"])
        rr = mrr(ids, q["expect"])
        recalls.append(rec)
        mrrs.append(rr)
        if not ids:
            empty += 1
        types = {h[1] for h in hits}
        for t in types:
            bucket = per_type.setdefault(t, {"queries": 0, "recall_sum": 0.0})
            bucket["queries"] += 1
            bucket["recall_sum"] += rec
        missing = [e for e in q["expect"] if e not in ids[:TOP_K]]
        if missing:
            misses.append(
                {
                    "q": q["q"],
                    "lang": q["lang"],
                    "missing": missing,
                    "top": ids[:TOP_K],
                    "recall@5": rec,
                    "mrr": rr,
                }
            )

    n = len(queries) or 1
    misses.sort(key=lambda m: (m["recall@5"], m["mrr"], m["q"]))
    return {
        "n": len(queries),
        "recall@5": sum(recalls) / n if queries else 0.0,
        "mrr": sum(mrrs) / n if queries else 0.0,
        "empty_state_rate": empty / n if queries else 0.0,
        "per_type": {
            t: {
                "queries": v["queries"],
                "recall@5": v["recall_sum"] / v["queries"],
            }
            for t, v in sorted(per_type.items())
        },
        "worst_misses": misses[:20],
    }


def _print_report(report: dict) -> None:
    print(f"queries\t{report['n']}")
    print(f"recall@5\t{report['recall@5']:.3f}")
    print(f"mrr\t{report['mrr']:.3f}")
    print(f"empty_state_rate\t{report['empty_state_rate']:.3f}")
    print("per_type")
    for t, stats in report["per_type"].items():
        print(f"  {t}\tqueries={stats['queries']}\trecall@5={stats['recall@5']:.3f}")
    print("worst_misses")
    if not report["worst_misses"]:
        print("  (none)")
        return
    for miss in report["worst_misses"]:
        print(
            f"  {miss['q']!r} missing={miss['missing']} "
            f"top={miss['top']} recall@5={miss['recall@5']:.3f}"
        )


def run(
    *,
    queries_path: Path,
    index_path: Path,
) -> dict:
    queries = load_queries(queries_path)
    ranked: list[list[tuple[str, str, float]]] = []
    if not index_path.is_file():
        print(f"WARN: index not found at {index_path}; ranking empty", file=sys.stderr)
        ranked = [[] for _ in queries]
    else:
        con = sqlite3.connect(f"file:{index_path.as_posix()}?mode=ro", uri=True)
        try:
            for q in queries:
                ranked.append(keyword_search(con, q["q"], q["lang"]))
        finally:
            con.close()
    report = evaluate(queries, ranked)
    _print_report(report)
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Keyword search eval (no network)")
    parser.add_argument("--queries", type=Path, default=DEFAULT_QUERIES)
    parser.add_argument("--index", type=Path, default=DEFAULT_INDEX)
    args = parser.parse_args(argv)
    if not args.queries.is_file():
        raise SystemExit(f"missing queries file {args.queries}")
    run(queries_path=args.queries, index_path=args.index)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
