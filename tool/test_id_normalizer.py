#!/usr/bin/env python3
"""unittest for tool/id_normalizer.py against shared vectors."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from id_normalizer import NORMALIZER_VERSION, normalize

_VECTORS = Path(__file__).resolve().parent / "fixtures" / "id_normalizer_vectors.json"


class NormalizeVersionTest(unittest.TestCase):
    def test_version_is_1(self) -> None:
        self.assertEqual(NORMALIZER_VERSION, 1)


class VectorFileTest(unittest.TestCase):
    def test_every_shared_vector(self) -> None:
        cases = json.loads(_VECTORS.read_text(encoding="utf-8"))
        self.assertGreaterEqual(len(cases), 1)
        for i, case in enumerate(cases):
            with self.subTest(i=i, inn=case["in"]):
                self.assertEqual(normalize(case["in"]), case["out"])


class EdgeCaseTest(unittest.TestCase):
    def test_empty_string(self) -> None:
        self.assertEqual(normalize(""), "")
        self.assertEqual(normalize("   "), "")

    def test_min_stem_length_3(self) -> None:
        # Prefix "di" would leave "a" (len 1); keep the token.
        self.assertEqual(normalize("dia"), "dia")
        # Suffix "i" would leave "an" (len 2); keep the token.
        self.assertEqual(normalize("ani"), "ani")

    def test_prefix_and_suffix_together(self) -> None:
        self.assertEqual(normalize("dikerjakan"), "kerja")
        self.assertEqual(normalize("pekerjaannya"), "kerja")


if __name__ == "__main__":
    unittest.main()
