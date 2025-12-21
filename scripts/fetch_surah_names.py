#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fetch surah names from Quran.com v4 API and generate Dart code for _getEnglishNames()
"""

import json
import requests

API_BASE_URL = "https://api.quran.com/api/v4"

def main():
    r = requests.get(f"{API_BASE_URL}/chapters", params={"language": "en"}, timeout=20)
    r.raise_for_status()
    data = r.json()
    chapters = data.get("chapters", [])
    
    if len(chapters) != 114:
        raise RuntimeError(f"Expected 114 chapters, got {len(chapters)}")
    
    # Generate Dart code
    print("Map<int, String> _getEnglishNames() {")
    print("  return {")
    
    for ch in chapters:
        cid = ch.get("id")
        name = ch.get("name_simple", "")
        # Escape single quotes in Dart strings
        name_escaped = name.replace("'", "\\'")
        print(f"    {cid}: '{name_escaped}',")
    
    print("  };")
    print("}")

if __name__ == "__main__":
    main()

