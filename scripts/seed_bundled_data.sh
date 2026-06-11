#!/usr/bin/env bash
# One-time (or occasional) backup: copy populated assets/ -> data/bundled/
# Run after you obtain or restore data so Git operations cannot erase your only copy.
set -euo pipefail

source "$(dirname "$0")/lib/paths.sh"

if [[ ! -f "$QURAN_OFFLINE_ROOT/assets/quran/manifest_multi.json" ]]; then
  echo "ERROR: assets/quran/manifest_multi.json not found." >&2
  echo "Populate assets/ per DATA_SOURCES.md first, then run this script." >&2
  exit 1
fi

mkdir -p "$QURAN_OFFLINE_BUNDLED"

copy_tree() {
  local name="$1"
  local src="$QURAN_OFFLINE_ROOT/assets/$name"
  local dst="$QURAN_OFFLINE_BUNDLED/$name"
  if [[ ! -d "$src" ]]; then
    return 0
  fi
  mkdir -p "$dst"
  shopt -s dotglob nullglob
  local entries=("$src"/*)
  shopt -u dotglob nullglob
  for entry in "${entries[@]}"; do
    local base
    base="$(basename "$entry")"
    [[ "$base" == ".gitkeep" ]] && continue
    cp -R "$entry" "$dst/"
  done
  echo "  saved $name/"
}

echo "Backing up assets/ -> data/bundled/"
echo "  target: $QURAN_OFFLINE_BUNDLED"

for dir in quran tafsir duas asma science themes reflection; do
  copy_tree "$dir"
done

echo ""
echo "Done. data/bundled/ is gitignored — safe from pull/reset/commit."
echo "After every git pull or checkout, assets/ is restored via:"
echo "  bash scripts/sync_bundled_data.sh"
