#!/usr/bin/env bash
# Safe release build: sync git-safe backup -> verify -> flutter build
# Usage:
#   bash scripts/build_release.sh apk --release
#   bash scripts/build_release.sh appbundle --release
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if (($# < 1)); then
  echo "Usage: bash scripts/build_release.sh <flutter-build-target> [flutter build args...]" >&2
  echo "Example: bash scripts/build_release.sh appbundle --release" >&2
  exit 1
fi

TARGET="$1"
shift

bash scripts/sync_bundled_data.sh
bash scripts/verify_assets.sh

echo ""
echo "Building flutter $TARGET $*"
flutter build "$TARGET" "$@"
