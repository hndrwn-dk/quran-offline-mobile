#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fetch tajweed text for all verses from Quran.com v4 API and update JSON files.

This script:
1. Reads existing JSON files (s001.json to s114.json)
2. Fetches tajweed text from API for each verse
3. Adds 'tj' field to each verse object
4. Saves updated JSON files

Run: python scripts/fetch_tajweed_data.py
"""

import json
import sys
import os
from pathlib import Path
import requests
import time

API_BASE_URL = "https://api.quran.com/api/v4"
REPO_ROOT = Path(__file__).resolve().parents[1]
ASSETS_DIR = REPO_ROOT / "assets" / "quran"

def fetch_tajweed_for_verse(surah_id: int, ayah_no: int) -> str | None:
    """Fetch tajweed text for a specific verse."""
    try:
        url = f"{API_BASE_URL}/quran/verses/uthmani_tajweed"
        params = {"verse_key": f"{surah_id}:{ayah_no}"}
        
        response = requests.get(url, params=params, timeout=20)
        response.raise_for_status()
        
        data = response.json()
        verses = data.get("verses", [])
        
        if verses and len(verses) > 0:
            return verses[0].get("text_uthmani_tajweed")
        
        return None
    except Exception as e:
        print(f"Error fetching tajweed for {surah_id}:{ayah_no}: {e}", file=sys.stderr)
        return None

def update_surah_file(surah_id: int, dry_run: bool = False) -> int:
    """Update a single surah JSON file with tajweed data."""
    surah_file = ASSETS_DIR / f"s{surah_id:03d}.json"
    
    if not surah_file.exists():
        print(f"Warning: {surah_file} not found, skipping...")
        return 0
    
    print(f"Processing Surah {surah_id}...")
    
    # Read existing JSON
    with open(surah_file, 'r', encoding='utf-8') as f:
        verses = json.load(f)
    
    updated_count = 0
    for verse in verses:
        # Skip if tajweed already exists
        if 'tj' in verse and verse['tj']:
            continue
        
        surah_id_verse = verse.get('s', surah_id)
        ayah_no = verse.get('a')
        
        if not ayah_no:
            continue
        
        print(f"  Fetching tajweed for verse {ayah_no}...", end=' ')
        tajweed = fetch_tajweed_for_verse(surah_id_verse, ayah_no)
        
        if tajweed:
            verse['tj'] = tajweed
            updated_count += 1
            print("OK")
        else:
            print("FAILED")
        
        # Rate limiting
        time.sleep(0.1)
    
    # Save updated JSON
    if updated_count > 0 and not dry_run:
        with open(surah_file, 'w', encoding='utf-8') as f:
            json.dump(verses, f, ensure_ascii=False, indent=2)
        print(f"  Updated {updated_count} verses in {surah_file.name}")
    
    return updated_count

def main():
    print("=" * 60)
    print("Quran.com v4 - Tajweed Data Fetcher")
    print("=" * 60)
    
    if not ASSETS_DIR.exists():
        print(f"Error: Assets directory not found: {ASSETS_DIR}")
        return 1
    
    total_updated = 0
    
    # Process all surahs
    for surah_id in range(1, 115):
        try:
            updated = update_surah_file(surah_id, dry_run=False)
            total_updated += updated
        except KeyboardInterrupt:
            print("\n\nInterrupted by user. Partial update saved.")
            return 1
        except Exception as e:
            print(f"Error processing Surah {surah_id}: {e}", file=sys.stderr)
            continue
    
    print("\n" + "=" * 60)
    print(f"DONE: Updated {total_updated} verses with tajweed data")
    print("=" * 60)
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        raise

