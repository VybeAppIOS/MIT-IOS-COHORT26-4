#!/usr/bin/env bash
# Task X-14 (ADR 006): open one screen in one state in the simulator and save a screenshot of it.
#
#   scripts/snap.sh <name> <route> <mode>
#
#   <name>   the file name: build/screenshots/<name>.png  (with mode "all": <name>-<mode>.png for each mode)
#   <route>  what to open: a short form such as  hangout/hangout-example-evening-c3d4  settings/privacy  saved
#            sheet/spot/<id>  cover/live/<id>   or a JSON Route. Use "none" for the first screen, or tab:profile
#            to start on a tab (discover, community, profile, search). The list of short
#            forms is in Vybe/App/LaunchOptions.swift.
#   <mode>   loaded | empty | failing | loading | all   (the sample-data stubs; "all" takes four screenshots)
#
# Environment: SIMULATOR (default: the first available iPhone), WAIT (seconds to wait before the picture, default 3),
# SKIP_BUILD=1 (reuse the last build). Uses only the debug launch options, so no personal data and nothing in Release.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ "$#" -ne 3 ]; then
  echo "usage: scripts/snap.sh <name> <route> <mode>   (mode: loaded | empty | failing | loading | all)" >&2
  exit 64
fi

NAME="$1"
ROUTE="$2"
MODE="$3"
WAIT="${WAIT:-3}"
BUNDLE_ID="com.lohitaksh.Vybe"
DERIVED="build/DerivedData"
OUT="build/screenshots"

case "$MODE" in
  loaded | empty | failing | loading) MODES=("$MODE") ;;
  all) MODES=(loaded empty failing loading) ;;
  *) echo "unknown mode '$MODE' (use loaded, empty, failing, loading or all)" >&2; exit 64 ;;
esac

SIMULATOR="${SIMULATOR:-$(xcrun simctl list devices available | grep -m1 -o 'iPhone[^(]*' | sed 's/ *$//')}"
UDID="$(xcrun simctl list devices available | grep -F "$SIMULATOR (" | head -1 | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}')"
if [ -z "$UDID" ]; then
  echo "no simulator named '$SIMULATOR'" >&2
  exit 1
fi

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  echo "==> Building for $SIMULATOR"
  xcodebuild build -project Vybe.xcodeproj -scheme Vybe -destination "platform=iOS Simulator,id=$UDID" \
    -derivedDataPath "$DERIVED" -quiet
fi
APP="$(find "$DERIVED/Build/Products" -name 'Vybe.app' -path '*iphonesimulator*' | head -1)"
[ -n "$APP" ] || { echo "Vybe.app not found in $DERIVED" >&2; exit 1; }

echo "==> Booting $SIMULATOR"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
# The same clock and battery in every picture, so two screenshots only differ when the screen does.
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP"

mkdir -p "$OUT"
for mode in "${MODES[@]}"; do
  target="$OUT/$NAME.png"
  [ "$MODE" = "all" ] && target="$OUT/$NAME-$mode.png"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  args=(-skipOnboarding -resetState -stubMode "$mode")
  case "$ROUTE" in
    none) ;;
    tab:*) args+=(-tab "${ROUTE#tab:}") ;;
    *) args+=(-debugRoute "$ROUTE") ;;
  esac
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "${args[@]}" >/dev/null
  sleep "$WAIT"
  xcrun simctl io "$UDID" screenshot "$target" >/dev/null 2>&1
  echo "==> Saved $target ($mode)"
done
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
