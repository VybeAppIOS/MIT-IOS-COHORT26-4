# Foundation tasks (do these first; they unblock everything)

Size: **S** ≈ half a day · **M** ≈ one day · **L** ≈ one and a half to two days.
"DoD" = the Definition of Done in `AGENTS.md` section 6. Before any task, read
`docs/START-HERE.md`. Code goes in `VybeKit/Sources/<Module>/` (folders already exist).
Everything is `public` with an explicit `public init`. Models and LocalData are not main-actor
isolated; Core protocols and `Rules` functions are written `nonisolated` (ARCHITECTURE 2.7).

Order: **F-0** and **F-1** first (small, unblock all). Then F-2, F-3, F-4, DS-1 can run in
parallel. Then F-5, F-6, F-7, F-8, F-9, F-10. After those, every other task in the pool is open.

### F-0 — Link VybeKit into the Xcode project  `[S]`  *(Lohitaksh only: project setting)*
- **Depends on:** nothing
- **Read:** ARCHITECTURE 3.2 ("Package details to verify"), BEFORE-BUILD 4 (spike 1)
- **Build:** In Xcode: File › Add Package Dependencies › Add Local › select `VybeKit`. Add the
  libraries `Models, Core, Design, Components, LocalData` and all 13 `*Feature` libraries to the
  `Vybe` app target. Put a temporary `#Preview` in `Design` that imports `Models` and open it in
  the canvas (the **60-minute preview spike**). If previews fail, try: build the package scheme once,
  accept any "trust macro" prompt. If they still fail, write the decision in OPEN-QUESTIONS.md and
  tell the group (fallback: same-named folders inside the app target).
- **Files:** `Vybe.xcodeproj` (via Xcode only)
- **Done when:** the app builds with `import Models` in `VybeApp.swift`; the spike result is
  recorded; the temporary preview is deleted; `./scripts/check.sh` is green.

### F-1 — IDs and shared value types  `[S]`
- **Depends on:** nothing
- **Note:** do this first; it blocks most of the other foundation tasks.
- **Read:** DATA-MODEL 2, 5 · ARCHITECTURE 2.1, 2.5
- **Build in `Models`:** `ID<Tag>` (the generic typed ID from DATA-MODEL 5: `Hashable`, `Codable` as a
  plain string, `Sendable`, `ExpressibleByStringLiteral`) and typealiases `PlaceID, HangoutID,
  SpotID, RunID, PhotoID, UserID, CommentID, ConversationID, MessageID, ReportID`; `Coordinate`;
  `RupeeRange { lower, upper }` with a `formattedPerPerson` that uses `.formatted(.currency(code: "INR"))`
  (en_IN grouping); `Photo`; `AppError` (`Error`, `Equatable`, `Sendable`, `init(_ error:)`, a
  friendly `message`); `LoadState<Content>` (`loading / loaded(_, isStale:) / empty / failed`) with
  `Equatable` conformance when `Content: Equatable`; `Page<T>` (items, `nextCursor: String?`).
- **Files:** `Models/Content/IDs.swift, Coordinate.swift, RupeeRange.swift, Photo.swift` ·
  `Models/State/LoadState.swift, Page.swift, AppError.swift` · tests in `Tests/ContentTests/`
- **Done when:** `swift`/Xcode builds; tests: an ID encodes/decodes as a plain JSON string; a
  `Place` ID cannot be passed where a `Hangout` ID is expected (compile-time, show in a comment);
  `RupeeRange` formats `₹150–400`.

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
  `Report` (+ `ReportReason`, `ReportTarget`), `Activity` (+ kinds), `GuestResponse`,
  `PlaceSuggestion` (+ status), `RemixCredit`.
- **Files:** `Models/Community/*.swift, Chat/*.swift, Safety/*.swift` · tests in `ContentTests/`
- **Done when:** every type round-trips JSON; `MessagePayload` decodes each kind; `Report` has all
  reasons listed in PRODUCT 4 (Safety defaults); `ReportTarget` is an IDs-only struct.

### F-4 — Navigation: Route, Sheet, Cover, Router  `[M]`
- **Depends on:** F-1
- **Read:** ARCHITECTURE 2.6 (the whole section; the code there compiles in Swift 5 and 6) · IA 5
- **Build in `Core/Navigation/`:** `AppTab` (discover, community, profile, search), `StackID`,
  `Route` (**all** cases listed in ARCHITECTURE 2.6), `Sheet`, `Cover` (each with `id`), `EditorStart`,
  `SettingsPage`, `AdminPage`, `SearchKind`, `ShareItem` (IDs-only payloads), and `Router`
  (`open, pop, popToRoot, present, dismissSheet, presentCover, dismissCover, show(_:in:), reset`,
  `lastNonSearchTab`).
