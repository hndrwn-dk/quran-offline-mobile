#!/usr/bin/env python3
"""Generate assets/asma/asmaul_husna_catalog.json (99 names, curated ayah refs)."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "asma" / "asmaul_husna_catalog.json"

# (id, arabic, transliteration, id_meaning, en_meaning, zh_meaning, ja_meaning, ayah_refs)
# ayah_refs: list of (surah, from, to)
NAMES = [
    ("ar_rahman", "الرَّحْمَنُ", "Ar-Rahman", "Maha Pengasih", "The Most Merciful", "至仁", "慈悲あまねく", [(1, 1, 3), (55, 1, 1)]),
    ("ar_rahim", "الرَّحِيمُ", "Ar-Rahim", "Maha Penyayang", "The Especially Merciful", "至慈", "慈悲深き", [(1, 1, 3), (2, 163, 163)]),
    ("al_malik", "الْمَلِكُ", "Al-Malik", "Maha Merajai", "The King", "君王", "主権者", [(59, 23, 23), (20, 114, 114)]),
    ("al_quddus", "الْقُدُّوسُ", "Al-Quddus", "Maha Suci", "The Most Holy", "至洁", "聖なる", [(59, 23, 23), (62, 1, 1)]),
    ("as_salam", "السَّلَامُ", "As-Salam", "Maha Sejahtera", "The Source of Peace", "和平", "平安の源", [(59, 23, 23)]),
    ("al_mumin", "الْمُؤْمِنُ", "Al-Mu'min", "Maha Memberi Keamanan", "The Granter of Security", "赐安宁者", "安心を与える", [(59, 23, 23)]),
    ("al_muhaymin", "الْمُهَيْمِنُ", "Al-Muhaymin", "Maha Pemelihara", "The Guardian", "监护者", "見守る", [(59, 23, 23)]),
    ("al_aziz", "الْعَزِيزُ", "Al-Aziz", "Maha Perkasa", "The Almighty", "全能", "尊厳なる", [(59, 23, 23), (3, 6, 6)]),
    ("al_jabbar", "الْجَبَّارُ", "Al-Jabbar", "Maha Pemaksa", "The Compeller", "强制者", "修復する", [(59, 23, 23)]),
    ("al_mutakabbir", "الْمُتَكَبِّرُ", "Al-Mutakabbir", "Maha Megah", "The Supreme", "至尊", "偉大なる", [(59, 23, 23)]),
    ("al_khaliq", "الْخَالِقُ", "Al-Khaliq", "Maha Pencipta", "The Creator", "创造者", "創造者", [(59, 24, 24), (6, 102, 102)]),
    ("al_bari", "الْبَارِئُ", "Al-Bari", "Maha Melepaskan", "The Evolver", "造化者", "形作る", [(59, 24, 24)]),
    ("al_musawwir", "الْمُصَوِّرُ", "Al-Musawwir", "Maha Membentuk Rupa", "The Fashioner", "塑形者", "形を与える", [(59, 24, 24)]),
    ("al_ghaffar", "الْغَفَّارُ", "Al-Ghaffar", "Maha Pengampun", "The Ever-Forgiving", "至恕", "寛恕する", [(20, 82, 82), (38, 66, 66)]),
    ("al_qahhar", "الْقَهَّارُ", "Al-Qahhar", "Maha Menundukkan", "The Subduer", "征服者", "征服する", [(13, 16, 16), (39, 4, 4)]),
    ("al_wahhab", "الْوَهَّابُ", "Al-Wahhab", "Maha Pemberi", "The Bestower", "赐予者", "与える", [(3, 8, 8), (38, 35, 35)]),
    ("ar_razzaq", "الرَّزَّاقُ", "Ar-Razzaq", "Maha Pemberi Rezeki", "The Provider", "供给者", "糧を与える", [(51, 58, 58)]),
    ("al_fattah", "الْفَتَّاحُ", "Al-Fattah", "Maha Pembuka", "The Opener", "开启者", "開く", [(34, 26, 26)]),
    ("al_alim", "الْعَلِيمُ", "Al-Alim", "Maha Mengetahui", "The All-Knowing", "全知", "全知", [(2, 158, 158), (3, 18, 18)]),
    ("al_qabid", "الْقَابِضُ", "Al-Qabid", "Maha Menyempitkan", "The Withholder", "收缩者", "握る", [(2, 245, 245)]),
    ("al_basit", "الْبَاسِطُ", "Al-Basit", "Maha Melapangkan", "The Extender", "展开者", "広げる", [(2, 245, 245)]),
    ("al_khafid", "الْخَافِضُ", "Al-Khafid", "Maha Merendahkan", "The Abaser", "降卑者", "低める", [(56, 3, 3)]),
    ("ar_rafi", "الرَّافِعُ", "Ar-Rafi", "Maha Meninggikan", "The Exalter", "升高者", "高める", [(58, 11, 11)]),
    ("al_muizz", "الْمُعِزُّ", "Al-Mu'izz", "Maha Memuliakan", "The Honourer", "尊荣者", "尊び与える", [(3, 26, 26)]),
    ("al_mudhill", "الْمُذِلُّ", "Al-Mudhill", "Maha Menghinakan", "The Humiliator", "屈辱者", "辱める", [(3, 26, 26)]),
    ("as_sami", "السَّمِيعُ", "As-Sami", "Maha Mendengar", "The All-Hearing", "全听", "全聴", [(2, 127, 127), (2, 256, 256)]),
    ("al_basir", "الْبَصِيرُ", "Al-Basir", "Maha Melihat", "The All-Seeing", "全视", "全視", [(4, 58, 58), (42, 11, 11)]),
    ("al_hakam", "الْحَكَمُ", "Al-Hakam", "Maha Menetapkan", "The Judge", "裁决者", "裁く", [(6, 114, 114), (22, 56, 56)]),
    ("al_adl", "الْعَدْلُ", "Al-Adl", "Maha Adil", "The Utterly Just", "至公", "公正", [(6, 115, 115)]),
    ("al_latif", "اللَّطِيفُ", "Al-Latif", "Maha Lembut", "The Subtle", "微妙", "優しい", [(6, 103, 103), (31, 16, 16)]),
    ("al_khabir", "الْخَبِيرُ", "Al-Khabir", "Maha Mengenal", "The All-Aware", "全觉", "全覚", [(6, 18, 18), (34, 1, 1)]),
    ("al_halim", "الْحَلِيمُ", "Al-Halim", "Maha Penyantun", "The Forbearing", "至缓", "寛容", [(2, 225, 225), (7, 152, 152)]),
    ("al_azim", "الْعَظِيمُ", "Al-Azim", "Maha Agung", "The Magnificent", "至大", "偉大", [(2, 255, 255), (42, 4, 4)]),
    ("al_ghafur", "الْغَفُورُ", "Al-Ghafur", "Maha Pengampun", "The Forgiving", "至恕", "赦す", [(8, 69, 69), (41, 32, 32)]),
    ("ash_shakur", "الشَّكُورُ", "Ash-Shakur", "Maha Mensyukuri", "The Appreciative", "善报者", "感謝する", [(35, 30, 30), (64, 17, 17)]),
    ("al_ali", "الْعَلِيُّ", "Al-Ali", "Maha Tinggi", "The Most High", "至高", "至高", [(2, 255, 255), (42, 11, 11)]),
    ("al_kabir", "الْكَبِيرُ", "Al-Kabir", "Maha Besar", "The Most Great", "至大", "偉大なる", [(13, 9, 9), (31, 30, 30)]),
    ("al_hafiz", "الْحَفِيظُ", "Al-Hafiz", "Maha Memelihara", "The Preserver", "保全者", "守る", [(11, 57, 57), (42, 6, 6)]),
    ("al_muqit", "الْمُقِيتُ", "Al-Muqit", "Maha Pemberi Kecukupan", "The Maintainer", "维持者", "養う", [(4, 85, 85)]),
    ("al_hasib", "الْحَسِيبُ", "Al-Hasib", "Maha Pembuat Perhitungan", "The Reckoner", "清算者", "計算する", [(4, 6, 6), (33, 39, 39)]),
    ("al_jalil", "الْجَلِيلُ", "Al-Jalil", "Maha Mulia", "The Majestic", "尊荣", "威厳", [(55, 27, 27)]),
    ("al_karim", "الْكَرِيمُ", "Al-Karim", "Maha Mulia", "The Generous", "至仁", "寛大", [(27, 40, 40), (82, 6, 6)]),
    ("ar_raqib", "الرَّقِيبُ", "Ar-Raqib", "Maha Mengawasi", "The Watchful", "监察者", "見守る", [(4, 1, 1), (5, 117, 117)]),
    ("al_mujib", "الْمُجِيبُ", "Al-Mujib", "Maha Mengabulkan", "The Responsive", "应答者", "応える", [(11, 61, 61), (42, 28, 28)]),
    ("al_wasi", "الْوَاسِعُ", "Al-Wasi", "Maha Luas", "The All-Encompassing", "至广", "広大", [(2, 115, 115), (2, 261, 261)]),
    ("al_hakim", "الْحَكِيمُ", "Al-Hakim", "Maha Bijaksana", "The Wise", "至睿", "英知", [(2, 129, 129), (31, 9, 9)]),
    ("al_wadud", "الْوَدُودُ", "Al-Wadud", "Maha Mencintai", "The Loving", "至爱", "愛する", [(11, 90, 90), (85, 14, 14)]),
    ("al_majid", "الْمَجِيدُ", "Al-Majid", "Maha Mulia", "The Glorious", "荣耀", "栄光", [(11, 73, 73), (85, 15, 15)]),
    ("al_baith", "الْبَاعِثُ", "Al-Ba'ith", "Maha Membangkitkan", "The Resurrector", "复活者", "起こす", [(22, 7, 7)]),
    ("ash_shahid", "الشَّهِيدُ", "Ash-Shahid", "Maha Menyaksikan", "The Witness", "见证者", "証人", [(4, 166, 166), (22, 17, 17)]),
    ("al_haqq", "الْحَقُّ", "Al-Haqq", "Maha Benar", "The Truth", "真理", "真理", [(6, 62, 62), (22, 6, 6)]),
    ("al_wakil", "الْوَكِيلُ", "Al-Wakil", "Maha Memelihara", "The Trustee", "受托者", "委ねる", [(3, 173, 173), (6, 102, 102)]),
    ("al_qawiyy", "الْقَوِيُّ", "Al-Qawiyy", "Maha Kuat", "The Strong", "至强", "強き", [(22, 40, 40), (42, 19, 19)]),
    ("al_matin", "الْمَتِينُ", "Al-Matin", "Maha Kokoh", "The Firm", "坚固", "堅固", [(51, 58, 58)]),
    ("al_wali", "الْوَلِيُّ", "Al-Wali", "Maha Melindungi", "The Protector", "保护者", "守護者", [(3, 68, 68), (42, 28, 28)]),
    ("al_hamid", "الْحَمِيدُ", "Al-Hamid", "Maha Terpuji", "The Praiseworthy", "可赞", "讃美される", [(14, 8, 8), (31, 26, 26)]),
    ("al_muhsi", "الْمُحْصِي", "Al-Muhsi", "Maha Menghitung", "The Accounter", "统计者", "数える", [(19, 94, 94)]),
    ("al_mubdi", "الْمُبْدِئُ", "Al-Mubdi", "Maha Memulai", "The Originator", "肇始者", "始める", [(10, 34, 34), (29, 19, 19)]),
    ("al_muid", "الْمُعِيدُ", "Al-Mu'id", "Maha Mengembalikan", "The Restorer", "复始者", "戻す", [(10, 34, 34), (27, 64, 64)]),
    ("al_muhyi", "الْمُحْيِي", "Al-Muhyi", "Maha Menghidupkan", "The Giver of Life", "赋予生命者", "生かす", [(7, 158, 158), (30, 50, 50)]),
    ("al_mumit", "الْمُمِيتُ", "Al-Mumit", "Maha Mematikan", "The Creator of Death", "使死者", "死なせる", [(7, 158, 158), (57, 2, 2)]),
    ("al_hayy", "الْحَيُّ", "Al-Hayy", "Maha Hidup", "The Ever-Living", "永生", "永遠に生きる", [(2, 255, 255), (40, 65, 65)]),
    ("al_qayyum", "الْقَيُّومُ", "Al-Qayyum", "Maha Mandiri", "The Sustainer", "自持者", "自立する", [(2, 255, 255), (3, 2, 2)]),
    ("al_wajid", "الْوَاجِدُ", "Al-Wajid", "Maha Menemukan", "The Finder", "发现者", "見出す", [(38, 44, 44)]),
    ("al_majid_du", "الْمَاجِدُ", "Al-Majid", "Maha Mulia", "The Noble", "尊贵", "高貴", [(11, 73, 73)]),
    ("al_wahid", "الْوَاحِدُ", "Al-Wahid", "Maha Esa", "The One", "独一", "唯一", [(2, 163, 163), (13, 16, 16)]),
    ("al_ahad", "الْأَحَدُ", "Al-Ahad", "Maha Tunggal", "The Unique", "独一", "唯一無二", [(112, 1, 1)]),
    ("as_samad", "الصَّمَدُ", "As-Samad", "Maha Dibutuhkan", "The Eternal", "永恒", "頼られる", [(112, 2, 2)]),
    ("al_qadir", "الْقَادِرُ", "Al-Qadir", "Maha Berkuasa", "The Able", "全能", "能なる", [(2, 20, 20), (36, 81, 81)]),
    ("al_muqtadir", "الْمُقْتَدِرُ", "Al-Muqtadir", "Maha Berkuasa", "The All-Powerful", "大能", "力ある", [(18, 45, 45), (54, 55, 55)]),
    ("al_muqaddim", "الْمُقَدِّمُ", "Al-Muqaddim", "Maha Mendahulukan", "The Expediter", "提前者", "先にする", [(16, 61, 61)]),
    ("al_muakhkhir", "الْمُؤَخِّرُ", "Al-Mu'akhkhir", "Maha Mengakhirkan", "The Delayer", "延后者", "後にする", [(71, 4, 4)]),
    ("al_awwal", "الْأَوَّلُ", "Al-Awwal", "Maha Awal", "The First", "最先", "最初", [(57, 3, 3)]),
    ("al_akhir", "الْآخِرُ", "Al-Akhir", "Maha Akhir", "The Last", "最后", "最後", [(57, 3, 3)]),
    ("az_zahir", "الظَّاهِرُ", "Az-Zahir", "Maha Nyata", "The Manifest", "显著", "顕れる", [(57, 3, 3)]),
    ("al_batin", "الْبَاطِنُ", "Al-Batin", "Maha Tersembunyi", "The Hidden", "隐微", "隠れる", [(57, 3, 3)]),
    ("al_wali_governor", "الْوَالِي", "Al-Wali", "Maha Penguasa", "The Governor", "主宰者", "統治する", [(13, 11, 11)]),
    ("al_mutali", "الْمُتَعَالِي", "Al-Muta'ali", "Maha Tinggi", "The Most Exalted", "至高", "高く", [(13, 9, 9)]),
    ("al_barr", "الْبَرُّ", "Al-Barr", "Maha Baik", "The Source of Goodness", "至善", "善き", [(52, 28, 28)]),
    ("at_tawwab", "التَّوَّابُ", "At-Tawwab", "Maha Penerima Tobat", "The Acceptor of Repentance", "至恕", "悔い改めを受け入れる", [(2, 37, 37), (9, 104, 104)]),
    ("al_muntaqim", "الْمُنْتَقِمُ", "Al-Muntaqim", "Maha Pemberi Balasan", "The Avenger", "报应者", "報復する", [(32, 22, 22), (43, 41, 41)]),
    ("al_afuww", "الْعَفُوُّ", "Al-Afuww", "Maha Pemaaf", "The Pardoner", "至恕", "赦す", [(4, 43, 43), (4, 99, 99)]),
    ("ar_rauf", "الرَّؤُوفُ", "Ar-Ra'uf", "Maha Pengasih", "The Compassionate", "至慈", "慈悲深き", [(2, 143, 143), (9, 117, 117)]),
    ("malikul_mulk", "مَالِكُ الْمُلْكِ", "Malik-ul-Mulk", "Penguasa Kerajaan", "Master of the Kingdom", "国权之主", "王国の主", [(3, 26, 26)]),
    ("dhu_l_jalali_wal_ikram", "ذُو الْجَلَالِ وَالْإِكْرَامِ", "Dhu-l-Jalali wal-Ikram", "Pemilik Kebesaran dan Kemuliaan", "Lord of Majesty and Honour", "尊荣之主", "威厳と栄光の主", [(55, 27, 27), (55, 78, 78)]),
    ("al_muqsit", "الْمُقْسِطُ", "Al-Muqsit", "Maha Adil", "The Equitable", "公平者", "公平", [(3, 18, 18)]),
    ("al_jami", "الْجَامِعُ", "Al-Jami", "Maha Mengumpulkan", "The Gatherer", "聚集者", "集める", [(3, 9, 9)]),
    ("al_ghani", "الْغَنِيُّ", "Al-Ghani", "Maha Kaya", "The Self-Sufficient", "至富", "自足", [(2, 263, 263), (47, 38, 38)]),
    ("al_mughni", "الْمُغْنِي", "Al-Mughni", "Maha Memperkaya", "The Enricher", "使富足者", "富ませる", [(9, 28, 28)]),
    ("al_mani", "الْمَانِعُ", "Al-Mani", "Maha Mencegah", "The Preventer", "阻止者", "防ぐ", [(67, 21, 21)]),
    ("ad_darr", "الضَّارُّ", "Ad-Darr", "Maha Memberi Mudarat", "The Distresser", "降祸者", "害を与える", [(6, 17, 17)]),
    ("an_nafi", "النَّافِعُ", "An-Nafi", "Maha Memberi Manfaat", "The Benefiter", "赐益者", "益を与える", [(30, 37, 37)]),
    ("an_nur", "النُّورُ", "An-Nur", "Maha Bercahaya", "The Light", "光明", "光", [(24, 35, 35)]),
    ("al_hadi", "الْهَادِي", "Al-Hadi", "Maha Pemberi Petunjuk", "The Guide", "引导者", "導く", [(22, 54, 54)]),
    ("al_badi", "الْبَدِيعُ", "Al-Badi", "Maha Pencipta Baru", "The Originator", "创新者", "初めて創る", [(2, 117, 117), (6, 101, 101)]),
    ("al_baqi", "الْبَاقِي", "Al-Baqi", "Maha Kekal", "The Everlasting", "永恒", "永遠", [(55, 27, 27)]),
    ("al_warith", "الْوَارِثُ", "Al-Warith", "Maha Pewaris", "The Inheritor", "继承者", "継承する", [(15, 23, 23), (28, 58, 58)]),
    ("ar_rashid", "الرَّشِيدُ", "Ar-Rashid", "Maha Pandai", "The Guide to the Right Path", "引导者", "正路へ導く", [(11, 87, 87)]),
    ("as_sabur", "الصَّبُورُ", "As-Sabur", "Maha Sabar", "The Patient", "至忍", "忍耐", [(2, 153, 153), (3, 200, 200)]),
]

FALLBACK = [(17, 110, 110), (59, 24, 24)]


def summary_for(meaning_id: str, lang_key: str) -> str:
    templates = {
        "id": f"Ingat nama {meaning_id} saat hati butuh mengingat sifat Allah yang sesuai.",
        "en": f"Remember this name when your heart needs to recall Allah's attribute of {meaning_id.lower()}.",
        "zh": f"当内心需要想起真主的这一属性时，记念此名。",
        "ja": f"アッラーのこの属性を思い出したいときに、この御名を唱える。",
    }
    return templates[lang_key]


def reflection_for(translit: str, lang_key: str) -> str:
    templates = {
        "id": f"Ucapkan dalam hati: ya {translit}, bantu saya mengenal-Mu lewat ayat-ayat-Nya.",
        "en": f"Say inwardly: O {translit}, help me know You through Your verses.",
        "zh": "在心中念：哦{0}，求你借你的经文让我认识你。",
        "ja": f"心の中で「おお {translit} よ、御自身の節を通して御自身を知らせてください」と唱える。",
    }
    t = templates[lang_key]
    return t.format(translit) if "{0}" in t else t


def main() -> None:
    entries = []
    for i, row in enumerate(NAMES, start=1):
        id_, arabic, translit, id_m, en_m, zh_m, ja_m, refs = row
        refs_json = [{"surah": s, "from": f, "to": t} for s, f, t in (refs or FALLBACK)]
        entries.append({
            "id": id_,
            "number": i,
            "sort": i,
            "arabic": arabic,
            "transliteration": translit,
            "title": {"id": id_m, "en": en_m, "zh": zh_m, "ja": ja_m},
            "summary": {
                "id": summary_for(id_m, "id"),
                "en": summary_for(en_m, "en"),
                "zh": summary_for(id_m, "zh"),
                "ja": summary_for(id_m, "ja"),
            },
            "reflection": {
                "id": reflection_for(translit, "id"),
                "en": reflection_for(translit, "en"),
                "zh": reflection_for(translit, "zh"),
                "ja": reflection_for(translit, "ja"),
            },
            "ayahRefs": refs_json,
        })

    assert len(entries) == 99
    ids = [e["id"] for e in entries]
    assert len(ids) == len(set(ids))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8") as f:
        json.dump({"version": 1, "entries": entries}, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(entries)} entries to {OUT}")


if __name__ == "__main__":
    main()
