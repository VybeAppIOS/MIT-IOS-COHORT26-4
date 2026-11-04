#!/usr/bin/env bash
# Task X-13: the architecture rules a SwiftLint regex cannot express (docs/adr/006-guardrails-and-agent-loop.md).
#   1. every *Feature has <Name>Screens.swift
#   2. every FooViewModel.swift has a FooViewModelTests.swift somewhere under VybeKit/Tests/
#   3. RunTimes appears only in Models, Core, LocalData, Remote, LiveFeature, PostingFeature and ProfileFeature
#   4. no feature's Package.swift dependency list names another feature, LocalData or Remote
# bash, grep, find and awk only, so it also runs on the Linux lint runner. Prints "file:line: message" for each
# violation and exits non-zero. Do not silence failures. Set ARCH_ROOT to check another copy of the tree (the self-test).
set -uo pipefail

ROOT="${ARCH_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT" || exit 2

SOURCES="VybeKit/Sources"
TESTS="VybeKit/Tests"
PACKAGE="VybeKit/Package.swift"
violations=0

fail() {
  echo "$1: $2"
  violations=$((violations + 1))
}

echo "==> Architecture rules"

# 1. Every feature has its Screens file (ADR 002).
for dir in "$SOURCES"/*Feature; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  short="${name%Feature}"
  [ -f "$dir/${short}Screens.swift" ] || fail "$dir" "missing ${short}Screens.swift (every feature has one: ADR 002)"
done

# 2. Every ViewModel has a test file somewhere under VybeKit/Tests/ (AGENTS.md 6).
while IFS= read -r file; do
  [ -n "$file" ] || continue
  base="$(basename "$file" .swift)"
  if [ -z "$(find "$TESTS" -name "${base}Tests.swift" -print -quit 2>/dev/null)" ]; then
    fail "$file" "no ${base}Tests.swift under $TESTS (every ViewModel has a test)"
  fi
done < <(find "$SOURCES" Vybe -name '*ViewModel.swift' 2>/dev/null | sort)

# 3. RunTimes (private visit times) stays in the modules that own a person's own runs (ADR 004, 006).
allowed='^VybeKit/Sources/(Models|Core|LocalData|Remote|LiveFeature|PostingFeature|ProfileFeature)/'
while IFS=: read -r file line text; do
  [ -n "$file" ] || continue
  trimmed="$(printf '%s' "$text" | sed 's/^[[:space:]]*//')"
  case "$trimmed" in //*) continue ;; esac   # a comment may mention it
  if [[ ! "$file" =~ $allowed ]]; then
    fail "$file:$line" "RunTimes may only appear in Models, Core, LocalData, Remote, Live, Posting and Profile (ADR 006)"
  fi
done < <(grep -rnw --include='*.swift' 'RunTimes' "$SOURCES" 2>/dev/null)

# 4. A feature depends on Models, Core, Design and Components only (ADR 002, ARCHITECTURE 3.2).
if [ -f "$PACKAGE" ]; then
  while IFS= read -r message; do
    [ -n "$message" ] || continue
    fail "${message%%|*}" "${message#*|}"
  done < <(awk '
    function check(line, feature, deps,   rest, token) {
      rest = deps
      while (match(rest, /"[A-Za-z0-9_]+"/)) {
        token = substr(rest, RSTART + 1, RLENGTH - 2)
        rest = substr(rest, RSTART + RLENGTH)
        if (token ~ /Feature$/ || token == "LocalData" || token == "Remote") {
          printf "%s:%d|%s must not depend on %s (a feature uses Models, Core, Design and Components only)\n", \
            FILENAME, line, feature, token
        }
      }
    }
    /let featureDeps/ { shared = $0; sharedLine = NR }
    /\.target\(name: "[A-Za-z0-9]+Feature"/ && !inTarget {
      inTarget = 1; start = NR; text = ""; depth = 0
      match($0, /name: "[A-Za-z0-9]+"/)
      feature = substr($0, RSTART + 7, RLENGTH - 8)
    }
    inTarget {
      text = text " " $0
      opened = gsub(/\(/, "(", $0); closed = gsub(/\)/, ")", $0)
      depth += opened - closed
      if (depth <= 0) {
        inTarget = 0
        if (text ~ /dependencies: *featureDeps/) {
          usesShared = 1
        } else if (match(text, /dependencies: *\[[^]]*\]/)) {
          check(start, feature, substr(text, RSTART, RLENGTH))
        }
      }
    }
    END { if (usesShared) check(sharedLine, "the features (featureDeps)", shared) }
  ' "$PACKAGE")
fi

if [ "$violations" -gt 0 ]; then
  echo "==> $violations architecture violation(s). Fix them; do not weaken the script." >&2
  exit 1
fi
echo "==> Architecture rules passed"
