#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Compare surah_meanings.json with surah_meanings_with_ja.json
"""

import json
import sys
import io
from pathlib import Path

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    repo_root = Path(__file__).resolve().parents[1]
    json1_path = repo_root / "assets" / "quran" / "surah_meanings.json"
    json2_path = repo_root / "assets" / "quran" / "surah_meanings_with_ja.json"
    
    # Read both JSON files
    print("Reading surah_meanings.json...")
    with json1_path.open("r", encoding="utf-8") as f:
        data1 = json.load(f)
    
    print("Reading surah_meanings_with_ja.json...")
    with json2_path.open("r", encoding="utf-8") as f:
        data2 = json.load(f)
    
    print("\n" + "=" * 60)
    print("COMPARISON RESULTS")
    print("=" * 60)
    
    # Compare
    differences = []
    missing_in_1 = []
    missing_in_2 = []
    identical = []
    
    all_surah_ids = set(data1.keys()) | set(data2.keys())
    
    for surah_id in sorted(all_surah_ids, key=int):
        entry1 = data1.get(surah_id, {})
        entry2 = data2.get(surah_id, {})
        
        if surah_id not in data1:
            missing_in_1.append(surah_id)
            continue
        if surah_id not in data2:
            missing_in_2.append(surah_id)
            continue
        
        # Compare each language
        for lang in ["en", "id", "zh", "ja"]:
            val1 = entry1.get(lang, "").strip()
            val2 = entry2.get(lang, "").strip()
            
            if val1 != val2:
                differences.append((surah_id, lang, val1, val2))
            elif lang == "ja" and val1:  # Track Japanese entries that match
                identical.append((surah_id, val1))
    
    # Print results
    print(f"\nTotal surahs: {len(all_surah_ids)}")
    print(f"✅ Identical Japanese entries: {len(identical)}")
    print(f"❌ Differences found: {len(differences)}")
    print(f"⚠️  Missing in surah_meanings.json: {len(missing_in_1)}")
    print(f"⚠️  Missing in surah_meanings_with_ja.json: {len(missing_in_2)}")
    
    if differences:
        print("\n🔍 Differences (first 20):")
        for surah_id, lang, val1, val2 in differences[:20]:
            print(f"  Surah {surah_id} ({lang}):")
            print(f"    surah_meanings.json:        '{val1}'")
            print(f"    surah_meanings_with_ja.json: '{val2}'")
    
    if identical:
        print("\n✅ Sample identical Japanese entries (first 10):")
        for surah_id, val in identical[:10]:
            print(f"  Surah {surah_id}: {val}")
    
    # Check if Japanese is filled in both
    print("\n📊 Japanese entries status:")
    ja_filled_1 = sum(1 for k, v in data1.items() if v.get("ja", "").strip())
    ja_filled_2 = sum(1 for k, v in data2.items() if v.get("ja", "").strip())
    print(f"  surah_meanings.json:        {ja_filled_1}/114")
    print(f"  surah_meanings_with_ja.json: {ja_filled_2}/114")
    
    # Show sample from both files
    print("\n📋 Sample comparison (first 5 surahs):")
    for surah_id in range(1, 6):
        sid = str(surah_id)
        ja1 = data1.get(sid, {}).get("ja", "").strip()
        ja2 = data2.get(sid, {}).get("ja", "").strip()
        match = "✅" if ja1 == ja2 else "❌"
        print(f"  {match} Surah {surah_id}:")
        print(f"    surah_meanings.json:        '{ja1}'")
        print(f"    surah_meanings_with_ja.json: '{ja2}'")
    
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        raise

