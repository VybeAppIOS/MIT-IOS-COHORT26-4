# 002: Each feature builds its own screens; one public `Screens` type; `AppDependencies` container
Status: accepted as the working default (4 Nov 2026); F-0 and F-9 verify it. Date: 4 Nov 2026

## Context
- The plan had the App target's `ScreenFactory` build every ViewModel with its dependencies (about 60 screens).
  That file would be edited by every screen task (merge conflicts on neighbouring lines), the App would need to
  know every ViewModel `init` (so every View and ViewModel had to be `public` with a hand-written `public init`),
  and a wiring mistake would only show up in the App target. This is mentor question 3 in `ARCHITECTURE.md` 11.

## Options
A. App-owned `ScreenFactory` builds all ViewModels (status quo).
B. Each feature owns its wiring; the App only calls one function per feature (chosen).
C. SwiftUI Environment or a DI library (rejected: ViewModels cannot read the Environment; no libraries).

## Decision
1. **Every feature exposes exactly one public type, `<Name>Screens`** (an `enum`) in `<Name>Screens.swift`, with
   `@ViewBuilder public static func` entry points that return `some View`:
   `view(for: <Name>Route, _ deps: AppDependencies)`, plus `root(_ deps:)` for a tab root and one function per
   router sheet or cover the feature owns (for example `HangoutDetailScreens.spotSheet(_:_:)`).
   **Views, ViewModels, previews and helpers are `internal`.** Tests use `@testable import`.
2. **`AppDependencies`** is a plain `Sendable` struct in `Core`: the repositories as `any ...Repository`, the stores,
   the `Router`, `FeatureFlags`, and the clock. It is built in two places:
   `AppDependencies.local()` in the App target (real wiring: LocalData now, Remote later) and
   `AppDependencies.preview(_ mode: StubMode)` in `Core/Fakes` (`#if DEBUG`, all stubs).
3. Only `*Screens.swift` files (and the App and Core) may mention `AppDependencies`. A ViewModel `init` still takes
   only the repositories and stores it needs, never the whole container.
4. The App target keeps a **thin** `ScreenFactory`: one `case` per feature route group, per `Sheet`, per `Cover`.
   It never names a View or ViewModel. `TabShell` calls `DiscoverScreens.root(deps)` and friends.
5. Previews call the same `Screens` function with `AppDependencies.preview(.loaded)`, so preview wiring and real
   wiring cannot drift.
6. A placeholder screen (`Text("HD3")`) lives in each feature's `Screens` until its task replaces that one `case`.
   Task **F-16** creates all 13 `Screens` files so nobody edits the App to add a screen.

```swift
// HangoutDetailFeature/HangoutDetailScreens.swift  (UNVERIFIED sketch; F-9 compiles it)
import Core
import Models
import SwiftUI

public enum HangoutDetailScreens {
    @ViewBuilder
    public static func view(for route: HangoutDetailRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .detail(let id):
            HangoutDetailView(viewModel: HangoutDetailViewModel(
                id: id, hangouts: deps.hangouts, places: deps.places,
                library: deps.library, liveStore: deps.liveStore, router: deps.router))
        case .remixTree:
            Text("HD3")                       // replaced by task SC-HD3
        }
    }
    @ViewBuilder
    public static func spotSheet(_ id: PlaceID, _ deps: AppDependencies) -> some View { Text("HD2") }
}
```

## Consequences
- Easier: no merge hotspot in the App; far fewer `public` declarations; a feature owner changes only their folder;
  the compiler enforces exhaustiveness inside each feature.
- Harder: `AppDependencies` lists every repository protocol, so adding a repository edits one Core file (rare; lead
  reviews). Inside `Screens` a feature can see the whole container; lint limits where it may be used (ADR-006).
- Undo: make the types `public` again and move the `switch` into the App. Mechanical but large; decide now.

## Verify in F-0 / F-9
- [ ] A feature target with `internal` View and ViewModel plus a `public` `Screens` compiles; the App target calls
      it; a `@testable import` test passes under `xcodebuild test`.
- [ ] `#Preview` inside the feature works with `AppDependencies.preview(.loaded)`.
