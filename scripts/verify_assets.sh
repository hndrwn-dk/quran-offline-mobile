#!/usr/bin/env bash
# Fail fast when required bundle assets are missing on disk (before flutter build).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
missing=()

require_file() {
  local rel="$1"
  if [[ ! -f "$ROOT/$rel" ]]; then
    missing+=("$rel")
  fi
}

require_file "assets/quran/manifest_multi.json"
require_file "assets/quran/surah_meanings.json"
require_file "assets/quran/surah_names/manifest.json"
require_file "assets/quran/index_juz.json"
require_file "assets/quran/index_pages.json"
require_file "assets/quran/surah_info/en_surah_info.sqlite"
require_file "assets/quran/surah_info/id_surah_info.sqlite"
require_file "assets/tafsir/en_ibn_kathir.sqlite"
require_file "assets/tafsir/id_as_saadi.sqlite"
require_file "assets/tafsir/zh_mokhtasar.sqlite"
require_file "assets/tafsir/ja_mokhtasar.sqlite"
require_file "assets/duas/duas_catalog.json"
require_file "assets/science/science_catalog.json"
require_file "assets/themes/life_themes_catalog.json"
require_file "assets/reflection/calendar_lenses_catalog.json"
require_file "assets/reflection/weekly_rotation_catalog.json"
require_file "assets/asma/asmaul_husna_catalog.json"

for i in $(seq 1 114); do
  require_file "$(printf 'assets/quran/s%03d.json' "$i")"
done

if ((${#missing[@]} > 0)); then
  echo "ERROR: Required assets missing on disk (${#missing[@]} files)." >&2
  echo "Flutter build bundles only what exists locally — not what is on GitHub." >&2
  echo "Fix:" >&2
  echo "  bash scripts/sync_bundled_data.sh   # restore from data/bundled/" >&2
  echo "  bash scripts/seed_bundled_data.sh   # first-time backup into data/bundled/" >&2
  echo "  See scripts/DATA_WORKFLOW.md and DATA_SOURCES.md" >&2
  echo >&2
  if ((${#missing[@]} <= 20)); then
    printf '  - %s\n' "${missing[@]}" >&2
  else
    printf '  - %s\n' "${missing[@]:0:15}" >&2
    echo "  ... and $((${#missing[@]} - 15)) more" >&2
  fi
  exit 1
fi

echo "OK: all required assets present under $ROOT/assets/"
