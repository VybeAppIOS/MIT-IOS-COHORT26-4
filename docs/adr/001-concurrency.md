# 001: Core is not main-actor by default; Swift 6 language mode from the start
Status: accepted as the working default (4 Nov 2026); F-0 verifies it on a Mac. Date: 4 Nov 2026

## Context
- UI targets use `defaultIsolation(MainActor)` plus `NonisolatedNonsendingByDefault` (`Package.swift`, `uiSettings`).
  Core was given the same settings, but Core mixes two kinds of code: things that must be on the main actor
  (`Router`, stores) and things that must not be (repository protocols, `Rules/`, services that `LocalData` and
  `Remote` implement).
- The old rule was "hand-write `nonisolated` on the second kind". Forgetting it fails to compile in `LocalData`, or
  worse, compiles and runs JSON loading on the main thread (`NonisolatedNonsendingByDefault` makes a plain `async`
  method run on the caller's actor). Four beginners and their agents will forget it.
- Package and app are in Swift 5 language mode. The code base is empty now, which is the cheapest moment to
  choose; every screen written in Swift 5 mode makes a later move to Swift 6 mode more expensive.

## Options
A. Keep Core main-actor by default and hand-mark `nonisolated` (status quo).
B. Core non-isolated by default; mark only the few main-actor types `@MainActor` (chosen).
C. Split Core into two targets, one per isolation (more targets, same result as B).

## Decision
1. **Models, Core, LocalData (and later Remote) have no default isolation and do not enable
   `NonisolatedNonsendingByDefault`.** A plain `async` repository method then hops off the main thread by design.
2. In Core, only these are `@MainActor`, written explicitly: `Router`, every store (`SessionStore`, `LibraryStore`,
   `LiveHangoutStore`, `BadgeStore`), `NetworkMonitor`, and the `AppDependencies.preview(_:)` factory.
   **Never** put `@MainActor` on a repository protocol, a rule, or a service protocol.
3. Design, Components and every Feature keep `defaultIsolation(MainActor)` and `NonisolatedNonsendingByDefault`.
4. **Swift 6 language mode** for the package (remove `swiftLanguageModes: [.v5]`) and `SWIFT_VERSION = 6.0` for the app.
   `Remote` may opt down per target (`.swiftLanguageMode(.v5)`) if the backend SDK is not ready.
5. Data-race errors are fixed properly. Never silence them with `@unchecked Sendable`, `nonisolated(unsafe)` or
   `MainActor.assumeIsolated` without a human saying yes.
6. All models are `Sendable` value types; repository protocols are `Sendable`; no global mutable state.

## Consequences
- Easier: nobody writes `nonisolated` by hand; repositories run off the main thread by default; the compiler checks
  data races for AI-written code.
- Harder: a few concurrency errors for beginners. Most code (Views, ViewModels) needs no annotations because the UI
  targets default to the main actor. Core and LocalData are written by the lead or reviewed by the lead.
- Undo: restore `swiftLanguageModes: [.v5]` and `SWIFT_VERSION = 5.0` (two lines). If Swift 6 mode blocks F-0,
  stay in Swift 5 mode with complete strict-concurrency checking as warnings, errors in CI, and write that here.

## Verify in F-0 (60 minutes per item; stop and record the fallback)
- [ ] A `@MainActor @Observable` store in Core is used from a ViewModel in a Feature target without warnings.
- [ ] A `Sendable` repository protocol in Core, implemented in LocalData by a struct that reads a bundled JSON file,
      runs off the main thread (check with `Thread.isMainThread` in a test) and compiles in Swift 6 mode.
- [ ] The empty skeleton and the F-0 spike compile in Swift 6 mode with zero warnings.
