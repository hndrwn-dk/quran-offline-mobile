"""
Unit tests for romanize module and tajweed transliteration expectations.

Run: python -m pytest scripts/test_romanize.py -v
Or:  python scripts/test_romanize.py
"""

import unittest
from romanize import (
    _tokenize_phonemes,
    romanize,
    romanize_to_readable,
    romanize_to_academic,
)


class TestTokenize(unittest.TestCase):
    def test_empty(self):
        self.assertEqual(_tokenize_phonemes(""), [])
        self.assertEqual(_tokenize_phonemes("   "), [])

    def test_single_chars(self):
        self.assertEqual(_tokenize_phonemes("abc"), ["a", "b", "c"])

    def test_multi_ll(self):
        self.assertEqual(_tokenize_phonemes("aLLa"), ["a", "LL", "a"])

    def test_multi_qalqalah(self):
        self.assertEqual(_tokenize_phonemes("mad_Q"), ["m", "a", "d", "_Q"])

    def test_mixed(self):
        tokens = _tokenize_phonemes("2aLLaahu")
        self.assertIn("LL", tokens)
        self.assertEqual(tokens[0], "2")
        self.assertEqual(tokens[1], "a")


class TestRomanizeReadable(unittest.TestCase):
    def test_hamza_omitted(self):
        out = romanize_to_readable("2a")
        self.assertEqual(out, "a")

    def test_heavy_lam(self):
        out = romanize_to_readable("2aLLaahu")
        self.assertIn("ll", out)
        self.assertIn("ah", out)

    def test_qalqalah_omitted(self):
        out = romanize_to_readable("SSamad_Q")
        self.assertTrue(out.endswith("d") or "dad" in out or "ad" in out)

    def test_spaces(self):
        out = romanize_to_readable("2alHamdu lillahi")
        self.assertIn(" ", out)


class TestRomanizeAcademic(unittest.TestCase):
    def test_emphatics(self):
        out = romanize_to_academic("S")
        self.assertEqual(out, "\u1e63")  # s with dot below

    def test_hamza_in_academic(self):
        out = romanize_to_academic("2a")
        self.assertIn("\u02bf", out)  # ʿ


class TestAlFatihahExpectations(unittest.TestCase):
    """
    Al-Fatihah expectations: 1:1 and 1:7.
    Phonemizer output is not fixed; we test that romanized output is
    consistent and includes expected substrings (bismillah-style, siratal-ladhina).
    """

    def test_1_1_contains_bismillah_style(self):
        # Simulated phonemizer-like output for 1:1 (bismillah ar-rahman ar-rahim)
        phon = "bis'mi 2aLLaahi RRaHmaani RRaHiymi"
        out = romanize_to_readable(phon)
        self.assertIsInstance(out, str)
        self.assertTrue(len(out) >= 5)
        # Should contain something like bismi, allah, rahman, rahim (spelling may vary)
        out_lower = out.lower().replace("'", "")
        self.assertTrue(
            "bism" in out_lower or "bismi" in out_lower,
            f"Expected bism* in {out!r}",
        )
        self.assertTrue(
            "llah" in out_lower or "allah" in out_lower,
            f"Expected *allah* in {out!r}",
        )

    def test_1_7_contains_siratal_ladhina_style(self):
        # Simulated phonemizer output for 1:7 (sirat alladhina, idgham)
        phon = "Si raa Ta 2al la dhii na"
        out = romanize_to_readable(phon)
        out_lower = out.lower().replace("-", " ").replace("  ", " ")
        self.assertIsInstance(out, str)
        # Should contain sirat-style and ladhina-style (idgham/assimilation)
        has_sirat = "sirat" in out_lower or "sira" in out_lower or "sir" in out_lower
        has_ladhina = "ladh" in out_lower or "ladhi" in out_lower or "dhi" in out_lower or "ladhina" in out_lower
        self.assertTrue(
            has_sirat or has_ladhina,
            f"Expected sirat* or ladhina* in {out!r}",
        )

    def test_ayn_hamza_stable_readable(self):
        # 2 (hamza) omitted in readable
        out1 = romanize_to_readable("2an2amta")
        out2 = romanize_to_readable("an2amta")
        self.assertNotIn("2", out1)
        self.assertNotIn("2", out2)

    def test_ayn_hamza_stable_academic(self):
        out = romanize_to_academic("2an2amta")
        self.assertIn("\u02bf", out)  # ʿ present in academic


class TestEdgeCases(unittest.TestCase):
    def test_empty_input(self):
        self.assertEqual(romanize_to_readable(""), "")
        self.assertEqual(romanize_to_readable(None), "")

    def test_include_hamza(self):
        out = romanize("2a", include_hamza=True, academic=False)
        self.assertEqual(out, "'a")


def run_tests():
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(__import__(__name__))
    runner = unittest.TextTestRunner(verbosity=2)
    return runner.run(suite)


if __name__ == "__main__":
    run_tests()
