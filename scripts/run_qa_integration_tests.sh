#!/usr/bin/env bash
# Run emulator/device QA regression tests (integration_test/qa_regression_test.dart).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

DEVICE_ID="${1:-}"

echo "==> flutter pub get"
flutter pub get

if [[ -n "$DEVICE_ID" ]]; then
  echo "==> Running QA integration tests on device: $DEVICE_ID"
  flutter test integration_test/qa_regression_test.dart -d "$DEVICE_ID"
else
  echo "==> Running QA integration tests on default device"
  flutter devices
  flutter test integration_test/qa_regression_test.dart
fi
