# Core

Uses Models. Router and routes, repository protocols, fakes, stores, services, rules, logging.

Not main-actor by default (`docs/adr/001-concurrency.md`): protocols, rules and services are plain `Sendable` types; only
`Router`, the stores, `NetworkMonitor` and `AppDependencies.preview` are `@MainActor`, written explicitly. Never write
`nonisolated` by hand. `AppDependencies` lives here (`docs/adr/002-feature-owned-screens.md`).

See `docs/ARCHITECTURE.md` section 3.2 (folder map, import rules, "where does X go?").
