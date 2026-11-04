#!/usr/bin/env bash
# Runs SwiftLint, then builds and runs the tests on an iPhone simulator.
# Exits non-zero on the first failure. Do not silence failures.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> SwiftLint"
swiftlint lint --strict

# The structural rules a lint regex cannot express (ADR 006, task X-13), then proof that the check itself works.
./scripts/check_architecture.sh
./scripts/check_architecture_selftest.sh

# Use $SIMULATOR if set, otherwise the first available iPhone simulator.
SIMULATOR="${SIMULATOR:-$(xcrun simctl list devices available | grep -m1 -o 'iPhone[^(]*' | sed 's/ *$//')}"
echo "==> Tests on: $SIMULATOR"
xcodebuild test \
  -project Vybe.xcodeproj \
  -scheme Vybe \
  -destination "platform=iOS Simulator,name=$SIMULATOR" \
  -quiet

# The local Swift package (VybeKit): builds every target and runs every test target.
if [ -f VybeKit/Package.swift ]; then
  echo "==> VybeKit package tests on: $SIMULATOR"
  (cd VybeKit && xcodebuild test \
    -scheme VybeKit-Package \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -quiet)
fi

echo "==> All checks passed"
