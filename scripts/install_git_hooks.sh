#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$ROOT/.git/hooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "ERROR: .git/hooks not found. Run from a git clone." >&2
  exit 1
fi

for hook in post-checkout post-merge; do
  src="$ROOT/scripts/hooks/$hook"
  dst="$HOOKS_DIR/$hook"
  cp "$src" "$dst"
  chmod +x "$dst"
  echo "Installed $hook"
done

echo ""
echo "Git will now re-sync assets/ from data/bundled/ after pull/checkout."
echo "One-time setup if not done yet:"
echo "  bash scripts/seed_bundled_data.sh"
echo "  bash scripts/install_git_hooks.sh"
