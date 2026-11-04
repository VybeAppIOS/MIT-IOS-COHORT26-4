#!/usr/bin/env bash
# Proves that scripts/check_architecture.sh works (task X-13): the real tree passes, and a deliberate violation of each
# rule makes it fail with the right message. Works on a temporary copy; the real files are never changed.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
REAL="$(pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
problems=0

fresh_copy() {   # a copy of what the script reads
  rm -rf "$TMP/tree"
  mkdir -p "$TMP/tree/VybeKit" "$TMP/tree/Vybe"
  cp -R VybeKit/Sources VybeKit/Tests VybeKit/Package.swift "$TMP/tree/VybeKit/"
  [ -d Vybe ] && cp -R Vybe/. "$TMP/tree/Vybe/"
}

run() { ARCH_ROOT="$TMP/tree" "$REAL/scripts/check_architecture.sh" 2>&1; }

expect_pass() {
  if run >/dev/null; then echo "ok    $1"; else echo "FAIL  $1 (expected the check to pass)"; problems=$((problems + 1)); fi
}

expect_fail() {   # name, text the report must contain
  local output
  if output="$(run)"; then
    echo "FAIL  $1 (the check passed, but it should have failed)"
    problems=$((problems + 1))
  elif printf '%s' "$output" | grep -qF -- "$2"; then
    echo "ok    $1"
  else
    echo "FAIL  $1 (failed, but the report does not say: $2)"
    problems=$((problems + 1))
  fi
}

echo "==> Architecture check self-test"

fresh_copy
expect_pass "the real tree passes"

# Rule 1: a feature without its Screens file.
fresh_copy
rm "$TMP/tree/VybeKit/Sources/SearchFeature/SearchScreens.swift"
expect_fail "rule 1: missing Screens file fails" "missing SearchScreens.swift"

# Rule 2: a ViewModel without a test, then with one.
fresh_copy
mkdir -p "$TMP/tree/VybeKit/Sources/DiscoverFeature/Map"
echo "final class MapViewModel {}" > "$TMP/tree/VybeKit/Sources/DiscoverFeature/Map/MapViewModel.swift"
expect_fail "rule 2: ViewModel without a test fails" "no MapViewModelTests.swift"
echo "// test" > "$TMP/tree/VybeKit/Tests/DiscoverFeatureTests/MapViewModelTests.swift"
expect_pass "rule 2: the same ViewModel with its test passes"

# Rule 3: RunTimes in a module that must not see it; a comment about it is fine.
fresh_copy
mkdir -p "$TMP/tree/VybeKit/Sources/CommunityFeature/Feed"
echo "let leak: RunTimes? = nil" > "$TMP/tree/VybeKit/Sources/CommunityFeature/Feed/Leak.swift"
expect_fail "rule 3: RunTimes in Community fails" "CommunityFeature/Feed/Leak.swift:1"
echo "/// Never shows RunTimes to other people." > "$TMP/tree/VybeKit/Sources/CommunityFeature/Feed/Leak.swift"
expect_pass "rule 3: a comment that only mentions RunTimes passes"
mkdir -p "$TMP/tree/VybeKit/Sources/ProfileFeature/Profile"
echo "let own: RunTimes? = nil" > "$TMP/tree/VybeKit/Sources/ProfileFeature/Profile/Own.swift"
expect_pass "rule 3: RunTimes in Profile (own runs) passes"

# Rule 4: a feature depending on another feature, and LocalData in the shared list.
fresh_copy
sed -i.bak 's/name: "DiscoverFeature", dependencies: featureDeps/name: "DiscoverFeature", dependencies: ["Models", "Core", "ChatFeature"]/' \
  "$TMP/tree/VybeKit/Package.swift"
expect_fail "rule 4: a feature depending on another feature fails" "DiscoverFeature must not depend on ChatFeature"
fresh_copy
sed -i.bak 's/"Design", "Components"\]$/"Design", "Components", "LocalData"]/' "$TMP/tree/VybeKit/Package.swift"
expect_fail "rule 4: LocalData in the shared feature list fails" "must not depend on LocalData"

if [ "$problems" -gt 0 ]; then
  echo "==> $problems self-test problem(s)" >&2
  exit 1
fi
echo "==> Architecture check self-test passed"
