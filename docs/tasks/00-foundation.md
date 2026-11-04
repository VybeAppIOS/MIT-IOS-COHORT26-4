# Foundation tasks (do these first; they unblock everything)

Size: **S** ≈ half a day · **M** ≈ one day · **L** ≈ one and a half to two days. "DoD" = `AGENTS.md` section 6. Before any task read
`docs/START-HERE.md` and the ADRs your task names (`docs/adr/`; they win over older documents). Code goes in
`VybeKit/Sources/<Module>/`. Types in `Models` and `Core` that other modules use are `public` with an explicit `public init`.
**Isolation (ADR 001):** `Models`, `Core` and `LocalData` are not main-actor by default: write plain `public protocol X: Sendable`;
never hand-write `nonisolated`; never put `@MainActor` on a repository protocol, a rule or a service protocol (only `Router`, the
stores, `NetworkMonitor` and `AppDependencies.preview` are `@MainActor`). **Features (ADR 002):** a feature's only `public` type is
its `<Name>Screens`; Views and ViewModels are `internal`.

Gates (proof, not dates): **G1** = F-0 merged (settings final; Core tasks may start). **G2** = F-4, F-5, F-16, F-9, DS-1/2/3 merged
(the app runs; screens may start). **G3** = SC-HD1 merged (the golden screen exists; copy it with `scripts/new_screen.py`). Order:
Models (F-1 to F-3), Design (DS-*), content (X-C*) and tooling (X-*) do not wait for G1; everything that writes code in `Core/`
waits for F-0; then F-4 and DS-1 in parallel; then F-5, F-16, F-6, F-7, F-8, F-9, F-10. After G2 every other task is open.

### F-0 — Link VybeKit, set the concurrency and language modes, prove the architecture  `[M]`  *(Lohitaksh only: project settings)*
- **Depends on:** nothing
- **Status:** **done 4 Nov 2026** (PR 1); the results are at the bottom of ADRs 001 to 004. Still to verify later: previews in the
  package canvas (proof a, at SC-HD1 or F-9), typing into `.searchable` (proof f, F-9) and the real back swipe (proof g, F-9).
- **Unlocks (G1):** every task that writes code in `Core/` (F-4, F-5, F-6, F-7, F-10, F-11, F-13, F-14, F-15) and F-16.
- **Read:** `docs/adr/001-concurrency.md` to `004` · ARCHITECTURE 3.1, 3.2 · BEFORE-BUILD 3
- **What it did:** linked `VybeKit` to the app target (the libraries Models, Core, Design, Components, LocalData and all 13 `*Feature`
  libraries); took `uiSettings` off Core (Models, Core and LocalData: no default isolation, no `NonisolatedNonsendingByDefault`);
  removed `swiftLanguageModes: [.v5]` and set `SWIFT_VERSION = 6.0`; exercised with a throwaway slice (deleted at the end): (a) a
  `#Preview` in a Feature target, (b) a `@MainActor @Observable` store used from an `internal` ViewModel, (c) a `Sendable`
  repository reading bundled JSON through `Bundle.module` off the main thread, (d) a Feature with `internal` View/ViewModel and a
  `public` `Screens` called from the App with a `@testable import` test, (e) strings and colours in a package target, (f) a
  `TabView` with `Tab(role: .search)` last and `.searchable` inside the search stack, (g) a `NavigationStack(path:)` bound to a
  `[Route]` in an `@Observable` router. Each item had a 60-minute limit and a written fallback (ADR).
- **Files:** `Vybe.xcodeproj` (via Xcode only), `VybeKit/Package.swift`, `docs/adr/*` (results)
- **Done when:** the app builds with `import Models`; `./scripts/check.sh` is green; every proof is ticked or has a written
  fallback; the throwaway code is deleted.

### F-1 — IDs, shared value types and the JSON coder  `[S]`
- **Depends on:** nothing
- **Note:** do this first (Lohitaksh does F-0 at the same time); it blocks most other foundation tasks. `Models` is not
  main-actor isolated and every type is `Sendable`.
