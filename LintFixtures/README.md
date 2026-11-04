# LintFixtures (task X-1)

Deliberate SwiftLint violations that prove every custom rule in `.swiftlint.yml` works.
Never compiled (outside `Vybe/`, `VybeTests/` and the `VybeKit` package) and excluded from normal lint.

- A line ending in `// expect: <rule_id>` must be reported with that rule.
- Every other line must NOT be reported by a custom rule (must-pass examples).
- The folders copy the real paths because many rules are path-scoped.

Run `scripts/check_lint_rules.sh` after changing any custom rule.