- **Files:** `Core/Navigation/AppTab.swift, Route.swift, Sheet.swift, Cover.swift, Router.swift` ·
  `Tests/CoreTests/RouterTests.swift`
- **Done when:** tests: `open` pushes on the selected tab's stack; with a cover up it pushes on
  the cover's stack; `dismissCover` clears that stack; `show(.hangout(id), in: .profile)` selects the
  tab, dismisses cover and sheet and leaves that single route; `reset` clears everything;
  `lastNonSearchTab` ignores `.search`.

### F-5 — Content repositories, stubs, stores, settings  `[L]`
- **Depends on:** F-1, F-2
- **Read:** ARCHITECTURE 2.2, 2.3, 2.7 · DATA-MODEL 1, 7
- **Build in `Core/`:**
  - `Repositories/` (all `nonisolated`, `Sendable`): `HangoutRepository` (hangout(id:),
    hangouts(near:filters:), picks(), remixes(of:), stats(for:) → done and remix counts), `PlaceRepository` (place(id:), places(in:), spots(for:)),
    `LibraryRepository` (saved/drafts/runs: load, save, delete), `ProfileRepository`, `SearchRepository`
    (search(text:scope:) over Hangouts, Places, People), `PhotoStore` (`func url(for: Photo) -> URL?`).
  - `Fakes/` (`#if DEBUG`, `nonisolated`): `Stub*Repository` for each, with modes
    `loaded / empty / failing / neverReturns`, using sample data from `Models/Samples`.
  - `Stores/`: `SessionStore` (current user, `onboardingDone`, blocked IDs, an **onboarding draft** holding name/photo/interests/area until `completeOnboarding()`, `resetOnboarding()`, `isTeamAccount` for the hidden admin screens),
    `LibraryStore` (`isSaved`, `toggleSave`, drafts, finished runs). `@MainActor @Observable`.
  - `Services/AppSettings.swift` (Foundation `UserDefaults` wrapper: onboardingDone, selectedAreaID,
    interests) and `Logging/Log.swift` (`os.Logger` helpers per feature).
- **Files:** as above · `Tests/CoreTests/`
- **Done when:** a test drives `LibraryStore` with a stub; stubs compile in a `#Preview`; no
  `@AppStorage` anywhere; `nonisolated` rules respected (project builds).

