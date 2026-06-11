#!/usr/bin/env bash
# Quran Offline — data-safe dev & release commands
# Usage: bash scripts/qo.sh <command> [args...]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

cmd="${1:-help}"
shift || true

run_sync() {
  bash "$ROOT/scripts/sync_bundled_data.sh" "$@"
}

run_verify() {
  bash "$ROOT/scripts/verify_assets.sh" "$@"
}

case "$cmd" in
  setup)
    echo "=== Quran Offline: setup data automation ==="
    if [[ -f "$ROOT/assets/quran/manifest_multi.json" ]]; then
      bash "$ROOT/scripts/seed_bundled_data.sh"
    elif [[ -f "${QURAN_OFFLINE_DATA_DIR:-$ROOT/data/bundled}/quran/manifest_multi.json" ]]; then
      echo "assets/ empty; using existing data/bundled/"
      run_sync
    else
      echo "ERROR: No data found in assets/ or data/bundled/." >&2
      echo "Populate assets/ per DATA_SOURCES.md, then run: bash scripts/qo.sh setup" >&2
      exit 1
    fi
    bash "$ROOT/scripts/install_git_hooks.sh"
    run_sync
    run_verify
    echo ""
    echo "Setup complete. Commands:"
    echo "  bash scripts/qo.sh run          # debug on device"
    echo "  bash scripts/qo.sh aab          # Play Store bundle"
    echo "  bash scripts/qo.sh apk          # release APK"
    ;;

  seed)
    bash "$ROOT/scripts/seed_bundled_data.sh" "$@"
    ;;

  sync)
    run_sync "$@"
    ;;

  verify|check)
    run_verify "$@"
    ;;

  hooks)
    bash "$ROOT/scripts/install_git_hooks.sh" "$@"
    ;;

  run)
    run_sync --quiet
    run_verify
    flutter run "$@"
    ;;

  apk)
    bash "$ROOT/scripts/build_apk.sh" "$@"
    ;;

  aab|appbundle)
    bash "$ROOT/scripts/build_aab.sh" "$@"
    ;;

  build)
    bash "$ROOT/scripts/build_release.sh" "$@"
    ;;

  test)
    run_sync --quiet
    flutter test "$@"
    ;;

  qa)
    run_sync --quiet
    run_verify
    bash "$ROOT/scripts/run_qa_integration_tests.sh" "$@"
    ;;

  help|--help|-h)
    cat <<'EOF'
Quran Offline — data-safe commands

  bash scripts/qo.sh setup     One-time: backup data, install git hooks, verify
  bash scripts/qo.sh sync      Restore assets/ from data/bundled/
  bash scripts/qo.sh seed      Backup assets/ -> data/bundled/
  bash scripts/qo.sh verify    Fail if required assets missing
  bash scripts/qo.sh hooks     Install post-pull auto-sync git hooks

  bash scripts/qo.sh run       sync + verify + flutter run
  bash scripts/qo.sh test      sync + flutter test
  bash scripts/qo.sh qa        sync + verify + integration tests

  bash scripts/qo.sh apk       sync + verify + release APK
  bash scripts/qo.sh aab       sync + verify + Play Store AAB

Optional env:
  QURAN_OFFLINE_DATA_DIR=/path   Custom backup folder (default: data/bundled/)

Docs: scripts/DATA_WORKFLOW.md
EOF
    ;;

  *)
    echo "Unknown command: $cmd" >&2
    echo "Run: bash scripts/qo.sh help" >&2
    exit 1
    ;;
esac