- **Read:** DATA-MODEL 2, 5 · ARCHITECTURE 2.1, 2.5 · `docs/adr/004-data-contract.md`, `docs/adr/005-state-and-persistence.md`
- **Build in `Models`:** `ID<Tag>` (the generic typed ID from DATA-MODEL 5: `Hashable`, `Codable` as a plain string,
  `Sendable`, `ExpressibleByStringLiteral`, **and `CodingKeyRepresentable`** so an ID works as a JSON object key) and
  typealiases `PlaceID, HangoutID, SpotID, RunID, PhotoID, UserID, CommentID, ConversationID, MessageID, ReportID`;
  `Coordinate`; `RupeeRange { lower, upper }` with a `formattedPerPerson` that uses
  `.formatted(.currency(code: "INR"))` (en_IN grouping); `Photo`; `ReportTarget` (IDs only: run, comment, user,
  message or place; used by `Report` in F-3 and by the router in F-4); `AppError` (`Error`, `Equatable`, `Sendable`,
  `init(_ error:)`, a friendly `message`; at least `notFound`, `offline`, `invalid(String)`, `unknown`);
  `LoadState<Content>` (`loading / loaded(_, isStale:) / empty / failed`) with `Equatable` conformance when
  `Content: Equatable`; `Page<T>` (items, `nextCursor: String?`); **`JSONCoding`** (`decoder` and `encoder`: ISO 8601
  dates with and without fractional seconds, unknown keys ignored, `.sortedKeys`); and **display formatting helpers**
  in `Models/Formatting/` (money `₹150–400`, duration "about 3 h", distance in km, compact counts; all through
  `.formatted(...)`) so every feature, and every `*Data` initializer in `Components`, writes these the same way.
- **Files:** `Models/Content/IDs.swift, Coordinate.swift, RupeeRange.swift, Photo.swift` ·
  `Models/Safety/ReportTarget.swift` · `Models/State/LoadState.swift, Page.swift, AppError.swift` ·
  `Models/Coding/JSONCoding.swift` · `Models/Formatting/*.swift` · tests in `Tests/ContentTests/`
- **Done when:** `swift`/Xcode builds; tests: an ID encodes/decodes as a plain JSON string; **a `[SpotID: Date]` encodes
  as a JSON object, not an array**; a date with and without fractional seconds both decode; a `Place` ID cannot be passed
  where a `Hangout` ID is expected (compile-time, show in a comment); `RupeeRange` formats `₹150–400`; 170 minutes formats as "about 3 h".

### F-2 — Content models  `[M]`
- **Depends on:** F-1
- **Read:** DATA-MODEL 3 (Content, Doing and posting, People), 4, 5, 7 · IA 3
- **Build in `Models/Content/`:** `Place` (+ `OpeningPeriod`, `PlaceStatus` incl. `closedByAuthorities`,
  optional `TrekInfo` with difficulty/season/start point/safety note), `Spot`, `HangoutStatus`,
  `Hangout` (fields exactly as DATA-MODEL 3), `Visit` (spotID, placeID, order), `RunTimes`
  (owner-only: startedAt, endedAt, visitedAt per Spot), `RunState` (`live/done/scheduled/posted`),
  `Visibility`, `HangoutRun`, `HangoutFilters` (budget range, max minutes, categories, tags, "good for groups"), `UserProfile` (public part + settings: who can comment / request /
  add me to groups / show me in search / default audience) and `AccountPrivate`. JSON key names =
  property names; dates ISO 8601.
- **Files:** `Models/Content/*.swift`, `Models/People/UserProfile.swift` · tests in `ContentTests/`
- **Done when:** each type decodes the EXAMPLE JSON in DATA-MODEL 4 (copy it into a test);
  encode → decode round-trips; unknown extra JSON keys are ignored; `Spot` ordering preserved.

