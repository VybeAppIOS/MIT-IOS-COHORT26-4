# Architecture decision records (ADRs)

Short records of the decisions that are expensive to change later. Written 4 Nov 2026 in the replan.
**Where an ADR and an older document disagree, the ADR wins.** Template: `docs/PROCESS.md` 4.2.

Nothing here has been compiled yet (the repo has no Swift code). Task **F-0** (Lohitaksh, on a Mac) proves
the items marked "verify in F-0" and records the result at the bottom of each ADR. If a proof fails, change
the ADR first, then the code.

| # | Decision | Status | Touches |
|---|---|---|---|
| [001](001-concurrency.md) | Core is not main-actor by default; Swift 6 language mode from the start | accepted, verify in F-0 | `Package.swift`, project setting |
| [002](002-feature-owned-screens.md) | Each feature builds its own screens; one public `Screens` type; `AppDependencies` container | accepted, verify in F-0 | every feature, App |
| [003](003-navigation.md) | Routes grouped per feature, `Codable`, all declared up front; a stack for sheets | accepted | `Core/Navigation` |
| [004](004-data-contract.md) | One JSON coder, ID dictionary keys, contract checks, injected clock, samples never invent | accepted, verify in F-0 | Models, Core, LocalData |
| [005](005-state-and-persistence.md) | Refresh never erases content, cancellation is not an error, one serial disk writer | accepted | ViewModels, stores, LocalData |
| [006](006-guardrails-and-agent-loop.md) | Machine-checked rules, debug launch options, screenshot script, screen generator, review tiers | accepted | lint, scripts, App |
| [007](007-remote-package.md) | The backend lives in its own package `VybeRemote` | proposed (backend phase) | later |

Reading order for a new teammate: 001, 002, 003 (about 10 minutes). The rest when your task names them.
