# 004: One JSON coder, ID dictionary keys, contract checks, injected clock, samples never invent
Status: accepted as the working default (4 Nov 2026); F-1 tests verify the coding items. Date: 4 Nov 2026

## Context
The same `Codable` structs are read from bundled JSON now and from a backend later. Four details decide whether
that swap is a one-line change or a rewrite, and all four are cheap to get right before the first model is written.

## Decision
1. **One shared coder** in `Models` (`JSONCoding.decoder` / `.encoder`): ISO 8601 dates **with and without
   fractional seconds** (Firestore and Postgres emit fractions; the built-in `.iso8601` strategy is not guaranteed
   to accept them), unknown keys ignored, `.sortedKeys` and `.prettyPrinted` for content files so diffs are stable.
   LocalData and Remote use only this. Tests cover both date forms.
2. **`ID<Tag>` conforms to `CodingKeyRepresentable`**, so `[SpotID: Date]` (`RunTimes.visitedAt`) is a JSON
   *object*. Without it Swift writes a flat `[key, value, key, value]` array, which is a data-format trap that no
   backend mapping would match. Test: encode `[SpotID: Date]` and assert the JSON is an object.
3. **Versioning:** every top-level JSON file has `schemaVersion`; new fields are optional; team-grown lists
   (category, tags, report reasons) are string-backed with an `unknown` fallback. The loader accepts older versions
   and rejects a newer major version with a clear error.
4. **Repository contract checks:** plain throwing functions in `Core/Fakes/Contracts/`
   (`HangoutRepositoryContract.verify(_ repo:)`, no test framework imported) that every implementation calls from its
   own test: LocalData now, Remote later. Stubs support `loaded / empty / failing / neverReturns`.
5. **Time and IDs are injected.** Anything that needs "now" or a new ID takes `now: @Sendable () -> Date` and
   `makeID: @Sendable () -> String` with production defaults; tests pass fixed values. Rules take dates as
   parameters and never call `Date()`.
6. **Samples never invent.** `Models/Samples` places and Hangouts are copies of the real X-C1 content. A ContentTests
   test fails if a sample differs from the bundled JSON. Sample *people* are clearly fake (`user-sample-...`).
   Until X-C1 is merged, previews use only the two EXAMPLE Hangouts from `DATA-MODEL.md` 4, labelled `EXAMPLE`; an
   agent that invents a venue name, coordinate, price or hours breaks `AGENTS.md` 4.
7. **The client holds exact visit times in one place.** `RunTimes` is owner-only; posts carry `visitOrder` and a
   rounded duration. Where `RunTimes` may appear is machine-checked (ADR-006).

## Consequences
Easier: the backend swap changes only `Remote`; bad data is caught by tests, not on a device; agents cannot
silently invent places. Harder: the content test and sample test must be kept green when content changes.
Undo: each item is independent.

## Verify
- [ ] F-1 tests: ID dictionary key is a JSON object; both date forms decode; a `Place` ID cannot be passed as a `Hangout` ID.
- [ ] F-8: `schemaVersion` handling and the samples-equal-content test pass.

## F-0 results (4 Nov 2026, Xcode 27.1, iPhone 18 Pro simulator)
- [x] `String(localized: "key", bundle: #bundle)` AND `bundle: .module` both find `Localizable.xcstrings` in the Design
      package target. Use `#bundle` (feeds X-3).
- [x] A colour in `Design/Resources/Colors.xcassets` resolves via `UIColor(named:in:)` with `.module` in a test, and a
      view using `Color("…", bundle: .module)` rendered in the app. Canvas preview not opened by the agent.