### F-3 — Community, chat and safety models  `[M]`
- **Depends on:** F-1
- **Read:** DATA-MODEL 3 (Community rows, Chat, Safety), 6a · IA 3
- **Build in `Models/Community/`, `Chat/`, `Safety/`:** `Comment` (threaded via `parentID`),
  `Like` (+ target enum run/comment), `FriendRequest` (with `isOther`), `Friendship`, `Block`,
  `Conversation` (dm/group), `Membership` (role, `status` pending/active, joinedAt, lastReadAt),
  `Message` with `MessagePayload` (`text / photos(≤2) / hangout(HangoutID) / link(URL) /
  voice(path, seconds) / poll(question)`, encoded as `{"kind": "...", ...}`), `PollVote`,
  `Report` (+ `ReportReason`; `ReportTarget` comes from F-1), `Activity` (+ kinds), `GuestResponse`,
  `PlaceSuggestion` (+ status), `RemixCredit`.
- **Files:** `Models/Community/*.swift, Chat/*.swift, Safety/*.swift` · tests in `ContentTests/`
- **Done when:** every type round-trips JSON; `MessagePayload` decodes each kind; `Report` has all
  reasons listed in PRODUCT 4 (Safety defaults); `Report` uses F-1's IDs-only `ReportTarget`.

### F-4 — Navigation: grouped Routes, Sheet, Cover, Router  `[M]`
- **Depends on:** F-0, F-1
- **Read:** `docs/adr/003-navigation.md` · ARCHITECTURE 2.6 (its Router code is the base; ADR 003 changes the `Route`
  enum, adds the sheet stack and `setPath`, and wins where they differ) · IA 4 and 5
- **Build in `Core/Navigation/`:** `AppTab` (discover, community, profile, search); `StackID` (`onboarding`, `tab(AppTab)`,
  `live`, `editor`, `sheet`); the **12 feature route enums** in `Routes/<Feature>Route.swift` (every feature except Discover, whose screens are a
  tab root, a card and a local sheet), covering **every pushed screen in `docs/IA.md` section 4, all phases**, each file also holding that feature's short constructors (`Route.hangout(id)`,
  `.saved`, `.settings`, `.conversation(id)` ... the names the docs already use); `Route` (one case per feature);
  `Sheet` and `Cover` (each with `id`); the payload types `EditorStart`, `SettingsPage`, `AdminPage`, `SearchKind` and
  `ShareItem` (IDs and small enums only; `ReportTarget` comes from F-1); all of them `Hashable, Codable, Sendable`; and
  `Router` (`@MainActor @Observable`: `open, pop, popToRoot, setPath(_:for:), present, dismissSheet, presentCover,
  dismissCover, show(_:in:), reset`, `lastNonSearchTab`). The current stack is the sheet's if a sheet is up, else the
  cover's, else the selected tab's.
- **Files:** `Core/Navigation/AppTab.swift, StackID.swift, Route.swift, Routes/*Route.swift, Sheet.swift, Cover.swift,
  Payloads.swift, Router.swift` · `Tests/CoreTests/RouterTests.swift, RouteCodingTests.swift`
- **Done when:** tests: `open` pushes on the selected tab's stack; with a cover up it pushes on the cover's stack; with a
  sheet up it pushes on the sheet stack, which disappears with the sheet (Report inside the Spot sheet); `setPath` shrinks a
  stack (back swipe); `dismissCover` clears that stack; `show(.hangout(id), in: .profile)` selects the tab, dismisses cover
  and sheet and leaves that single route; `reset` clears everything; `lastNonSearchTab` ignores `.search`; **every route case
  round-trips through JSON**. There is a route for every screen in `docs/IA.md` section 4. `./scripts/check.sh` is green.

