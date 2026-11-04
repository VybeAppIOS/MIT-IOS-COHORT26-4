# 003: Routes grouped per feature, `Codable`, all declared up front; a stack for sheets
Status: accepted as the working default (4 Nov 2026). Date: 4 Nov 2026

## Context
- A single flat `Route` enum plus one `ScreenFactory` `switch` is touched by every screen task, and the plan said
  Phase 2 cases would be added later "by the owner", so the two hottest files would change all the time.
- The router sketch has gaps found on review (not compiled, found by reading):
  1. `Report` is meant to be pushed *inside* a sheet, but the router has no stack for a sheet, so
     `router.open(.report)` would push onto the tab behind the sheet.
  2. `paths` is `private(set)`, but `NavigationStack(path:)` needs a binding the system can write (back swipe).
  3. Routes are not `Codable`, so state restoration, deep links and a debug "open this screen" launch (ADR-006)
     would be retrofits.

## Decision
1. **`Route` has one case per feature, carrying that feature's own route enum**, for example
   `Route.hangoutDetail(HangoutDetailRoute)`. Feature route enums live in
   `Core/Navigation/Routes/<Feature>Route.swift`. The same file defines the short constructors used everywhere
   (`Route.hangout(id)`, `.saved`, `.settings`, `.conversation(id)`), so the names in `docs/IA.md` and the task files
   stay valid. A route belongs to the feature that owns the screen.
2. **F-4 declares every route for every screen in `docs/IA.md`**, including screens built later. Their
   `Screens` placeholder shows the screen ID. After F-4, adding a screen edits only the owner's two files (route
   enum case + `Screens` case); the App is untouched.
3. `Route`, the feature route enums, `Sheet`, `Cover`, `StackID`, `AppTab` and all payloads are
   `Hashable, Codable, Sendable`. Payloads are IDs and small enums only. A saved route that no longer decodes is
   ignored, never a crash.
4. **Stacks:** one per tab, one for onboarding, one per cover, and **one for the sheet that is up**
   (`StackID.sheet`). The router's current stack is the sheet's if a sheet is up, else the cover's, else the
   selected tab's. `dismissSheet()` clears the sheet stack.
5. The router exposes `setPath(_:for:)` (and keeps `paths` readable). `TabShell` and the hosts build the `Binding`
   from it, so the system can pop. Core stays free of SwiftUI.
6. Unchanged from `ARCHITECTURE.md` 2.6: one `NavigationStack` per tab, routes carry IDs only, `selectedTab` is
   always a visible tab, Search is the trailing search-role tab, two sheet hosts (TabShell while no cover, each cover
   root while a cover is up), local sheets stay a flag in the ViewModel, deep-link policy table.

```swift
// Core/Navigation/Routes/HangoutDetailRoute.swift  (UNVERIFIED sketch)
public enum HangoutDetailRoute: Hashable, Codable, Sendable {
    case detail(HangoutID)            // HD1
    case remixTree(HangoutID)         // HD3
}
public extension Route {
    static func hangout(_ id: HangoutID) -> Route { .hangoutDetail(.detail(id)) }
    static func remixTree(_ id: HangoutID) -> Route { .hangoutDetail(.remixTree(id)) }
}
// Core/Navigation/Route.swift
public enum Route: Hashable, Codable, Sendable {
    case onboarding(OnboardingRoute), auth(AuthRoute), hangoutDetail(HangoutDetailRoute),
         live(LiveRoute), posting(PostingRoute), search(SearchRoute), profile(ProfileRoute),
         community(CommunityRoute), friends(FriendsRoute), chat(ChatRoute),
         moderation(ModerationRoute), editor(EditorRoute)     // Discover has no pushed routes of its own
}
```

## Consequences
- Easier: no hotspot; exhaustive `switch` at two levels; state restoration, deep links and debug launch are nearly free.
- Harder: two small files per new screen instead of one enum line; a reader must learn `Route.hangout(id)` is
  sugar for a nested case.
- Undo: flatten the enums; the static constructors keep every call site unchanged.

## Router tests F-4 must contain
`open` on tab / cover / sheet stacks; a pushed Report inside a sheet lands on the sheet stack and disappears with the
sheet; `setPath` shrinks a stack (back swipe); `show(_:in:)` clears cover and sheet; `reset`; `lastNonSearchTab`
ignores `.search` (checks that `didSet` on an `@Observable` property fires; if not, use a method); every route
round-trips through JSON.

## F-0 results (4 Nov 2026, Xcode 27.1, iPhone 18 Pro simulator)
- [x] `TabView` with `Tab(value:role: .search)` last renders as the trailing Search tab (simulator screenshot).
      `.searchable` inside the search stack compiled; typing into it was **not exercised** (needs a manual check).
- [x] `NavigationStack(path:)` bound to a `[Route]` in an `@Observable` router compiles; unit test: `setPath` shrinks the path.
- [ ] The real **back swipe** was **not driven** (no UI automation). Manual check pending; the fallback is unchanged.
