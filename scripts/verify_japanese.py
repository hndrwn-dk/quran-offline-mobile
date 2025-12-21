#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Verify Japanese translations in surah_meanings.json against Excel file
"""

import json
import sys
import io
from pathlib import Path

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

try:
    import openpyxl
except ImportError:
    print("Installing openpyxl...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "openpyxl"])
    import openpyxl

def main():
    repo_root = Path(__file__).resolve().parents[1]
    excel_path = repo_root / "assets" / "quran" / "Surah_name_Japanses.xlsx"
    json_path = repo_root / "assets" / "quran" / "surah_meanings.json"
    
    # Read Excel
    print("Reading Excel file...")
    wb = openpyxl.load_workbook(excel_path)
    ws = wb.active
    
    excel_data = {}
    for row in range(2, 116):  # Row 2 to 115 (114 surahs)
        surah_id = row - 1  # Row 2 = Surah 1
        japanese_name = ws.cell(row=row, column=2).value
        if japanese_name:
            excel_data[surah_id] = str(japanese_name).strip()
    
    print(f"Found {len(excel_data)} Japanese entries in Excel")
    
    # Read JSON
    print("Reading JSON file...")
    with json_path.open("r", encoding="utf-8") as f:
        json_data = json.load(f)
    
    # Verify
    print("\n" + "=" * 60)
    print("VERIFICATION RESULTS")
    print("=" * 60)
    
    mismatches = []
    missing = []
    correct = []
    
    for surah_id in range(1, 115):
        sid = str(surah_id)
        json_ja = json_data.get(sid, {}).get("ja", "").strip()
        excel_ja = excel_data.get(surah_id, "").strip()
        
        if not excel_ja:
            missing.append(surah_id)
        elif json_ja != excel_ja:
            mismatches.append((surah_id, excel_ja, json_ja))
        else:
            correct.append(surah_id)
    
    print(f"\n✅ Correct: {len(correct)}/114")
    print(f"❌ Mismatches: {len(mismatches)}")
    print(f"⚠️  Missing in Excel: {len(missing)}")
    
    if mismatches:
        print("\n🔍 Mismatches (first 10):")
        for surah_id, excel_val, json_val in mismatches[:10]:
            print(f"  Surah {surah_id}:")
            print(f"    Excel: '{excel_val}'")
            print(f"    JSON:  '{json_val}'")
    
    if missing:
        print(f"\n⚠️  Missing in Excel (first 10): {missing[:10]}")
    
    # Show sample from Excel
    print("\n📋 Sample from Excel (first 10):")
    for surah_id in range(1, 11):
        if surah_id in excel_data:
            print(f"  Surah {surah_id}: {excel_data[surah_id]}")
    
    # Show sample from JSON
    print("\n📋 Sample from JSON (first 10):")
    for surah_id in range(1, 11):
        sid = str(surah_id)
        json_ja = json_data.get(sid, {}).get("ja", "").strip()
        print(f"  Surah {surah_id}: {json_ja}")
    
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        raise