### F-5 — Content repositories, stubs, stores, settings, AppDependencies  `[L]`
- **Depends on:** F-0, F-1, F-2, F-4
- **Read:** ARCHITECTURE 2.2, 2.3, 2.7 · DATA-MODEL 1, 7 · `docs/adr/001-concurrency.md`, `002-feature-owned-screens.md`, `004-data-contract.md`, `005-state-and-persistence.md`
- **Build in `Core/`** (Core is not main-actor by default: plain `public protocol X: Sendable`, no hand-written
  `nonisolated`, no `@MainActor` on protocols):
  - `Repositories/`: `HangoutRepository` (hangout(id:), hangouts(near:filters:), picks(), remixes(of:), stats(for:) →
    done and remix counts), `PlaceRepository` (place(id:), places(in:), spots(for:)), `LibraryRepository` (saved/drafts/
    runs: load, save, delete), `ProfileRepository`, `SearchRepository` (search(text:scope:) over Hangouts, Places,
    People), `PhotoStore` (`func url(for: Photo) -> URL?`).
  - `Fakes/` (`#if DEBUG`): `Stub*Repository` for each, with modes `loaded / empty / failing / neverReturns`
    (`StubMode`), using sample data from `Models/Samples`; `AppDependencies.preview(_ mode: StubMode)` (`@MainActor`);
    `Contracts/`: repository contract checks (`HangoutRepositoryContract.verify(_:)` and so on: plain throwing functions,
    no test framework) that LocalData (F-8) and later Remote call from their own tests.
  - `Stores/` (`@MainActor @Observable`, written explicitly): `SessionStore` (current user, `onboardingDone`, blocked IDs,
    an **onboarding draft** holding name/photo/interests/area until `completeOnboarding()`, `resetOnboarding()`,
    `isTeamAccount` for the hidden admin screens), `LibraryStore` (`isSaved`, `toggleSave`, drafts, finished runs).
  - `Services/AppSettings.swift` (Foundation `UserDefaults` wrapper: onboardingDone, selectedAreaID, interests),
    `Services/FeatureFlags.swift` (a `Sendable` struct of booleans such as `communityEnabled`, `chatEnabled`,
    `postingEnabled`, all true in DEBUG; an unfinished area can show its "Coming soon" state so `main` can always ship)
    and `Logging/Log.swift` (`os.Logger` helpers per feature).
  - **`AppDependencies`** (`Sendable` struct, ADR 002): the repositories as `any ...`, the stores, the `Router`,
    `FeatureFlags` and `now: @Sendable () -> Date`. F-7 adds the social repositories.
- **Files:** as above · `Tests/CoreTests/`
- **Done when:** a test drives `LibraryStore` with a stub; stubs compile in a `#Preview`; `AppDependencies.preview(.empty)`
  builds; the contract checks pass on the stubs; no `@AppStorage` anywhere; project builds with no concurrency warnings.

