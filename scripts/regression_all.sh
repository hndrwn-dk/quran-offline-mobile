#!/usr/bin/env bash
# Build debug APK, install on devices, run UI regression on each.
# Usage: ./scripts/regression_all.sh [device-serial ...]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK="${ROOT}/build/app/outputs/flutter-apk/app-debug.apk"
PKG="com.tursinalabs.quranoffline"

log() { echo "[regression] $*"; }
fail() { echo "[regression] FAIL: $*" >&2; exit 1; }

if [[ $# -gt 0 ]]; then
  DEVICES=("$@")
else
  mapfile -t DEVICES < <(adb devices | awk 'NR>1 && $2=="device" {print $1}')
fi

[[ ${#DEVICES[@]} -gt 0 ]] || fail "No adb devices attached"

log "flutter test"
(cd "$ROOT" && flutter test)

log "flutter build apk --debug"
(cd "$ROOT" && flutter build apk --debug)

[[ -f "$APK" ]] || fail "APK not found at $APK"

PASS=0
FAIL=0
FAILED=()

for serial in "${DEVICES[@]}"; do
  log "Install on $serial"
  if ! adb -s "$serial" install -r "$APK" >/dev/null 2>&1; then
    if adb -s "$serial" shell pm path "$PKG" >/dev/null 2>&1; then
      log "Install skipped on $serial (using existing APK)"
    else
      log "SKIP $serial — install failed and app not present"
      FAIL=$((FAIL + 1))
      FAILED+=("$serial (no install)")
      continue
    fi
  fi
  if bash "${ROOT}/scripts/regression_read_scroll.sh" "$serial"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED+=("$serial")
  fi
done

log "Done: ${PASS} passed, ${FAIL} failed"
if [[ $FAIL -gt 0 ]]; then
  log "Failed devices: ${FAILED[*]}"
  exit 1
fi