### F-6 — Hangout rules  `[S]`
- **Depends on:** F-2
- **Read:** PRODUCT 4 (Hangouts, Doing and posting) · DATA-MODEL 7 · RISKS 3
- **Build in `Core/Rules/HangoutRules.swift`** (all `public nonisolated static func`, pure):
  `isValidSpotCount(_:)` (2…10), `hasDuplicatePlace(_:)` (for the "same place twice" warning),
  `remixKeepsEnough(original:remix:)` (≥70% of the original's Spots kept), `canPost(visitedCount:)`
  (≥2 visited), `maxPhotos(visitedCount:)` (2 × visited), `earliestPostTime(endedAt:delay:)`
  (default 30 minutes; options 2 h, next day), `roundedDuration(_:)` ("about 3 h").
- **Files:** `Core/Rules/HangoutRules.swift` · `Tests/CoreTests/HangoutRulesTests.swift`
- **Done when:** a test per rule including boundaries (1 and 2 Spots, 10 and 11, 69% and 70%).

### F-7 — Community, chat and safety repositories + sample social data  `[M]`
- **Depends on:** F-3, F-5
- **Read:** ARCHITECTURE 2.2, 2.7 · DATA-MODEL 3 · IA 4 (Community, Friends, Chat)
- **Build in `Core/`:** protocols `FeedRepository` (feed, trending, post(id:), comments(for:), like,
  comment), `FriendsRepository` (friends, requests incl. "other", suggestions, send/accept/cancel),
  `ChatRepository` (conversations, messages as `AsyncStream`, send, edit, delete, markRead, polls),
  `SafetyRepository` (report, block, unblock), `AuthRepository` (sign in methods as stubs),
  `AdminRepository` (reports queue, place suggestions, ban); `Stores/BadgeStore`; matching
  `Fakes/Stub*Repository`; and in `Models/Samples/` believable **fake** social data (12 people with
  Kothrud-style names and no real persons, 8 posts incl. 2 Picks, comment threads, 3 chats incl. 1
  group, reports). Clearly mark everything sample.
- **Files:** `Core/Repositories/…`, `Core/Fakes/…`, `Core/Stores/BadgeStore.swift`, `Models/Samples/…`
- **Done when:** every stub supports loaded / empty / failing / neverReturns; chat stub can
  simulate an incoming message after 2 seconds; tests for `BadgeStore` counts.

### F-8 — LocalData: loader, sample content, content test  `[L]`
- **Depends on:** F-2, F-5
- **Read:** DATA-MODEL 1, 4 · ARCHITECTURE 3.2 (LocalData, "Package details to verify") · PRODUCT 8
- **Build in `LocalData/`:** `ContentLoader` (public; reads every `Places/*.json` and `Hangouts/*.json`
  from `Bundle.module` `Content/`, checks `schemaVersion`), `LocalHangoutRepository`,
  `LocalPlaceRepository`, `LocalSearchRepository` (on-device search: title > tag > area scoring using
  `localizedStandardContains`), `LocalLibraryRepository` (+ `LibraryFile`: `library.json` in Application
  Support, atomic writes, `schemaVersion`), `LocalProfileRepository`, `LocalPhotoStore` (`Photo` →
  bundle URL). Put the **5 Places and 2 Hangouts** from task X-C1 in `Resources/Content/`.
- **Files:** `LocalData/*.swift`, `LocalData/Resources/Content/**` · `Tests/ContentTests/ContentTests.swift`
- **Done when:** the **content test** loads every JSON file and checks: IDs unique, every Spot's place
  exists, 2…10 Spots, coordinates inside Pune (lat 18.3–18.7, lon 73.6–74.1), every photo file exists;
  library round-trips to disk; search finds a Hangout by tag.

### F-9 — App shell: dependencies, tabs, screen factory  `[L]`
- **Depends on:** F-0, F-4, F-5, DS-1
- **Read:** ARCHITECTURE 1, 2.6, 2.7, 3.2 (App target) · IA 2
- **Build in `Vybe/App/`:** `AppDependencies` (creates local repositories, stores, `Router`),
  `RootView` (onboarding gate: `NavigationStack(path:)` on `StackID.onboarding` until
  `session.onboardingDone`, then `TabShell`; the live and editor covers via `.fullScreenCover(item:)`),
  `TabShell` (`TabView(selection: $router.selectedTab)` with `Tab` for Discover, Community, Profile and
  `Tab(role: .search)` last; one `NavigationStack` per tab bound to `router.paths[.tab(...)]` with
  `.navigationDestination(for: Route.self)`; the router's `Sheet` host active only while
  `router.cover == nil`; the second sheet host on each cover's root), `ScreenFactory`
  (`screen(for: Route)`, `sheet(for: Sheet)`, `cover(for: Cover)`): **a stub `Text("<ID>")` for every
  route**, so each screen task only replaces its own case. Search lives inside `SearchView` (S1).
- **Files:** `Vybe/App/AppDependencies.swift, RootView.swift, TabShell.swift, ScreenFactory.swift`
- **Done when:** the app runs on the simulator showing 4 tabs with Search separate at the right end;
  every route/sheet/cover shows its placeholder; `router.show` switches tabs; **no tab selection can be
  hidden** (iOS 27 rule); `./scripts/check.sh` green.

### F-10 — Live run store (survives the app closing)  `[M]`
- **Depends on:** F-2, F-5
- **Read:** ARCHITECTURE 2.3, 4a #2 and #10 · MOTION 4 (moment 4) · RISKS 3
- **Build in `Core/Stores/LiveHangoutStore.swift`:** `@MainActor @Observable` store holding the current
  `HangoutRun` + `RunTimes`; `startOrResume(hangoutID:)` (creates a run, or returns the live/minimised
  one), `markVisited(spotID:)`, `addPhoto`, `end()` (→ `done`), `discard()`; writes to disk on every
  change through `LibraryRepository`; elapsed time computed from `startedAt` (never a running timer);
  restores on launch.
- **Files:** `Core/Stores/LiveHangoutStore.swift` · `Tests/CoreTests/LiveHangoutStoreTests.swift`
- **Done when:** tests: start twice returns the same run; mark visited twice is idempotent; restart
  (new store, same file) restores; `end` yields `done`; time-of-visit lives only in `RunTimes`.

### F-11 — LocationService (real + simulated walk)  `[M]`
- **Depends on:** F-1
- **Read:** ARCHITECTURE 4a #1, #8, #9, #10 · RISKS 3
- **Build in `Core/Services/`:** `nonisolated protocol LocationService` (`authorization`, `updates() ->
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
- **Depends on:** F-1
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
- **Depends on:** F-1
- **Read:** ARCHITECTURE 4 (Voice notes) · PRODUCT 4 (Chat)
- **Build in `Core/Services/`:** `AudioRecorder` (`AVAudioRecorder`, AAC mono 32 kbps `.m4a`, hard stop
  at 2 minutes, metering for a waveform, microphone permission handled), `AudioPlayer` (play/pause/
  seek, progress). No UI here (that is SC-CH2). Do not add the microphone purpose string (Lohitaksh, X-9).
- **Files:** `Core/Services/AudioRecorder.swift, AudioPlayer.swift`
- **Done when:** recording stops at 2:00 in a test with a short limit injected; file size is about
  240 KB per minute; permission-denied is a clear error state.