### F-6 — Hangout rules  `[S]`
- **Depends on:** F-0, F-2
- **Read:** PRODUCT 4 (Hangouts, Doing and posting) · DATA-MODEL 7 · RISKS 3
- **Build in `Core/Rules/HangoutRules.swift`** (all `public static func`, pure, no `Date()` inside: dates are parameters):
  `isValidSpotCount(_:)` (2…10), `hasDuplicatePlace(_:)` (for the "same place twice" warning),
  `remixKeepsEnough(original:remix:)` (≥70% of the original's Spots kept), `canPost(visitedCount:)`
  (≥2 visited), `maxPhotos(visitedCount:)` (2 × visited), `earliestPostTime(endedAt:delay:)`
  (default 30 minutes; options 2 h, next day), `roundedDuration(_:)` ("about 3 h").
- **Files:** `Core/Rules/HangoutRules.swift` · `Tests/CoreTests/HangoutRulesTests.swift`
- **Done when:** a test per rule including boundaries (1 and 2 Spots, 10 and 11, 69% and 70%).

### F-7 — Community, chat and safety repositories + sample social data  `[M]`
- **Depends on:** F-3, F-5
- **Read:** ARCHITECTURE 2.2, 2.7 · DATA-MODEL 3, 6 ("the hardest parts") · IA 4 (Community, Friends, Chat)
- **Shape the protocols so both backends can implement them:** cursor paging with `Page` (no offsets), listeners as
  `AsyncStream`, no cross-collection joins, blocking applied by the repository. Re-check them against the BK-1 result
  (`docs/tasks/70-backend-later.md`) before the social screens (SC-CM*, SC-FR1, SC-CH*) start.
- **Build in `Core/`:** protocols `FeedRepository` (feed, trending, post(id:), comments(for:), like,
  comment), `FriendsRepository` (friends, requests incl. "other", suggestions, send/accept/cancel),
  `ChatRepository` (conversations, messages as `AsyncStream`, send, edit, delete, markRead, polls),
  `SafetyRepository` (report, block, unblock), `AuthRepository` (sign in methods as stubs),
  `AdminRepository` (reports queue, place suggestions, ban); `Stores/BadgeStore`; matching
  `Fakes/Stub*Repository`, contract checks and entries in `AppDependencies` and its `.preview`; and in `Models/Samples/` believable **fake** social data (12 people with
  Kothrud-style names and no real persons, 8 posts incl. 2 Picks, comment threads, 3 chats incl. 1
  group, reports). Clearly mark everything sample.
- **Files:** `Core/Repositories/…`, `Core/Fakes/…`, `Core/Stores/BadgeStore.swift`, `Models/Samples/…`
- **Done when:** every stub supports loaded / empty / failing / neverReturns; chat stub can
  simulate an incoming message after 2 seconds; tests for `BadgeStore` counts.

### F-8 — LocalData: loader, sample content, persistence, content test  `[L]`
- **Depends on:** F-2, F-5
- **Read:** DATA-MODEL 1, 4 · ARCHITECTURE 3.2 (LocalData, Package details) · PRODUCT 8 · `docs/adr/004-data-contract.md`, `005-state-and-persistence.md`
- **Build in `LocalData/`:** `ContentLoader` (public; reads every `Places/*.json` and `Hangouts/*.json` from `Bundle.module`
  `Content/`, checks `schemaVersion`: older is accepted, a newer major version is rejected with a clear error),
  `LocalHangoutRepository`, `LocalPlaceRepository`, `LocalSearchRepository` (on-device search: title > tag > area scoring
  using `localizedStandardContains`), `LocalLibraryRepository` (+ `LibraryFile`: an `actor`, one serial writer for
  `library.json` in Application Support, atomic writes, coalesces to the latest snapshot, `schemaVersion`; a file that cannot
  be read is renamed `library.corrupt-<timestamp>.json`, logged without personal data, and the store starts empty),
  `LocalProfileRepository`, `LocalPhotoStore` (`Photo` → bundle URL). All JSON goes through `JSONCoding`. Put the **5 Places
  and 2 Hangouts** from task X-C1 in `Resources/Content/`.
- **Files:** `LocalData/*.swift`, `LocalData/Resources/Content/**` · `Tests/ContentTests/ContentTests.swift`, `Tests/LocalDataTests/`
- **Done when:** the **content test** loads every JSON file and checks: IDs unique, every Spot's place exists, 2…10 Spots,
  coordinates inside Pune (lat 18.3–18.7, lon 73.6–74.1), every photo file exists; **every Place and Hangout in
  `Models/Samples` equals its bundled JSON file** (samples never invent data); the F-5 contract checks pass on the Local
  repositories; ten quick successive saves leave one valid `library.json`; a corrupt file is quarantined and the app starts
  empty; the library round-trips to disk; search finds a Hangout by tag.

### F-9 — App shell: dependencies, tabs, thin screen factory  `[L]`
- **Depends on:** F-0, F-4, F-5, F-16, DS-1
- **Read:** ARCHITECTURE 1, 2.6, 2.7, 3.2 (App target) · IA 2 · `docs/adr/002-feature-owned-screens.md`, `003-navigation.md`
- **Build in `Vybe/App/`:** `AppDependencies+Local.swift` (`AppDependencies.local()`: the LocalData repositories, the stores,
  the `Router`, `FeatureFlags`), `RootView` (onboarding gate: `NavigationStack` on `StackID.onboarding` until
  `session.onboardingDone`, then `TabShell`; the live and editor covers via `.fullScreenCover(item:)`), `TabShell`
  (`TabView(selection:)` with `Tab` for Discover, Community, Profile and `Tab(role: .search)` last; one `NavigationStack`
  per tab whose path binding reads `router.paths` and writes through `router.setPath`; `.navigationDestination(for: Route.self)`
  on every stack root; the router's `Sheet` host active only while `router.cover == nil`, with its own `NavigationStack` for
  `StackID.sheet`; the second sheet host on each cover's root) and a **thin `ScreenFactory`**: `screen(for: Route)` has one
  `case` per feature route group and calls `<Name>Screens.view(for:_:)`; `sheet(for: Sheet)` and `cover(for: Cover)` call the
  owning feature's `Screens`. It never names a View or a ViewModel (ADR 002). Search lives inside `SearchView` (S1).
- **Files:** `Vybe/App/AppDependencies+Local.swift, RootView.swift, TabShell.swift, ScreenFactory.swift`
- **Done when:** the app runs on the simulator showing 4 tabs with Search separate at the right end; every route, sheet and
  cover shows the placeholder from F-16; a test resolves a `.hangout` route through `HangoutDetailScreens`; `router.show`
  switches tabs; **no tab selection can be hidden** (iOS 27 rule); `./scripts/check.sh` green.

### F-10 — Live run store (survives the app closing)  `[M]`
- **Depends on:** F-2, F-5
- **Read:** ARCHITECTURE 2.3, 4a #2 and #10 · MOTION 4 (moment 4) · RISKS 3 · `docs/adr/005-state-and-persistence.md`
- **Build in `Core/Stores/LiveHangoutStore.swift`:** `@MainActor @Observable` store holding the current `HangoutRun` +
  `RunTimes`; `startOrResume(hangoutID:)` (creates a run, or returns the live/minimised one), `markVisited(spotID:)`,
  `addPhoto`, `end()` (→ `done`), `discard()`; takes `now: @Sendable () -> Date`; memory updates immediately and the run is
  **persisted write-behind** through `LibraryRepository` (one serial writer, ADR 005), flushed when the app goes to the
  background; a write failure is logged and exposed as `persistenceError`; elapsed time is computed from `startedAt` (never a
  running timer); restores on launch.
- **Files:** `Core/Stores/LiveHangoutStore.swift` · `Tests/CoreTests/LiveHangoutStoreTests.swift`
- **Done when:** tests: start twice returns the same run; mark visited twice is idempotent; ten quick `markVisited` calls end in
  one consistent saved file; restart (new store, same file) restores; a failing write sets `persistenceError`; `end` yields
  `done`; time-of-visit lives only in `RunTimes`.

### F-11 — LocationService (real + simulated walk)  `[M]`
- **Depends on:** F-0, F-1
- **Read:** ARCHITECTURE 4a #1, #8, #9, #10 · RISKS 3
- **Build in `Core/Services/`:** `protocol LocationService: Sendable` (`authorization`, `updates() ->
  AsyncStream<LocationSample>`, `requestWhenInUse()`); `LiveLocationService` using
  `CLLocationUpdate.liveUpdates(.fitness)` and `CLServiceSession` (no delegate code; never request
  Always; holds a `CLBackgroundActivitySession` while a Hangout is live); `SimulatedLocationService`
  that replays a route (list of `Coordinate`) at walking speed for desk demos. Do not add the
  Background Modes capability or purpose strings: Lohitaksh does those (X-9).
- **Files:** `Core/Services/LocationService.swift, LiveLocationService.swift, SimulatedLocationService.swift`
- **Done when:** the simulated service emits samples at the expected pace (test with a fake clock);
  the live service compiles and is not used by tests; no `CLLocationManagerDelegate`.

### F-12 — (moved) ImageLoader is task DS-6  `[S]`
- **Depends on:** nothing
- **Note:** `Components` may import `Design` but not `Core`, so the image loader lives in `Design` (see
  `docs/tasks/10-design-system-and-components.md`, task DS-6). Nothing to build here: this entry only keeps
  the numbering stable. Take DS-6 instead.

### F-13 — PhotoProcessor (resize, strip location)  `[M]`
- **Depends on:** F-0, F-1
- **Read:** ARCHITECTURE 4 (Photos row) · RISKS 3 (photo location data)
- **Build in `Core/Services/PhotoProcessor.swift`:** takes picked image `Data`, returns two JPEGs
  (about 1600 px and 400 px on the long side) using `CGImageSourceCreateThumbnailAtIndex` and
  `CGImageDestinationAddImage` **with no metadata**, so GPS and other EXIF are removed; quality ≈ 0.8.
- **Files:** `Core/Services/PhotoProcessor.swift` · `Tests/CoreTests/PhotoProcessorTests.swift`
- **Done when:** a test image carrying a GPS EXIF tag comes out with **no** GPS/EXIF dictionary;
  sizes are as requested; output is under ~300 KB for the large size on the test image.

### F-14 — NetworkMonitor and offline state  `[S]`
- **Depends on:** F-5
- **Read:** ARCHITECTURE 2.5 · PRODUCT 4 (Offline) · DATA-MODEL 1
- **Build in `Core/Services/NetworkMonitor.swift`:** `@MainActor @Observable` wrapper over
  `NWPathMonitor` exposing `isOffline`; a way for tests to force it. (The UI banner is DS-2.)
- **Files:** `Core/Services/NetworkMonitor.swift` · tests
- **Done when:** forced offline/online toggles `isOffline`; stopping the monitor on deinit is safe.

### F-15 — Voice notes: AudioRecorder and player  `[M]`
- **Depends on:** F-0, F-1
- **Read:** ARCHITECTURE 4 (Voice notes) · PRODUCT 4 (Chat)
- **Build in `Core/Services/`:** `AudioRecorder` (`AVAudioRecorder`, AAC mono 32 kbps `.m4a`, hard stop
  at 2 minutes, metering for a waveform, microphone permission handled), `AudioPlayer` (play/pause/
  seek, progress). No UI here (that is SC-CH2). Do not add the microphone purpose string (Lohitaksh, X-9).
- **Files:** `Core/Services/AudioRecorder.swift, AudioPlayer.swift`
- **Done when:** recording stops at 2:00 in a test with a short limit injected; file size is about
  240 KB per minute; permission-denied is a clear error state.

### F-16 — Feature `Screens` scaffolds (all 13 features)  `[M]`
- **Depends on:** F-4, F-5
- **Read:** `docs/adr/002-feature-owned-screens.md`, `docs/adr/003-navigation.md` · ARCHITECTURE 3.2 · `docs/templates/new-screen/README.md`
- **Build:** in each of the 13 `*Feature` folders create `<Name>Screens.swift`: a `public enum <Name>Screens` with
  `@ViewBuilder public static func` entry points that cover **every route in that feature's route enum** (F-4; Discover has none), every
  `Sheet` and `Cover` the feature owns, and `root(_:)` for the four tab roots (Discover, Community, Profile, Search). Each
  returns a placeholder `Text("<screen ID>")` for now. Add one test per feature in `Tests/<Name>FeatureTests/` (with
  `@testable import`) that builds every entry point with `AppDependencies.preview(.loaded)`, so a missing case fails the build.
- **Files:** `VybeKit/Sources/<Name>Feature/<Name>Screens.swift` (13 files) · `Tests/<Name>FeatureTests/<Name>ScreensTests.swift` (13)
- **Done when:** the package builds in Swift 6 mode; each feature test builds its placeholders; the only `public` declaration in
  each feature is its `Screens` enum; `./scripts/check.sh` green. Afterwards a screen task only replaces its own placeholder
  `case` and never touches the App target.
