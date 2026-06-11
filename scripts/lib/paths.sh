# Shared paths for asset workflow scripts. Source from other scripts:
#   source "$(dirname "$0")/lib/paths.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export QURAN_OFFLINE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Canonical data store — entire data/ tree is .gitignored; Git never deletes it.
export QURAN_OFFLINE_BUNDLED="${QURAN_OFFLINE_DATA_DIR:-$QURAN_OFFLINE_ROOT/data/bundled}"
