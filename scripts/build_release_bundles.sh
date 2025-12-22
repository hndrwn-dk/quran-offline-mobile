#!/bin/bash

# Script to build release bundles for v1.0.0+3 and v1.0.0+4

set -e

# Get script directory and change to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Project root: $PROJECT_ROOT"
echo "Building release bundles for v1.0.0+3 and v1.0.0+4..."

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# Stash any uncommitted changes
echo "Stashing uncommitted changes..."
git stash push -m "WIP: Notes and highlights feature"

# Build v1.0.0+4 bundle (from latest release commit)
echo ""
echo "=== Building bundle for v1.0.0+4 ==="
LATEST_RELEASE=$(git log --oneline --grep="v1.0.0+4\|quick search\|bookmark.*Mushaf\|tajweed" --all -1 | cut -d' ' -f1)
if [ -z "$LATEST_RELEASE" ]; then
    LATEST_RELEASE="6e43a06"  # Latest commit with quick search
fi
echo "Checking out commit: $LATEST_RELEASE"
git checkout $LATEST_RELEASE

# Verify version
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
echo "Version: $VERSION"
if [ "$VERSION" != "1.0.0+4" ]; then
    echo "Warning: Version mismatch! Expected 1.0.0+4, got $VERSION"
fi

# Build bundle
echo "Building app bundle..."
# Ensure we're in project root before clean
cd "$PROJECT_ROOT"
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build appbundle --release

# Copy bundle with version name
cd "$PROJECT_ROOT"
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    cp build/app/outputs/bundle/release/app-release.aab "build/app/outputs/bundle/release/app-release-v1.0.0+4.aab"
    echo "✓ Bundle created: build/app/outputs/bundle/release/app-release-v1.0.0+4.aab"
else
    echo "✗ Failed to build bundle for v1.0.0+4"
fi

# Build v1.0.0+3 bundle
echo ""
echo "=== Building bundle for v1.0.0+3 ==="
V3_COMMIT="2ffd1ee"
echo "Checking out commit: $V3_COMMIT"
git checkout $V3_COMMIT

# Verify version
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
echo "Version: $VERSION"
if [ "$VERSION" != "1.0.0+3" ]; then
    echo "Warning: Version mismatch! Expected 1.0.0+3, got $VERSION"
fi

# Build bundle
echo "Building app bundle..."
# Ensure we're in project root before clean
cd "$PROJECT_ROOT"
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build appbundle --release

# Copy bundle with version name
cd "$PROJECT_ROOT"
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    cp build/app/outputs/bundle/release/app-release.aab "build/app/outputs/bundle/release/app-release-v1.0.0+3.aab"
    echo "✓ Bundle created: build/app/outputs/bundle/release/app-release-v1.0.0+3.aab"
else
    echo "✗ Failed to build bundle for v1.0.0+3"
fi

# Return to original branch
echo ""
echo "Returning to original branch: $CURRENT_BRANCH"
cd "$PROJECT_ROOT"
git checkout $CURRENT_BRANCH

# Restore stashed changes
echo "Restoring stashed changes..."
git stash pop || true

echo ""
echo "=== Build Complete ==="
echo "Bundles created:"
echo "  - build/app/outputs/bundle/release/app-release-v1.0.0+3.aab"
echo "  - build/app/outputs/bundle/release/app-release-v1.0.0+4.aab"

