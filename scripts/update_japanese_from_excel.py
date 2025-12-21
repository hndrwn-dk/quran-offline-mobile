#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Update Japanese translations in surah_meanings.json from Excel file
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
    
    # Update JSON with Excel data
    print("Updating JSON file...")
    updated_count = 0
    for surah_id in range(1, 115):
        sid = str(surah_id)
        if sid in json_data and surah_id in excel_data:
            old_value = json_data[sid].get("ja", "").strip()
            new_value = excel_data[surah_id]
            if old_value != new_value:
                json_data[sid]["ja"] = new_value
                updated_count += 1
                if updated_count <= 5:  # Show first 5 updates
                    print(f"  Surah {surah_id}: '{old_value}' -> '{new_value}'")
    
    # Write updated JSON
    print(f"\nUpdated {updated_count} entries")
    print("Writing JSON file...")
    with json_path.open("w", encoding="utf-8") as f:
        json.dump(json_data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ DONE: Updated {json_path}")
    
    # Verify
    print("\nVerification (first 10):")
    for surah_id in range(1, 11):
        sid = str(surah_id)
        json_ja = json_data.get(sid, {}).get("ja", "").strip()
        excel_ja = excel_data.get(surah_id, "").strip()
        status = "✅" if json_ja == excel_ja else "❌"
        print(f"  {status} Surah {surah_id}: {json_ja}")
    
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        raise

