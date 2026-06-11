#!/usr/bin/env bash
# Copy git-safe data/bundled/ into assets/ before run or release build.
set -euo pipefail

source "$(dirname "$0")/lib/paths.sh"

QUIET=0
for arg in "$@"; do
  case "$arg" in
    --quiet|-q) QUIET=1 ;;
  esac
done

log() {
  if ((QUIET == 0)); then
    echo "$@"
  fi
}

if [[ ! -d "$QURAN_OFFLINE_BUNDLED" ]]; then
  log "No bundled data at $QURAN_OFFLINE_BUNDLED (skip sync)."
  exit 0
fi

if [[ ! -f "$QURAN_OFFLINE_BUNDLED/quran/manifest_multi.json" ]]; then
  log "Bundled data folder exists but looks empty (no quran/manifest_multi.json). Skip sync."
  exit 0
fi

copy_tree() {
  local name="$1"
  local src="$QURAN_OFFLINE_BUNDLED/$name"
  local dst="$QURAN_OFFLINE_ROOT/assets/$name"
  if [[ ! -d "$src" ]]; then
    return 0
  fi
  mkdir -p "$dst"
  # cp contents so .gitkeep in assets/ subdirs is preserved when absent in src
  shopt -s dotglob nullglob
  local entries=("$src"/*)
  shopt -u dotglob nullglob
  if ((${#entries[@]} == 0)); then
    return 0
  fi
  cp -R "${entries[@]}" "$dst/"
  log "  synced $name/"
}

log "Syncing bundled data -> assets/"
log "  from: $QURAN_OFFLINE_BUNDLED"

for dir in quran tafsir duas asma science themes reflection; do
  copy_tree "$dir"
done

log "Sync complete."
