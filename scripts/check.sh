#!/usr/bin/env bash
# Runs SwiftLint, then builds and runs the tests on an iPhone simulator.
# Exits non-zero on the first failure. Do not silence failures.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> SwiftLint"
swiftlint lint --strict

# Use $SIMULATOR if set, otherwise the first available iPhone simulator.
SIMULATOR="${SIMULATOR:-$(xcrun simctl list devices available | grep -m1 -o 'iPhone[^(]*' | sed 's/ *$//')}"
echo "==> Tests on: $SIMULATOR"
xcodebuild test \
  -project Vybe.xcodeproj \
  -scheme Vybe \
  -destination "platform=iOS Simulator,name=$SIMULATOR" \
  -quiet

echo "==> All checks passed"
