import unittest

from generate_quran_json import build_indexes, map_verse


class MapVerseTest(unittest.TestCase):
    def test_maps_uthmani_and_translations_omitting_tajweed(self):
        api = {
            "verse_key": "1:6",
            "text_uthmani": "صِرَٰطَ",
            "juz_number": 1,
            "page_number": 1,
            "hizb_number": 1,
            "ruku_number": 1,
            "translations": [
                {"resource_id": 20, "text": "en"},
                {"resource_id": 33, "text": "id"},
                {"resource_id": 109, "text": "zh"},
                {"resource_id": 35, "text": "ja"},
            ],
        }
        out = map_verse(api)
        self.assertEqual(out["s"], 1)
        self.assertEqual(out["a"], 6)
        self.assertEqual(out["ar"], "صِرَٰطَ")
        self.assertEqual(out["tr"], {"en": "en", "id": "id", "zh": "zh", "ja": "ja"})
        self.assertEqual(out["m"]["juz"], 1)
        self.assertNotIn("tj", out)
        self.assertNotIn("tl", out)
        self.assertNotIn("tl_tj", out)

    def test_rejects_tajweed_field(self):
        api = {
            "verse_key": "1:1",
            "text_uthmani": "x",
            "text_uthmani_tajweed": "<tajweed>",
            "juz_number": 1,
            "page_number": 1,
            "hizb_number": 1,
            "ruku_number": 1,
            "translations": [
                {"resource_id": 20, "text": "en"},
                {"resource_id": 33, "text": "id"},
                {"resource_id": 109, "text": "zh"},
                {"resource_id": 35, "text": "ja"},
            ],
        }
        with self.assertRaises(ValueError):
            map_verse(api)

    def test_index_ranges(self):
        verses = [
            {"s": 1, "a": 1, "m": {"juz": 1, "page": 1}},
            {"s": 1, "a": 2, "m": {"juz": 1, "page": 1}},
            {"s": 2, "a": 1, "m": {"juz": 1, "page": 2}},
        ]
        juz, pages = build_indexes(verses)
        self.assertEqual(juz["1"], [{"s": 1, "a1": 1, "a2": 2}, {"s": 2, "a1": 1, "a2": 1}])
        self.assertEqual(pages["1"], [{"s": 1, "a1": 1, "a2": 2}])
        self.assertEqual(pages["2"], [{"s": 2, "a1": 1, "a2": 1}])


if __name__ == "__main__":
    unittest.main()
