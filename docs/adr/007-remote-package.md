# 007: The backend lives in its own package `VybeRemote`
Status: proposed (backend phase, decide at BK-2). Date: 4 Nov 2026

## Context
`Remote` was planned as a target of `VybeKit`. A backend SDK (Firebase or Supabase) is large. Inside `VybeKit` it would
be resolved and compiled by every `check.sh` run, by every feature's tests, and it makes dropping a backend that did not
work out a change inside the core package. It also needs an exception to "no third-party libraries".

## Decision
- `VybeRemote/` is a second local Swift package that depends on `VybeKit` (Models, Core) and on the backend SDK. It holds
  the DTOs, the mappers to Models, the `Remote*Repository` implementations and `AppDependencies.remote()`.
- `VybeKit` stays dependency-free. The SDK exception is limited to `VybeRemote` and written in `AGENTS.md` at BK-2.
- `VybeRemote` may use Swift 5 language mode per target if the SDK needs it (ADR-001).
- The App target links both packages and chooses `AppDependencies.local()` or `.remote()`.
- `VybeRemote` runs the same contract checks as LocalData (ADR-004).

## Consequences
Easier: fast checks for feature work; the backend choice is reversible by deleting one folder. Harder: one more
`Package.swift` (lead-only) and an App-level wiring switch. Nothing to do until BK-2; keep Core free of SDK types.
