#!/usr/bin/env bash
# Proves that every custom SwiftLint rule in .swiftlint.yml works (task X-1).
# It lints LintFixtures/ and compares the result with the `// expect: <rule_id>` tags there:
#   1. every tagged line must be reported with that rule   (the rule catches what it should),
#   2. no untagged line may be reported by a custom rule   (no false alarms),
#   3. every custom rule must have at least one tagged example.
# Exits non-zero if any check fails. Do not silence failures.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "swiftlint not found. Install it, then run this script again." >&2
  exit 1
fi

report="$(mktemp)"
trap 'rm -f "$report"' EXIT

echo "==> SwiftLint on LintFixtures/ ($(swiftlint version))"
# Pass the fixture FILES one by one: a folder argument is filtered through the config's `included:` list,
# while an explicit file is linted even though `excluded:` lists LintFixtures (that keeps it out of check.sh).
fixtures=()
while IFS= read -r -d '' file; do fixtures+=("$file"); done < <(find LintFixtures -name '*.swift' -print0 | sort -z)
# SwiftLint exits non-zero when it finds violations; that is expected here.
swiftlint lint --config .swiftlint.yml --reporter json --no-cache --quiet "${fixtures[@]}" > "$report" || true

python3 -I - "$PWD" "$report" <<'PY'
import json, os, re, sys

root, report_path = sys.argv[1], sys.argv[2]

config = open(os.path.join(root, ".swiftlint.yml"), encoding="utf-8").read()
custom_section = config.split("\ncustom_rules:", 1)[1] if "\ncustom_rules:" in config else ""
custom = re.findall(r"^  ([a-z_]+):[ \t]*$", custom_section, re.M)
if not custom:
    sys.exit("No custom_rules found in .swiftlint.yml")

try:
    reported = json.load(open(report_path, encoding="utf-8"))
except ValueError:
    sys.exit("SwiftLint did not produce a JSON report. Run it by hand to see the error.")
actual = {(os.path.relpath(v["file"], root), v["line"], v["rule_id"])
          for v in reported if v["rule_id"] in custom}

expected = set()
for folder, _, names in os.walk(os.path.join(root, "LintFixtures")):
    for name in sorted(names):
        if not name.endswith(".swift"):
            continue
        path = os.path.join(folder, name)
        rel = os.path.relpath(path, root)
        for number, line in enumerate(open(path, encoding="utf-8"), 1):
            tag = re.search(r"//\s*expect:\s*([a-z_,\s]+?)\s*$", line)
            if tag:
                for rule in re.split(r"[,\s]+", tag.group(1)):
                    if rule:
                        expected.add((rel, number, rule))

unknown = sorted(r for r in {e[2] for e in expected} if r not in custom)
missed = sorted(expected - actual)
false_alarms = sorted(actual - expected)
untested = sorted(set(custom) - {e[2] for e in expected})

for rule in custom:
    want = sum(1 for e in expected if e[2] == rule)
    got = sum(1 for e in expected if e[2] == rule and e in actual)
    print(f"  {'ok  ' if want and got == want else 'FAIL'} {rule:<34} caught {got}/{want}")

def show(title, items):
    if items:
        print(f"\n{title}:")
        for file, line, rule in items:
            print(f"  {file}:{line}  {rule}")

show("Missed (tagged line was NOT reported)", missed)
show("False alarms (untagged line WAS reported)", false_alarms)
for rule in untested:
    print(f"\nNo example: rule '{rule}' has no `// expect:` line in LintFixtures/")
for rule in unknown:
    print(f"\nUnknown rule in an expect tag: '{rule}'")

if missed or false_alarms or untested or unknown:
    print(f"\nFAILED: {len(missed)} missed, {len(false_alarms)} false alarms, "
          f"{len(untested)} rules without an example, {len(unknown)} unknown tags.")
    sys.exit(1)
print(f"\nAll {len(custom)} custom rules caught {len(expected)}/{len(expected)} violations, no false alarms.")
PY
