import json
import tempfile
import unittest
from pathlib import Path

import extract_dua_ayat as x
from generate_quran_json import EXPECTED_AYAHS

# Real-shaped samples (text_uthmani lineage). Only used as test fixtures.
RABBANA_2_201 = "وَمِنْهُم مَّن يَقُولُ رَبَّنَآ ءَاتِنَا فِى ٱلدُّنْيَا حَسَنَةً"
RABB_1_2 = "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ"
RABBI_20_25 = "قَالَ رَبِّ ٱشْرَحْ لِى صَدْرِى"
YA_RABBI_25_30 = "وَقَالَ ٱلرَّسُولُ يَٰرَبِّ إِنَّ قَوْمِى ٱتَّخَذُوا۟"


def verse(s, a, ar="نص", tr_id="teks", tr_en="text"):
    return {"s": s, "a": a, "ar": ar, "tr": {"id": tr_id, "en": tr_en, "zh": "", "ja": ""}, "m": {}}


def make_corpus(root: Path, overrides: dict) -> Path:
    qdir = root / "quran"
    qdir.mkdir()
    for s in range(1, 115):
        verses = []
        for a in range(1, EXPECTED_AYAHS[s - 1] + 1):
            verses.append(overrides.get((s, a), verse(s, a)))
        (qdir / f"s{s:03d}.json").write_text(json.dumps(verses, ensure_ascii=False), encoding="utf-8")
    (qdir / "manifest_multi.json").write_text(json.dumps({"version": "test"}), encoding="utf-8")
    return qdir


class NormalizeTest(unittest.TestCase):
    def test_rabbana_normalizes(self):
        self.assertIn("ربنا", x.normalize_arabic(RABBANA_2_201).split())

    def test_ya_rabbi_normalizes(self):
        self.assertIn("يرب", x.normalize_arabic(YA_RABBI_25_30).split())

    def test_clean_translation_strips_footnotes(self):
        self.assertEqual(x.clean_translation("1. Ya Tuhan kami<sup foot_note=12>1</sup>"), "Ya Tuhan kami")


class DetectTest(unittest.TestCase):
    def test_rabbana_with_vocative_is_high(self):
        _, conf = x.detect_signals(RABBANA_2_201, "“Ya Tuhan kami, berilah kami kebaikan", "Our Lord, give us")
        self.assertEqual(conf, "high")

    def test_rabb_al_alamin_is_not_doa(self):
        _, conf = x.detect_signals(RABB_1_2, "Segala puji bagi Allah, Tuhan seluruh alam.", "Lord of the worlds")
        self.assertIsNone(conf)

    def test_vocative_rabbi_needs_translation(self):
        _, conf = x.detect_signals(RABBI_20_25, "Dia (Musa) berkata, “Ya Tuhanku, lapangkanlah dadaku,”", "My Lord")
        self.assertEqual(conf, "high")
        _, conf2 = x.detect_signals(RABBI_20_25, "Dia berkata, lapangkanlah", "He said")
        self.assertIsNone(conf2)

    def test_strong_arabic_without_translation_is_medium(self):
        _, conf = x.detect_signals(YA_RABBI_25_30, "Rasul berkata", "The Messenger said")
        self.assertEqual(conf, "medium")


class ExtractBuildTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        voc = dict(tr_id="Ya Tuhan kami, ampunilah", tr_en="Our Lord, forgive")
        self.qdir = make_corpus(
            root,
            {
                (1, 2): verse(1, 2, RABB_1_2, "Tuhan seluruh alam", "Lord of the worlds"),
                (2, 201): verse(2, 201, RABBANA_2_201, **voc),
                (3, 191): verse(3, 191, RABBANA_2_201, **voc),
                (3, 192): verse(3, 192, RABBANA_2_201, **voc),
                (3, 193): verse(3, 193, RABBANA_2_201, **voc),
                (15, 36): verse(15, 36, RABBI_20_25, "Ya Tuhanku, tangguhkanlah", "My Lord"),
            },
        )
        self.catalog = root / "duas_catalog.json"
        self.catalog.write_text(
            json.dumps({"version": 1, "entries": [{"id": "dua_2_201", "ayahRefs": [{"surah": 2, "from": 201}]}]}),
            encoding="utf-8",
        )
        self.review = root / "review.json"
        self.out = root / "out.json"
        self.common = ["--quran-dir", str(self.qdir), "--dua-catalog", str(self.catalog), "--review-file", str(self.review)]

    def tearDown(self):
        self.tmp.cleanup()

    def extract(self):
        x.main(["extract", *self.common])
        return json.loads(self.review.read_text(encoding="utf-8"))

    def test_extract_groups_and_flags(self):
        doc = self.extract()
        keys = [g["group_key"] for g in doc["groups"]]
        self.assertEqual(keys, ["2:201-201", "3:191-193", "15:36-36"])
        by_key = {g["group_key"]: g for g in doc["groups"]}
        self.assertTrue(by_key["2:201-201"]["in_dua_catalog"])
        self.assertEqual(by_key["2:201-201"]["dua_catalog_ids"], ["dua_2_201"])
        self.assertTrue(any("Iblis" in h for h in by_key["15:36-36"]["hints"]))
        self.assertEqual(by_key["3:191-193"]["ayat"][0]["ar"], RABBANA_2_201)  # verbatim
        self.assertTrue(all(g["review"]["decision"] == "pending" for g in doc["groups"]))

    def test_build_refuses_pending(self):
        self.extract()
        with self.assertRaises(SystemExit):
            x.main(["build", *self.common, "--out", str(self.out)])
        self.assertFalse(self.out.exists())

    def _approve(self, doc, key, **overrides):
        for g in doc["groups"]:
            if g["group_key"] == key:
                g["review"].update(
                    {
                        "decision": "approved",
                        "is_doa_lafaz": True,
                        "recommended_to_recite": True,
                        "category": "forgiveness",
                        "tags": ["ampunan"],
                        "need": {"id": "memohon ampunan", "en": "asking forgiveness"},
                        "reviewer": "tester",
                    }
                )
                g["review"].update(overrides)

    def test_build_writes_refs_only_and_keeps_reviews_on_reextract(self):
        doc = self.extract()
        self._approve(doc, "3:191-193", **{"from": 192})
        for g in doc["groups"]:
            if g["review"]["decision"] == "pending":
                g["review"]["decision"] = "rejected"
        doc["manual_additions"].append(
            {"surah": 21, "from": 87, "to": 87, "review": {
                "decision": "approved", "is_doa_lafaz": True, "recommended_to_recite": True,
                "category": "trials", "tags": ["kesulitan"], "need": {"id": "keluar dari kesulitan", "en": "relief"},
                "reviewer": "tester"}}
        )
        self.review.write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")

        doc2 = self.extract()  # re-run must keep decisions
        self.assertEqual({g["group_key"]: g["review"]["decision"] for g in doc2["groups"]}["3:191-193"], "approved")
        self.assertEqual(len(doc2["manual_additions"]), 1)

        x.main(["build", *self.common, "--out", str(self.out)])
        cat = json.loads(self.out.read_text(encoding="utf-8"))
        ids = [e["id"] for e in cat["entries"]]
        self.assertEqual(ids, ["qd_003_192_193", "qd_021_087_087"])
        text = self.out.read_text(encoding="utf-8")
        self.assertNotIn("ربنا", text)
        self.assertNotIn("\u0631\u064E\u0628\u0651", text)
        self.assertNotIn("Ya Tuhan", text)

    def test_build_rejects_invalid_approval(self):
        doc = self.extract()
        for g in doc["groups"]:
            g["review"]["decision"] = "rejected"
        self._approve(doc, "2:201-201", need={"id": "", "en": "x"})
        self.review.write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")
        with self.assertRaises(SystemExit):
            x.main(["build", *self.common, "--out", str(self.out)])

    def test_build_rejects_out_of_range(self):
        doc = self.extract()
        for g in doc["groups"]:
            g["review"]["decision"] = "rejected"
        self._approve(doc, "2:201-201", to=999)
        self.review.write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")
        with self.assertRaises(SystemExit):
            x.main(["build", *self.common, "--out", str(self.out)])


if __name__ == "__main__":
    unittest.main()
