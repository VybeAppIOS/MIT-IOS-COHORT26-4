# Vybe: Technical Architecture

Status: working architecture (3 Nov 2026, replanned 4 Nov). **`docs/adr/` (001 to 007) win where they differ.** Code sketches
are illustrations; what F-0 proved, and what is still unproven, is recorded at the bottom of ADRs 001 to 004. Evidence: the code of
open-source SwiftUI apps (Ice Cubes, IcySky, Element X, Damus, Apple's Backyard Birds, Food Truck and Landmarks, isowords),
Apple's documentation, WWDC and HIG, and expert articles (links at the end). "Checked" = read in the source; "unverified" = not yet.

---

## 0. Our environment (checked on the lead's Mac)

| | Value |
|---|---|
| Xcode | 27.1 (Swift 6.4), iOS 27 simulators; Xcode 27 debugs devices on iOS 17+ |
| App | **iOS 26.0 minimum** (decided 3 Nov), iPhone, portrait, light; Swift 6 mode, default main actor (ADR 001) |
| Project | Xcode synchronized folders: new files don't edit the project file |
| Simulators | iOS 27.0 and 27.1 installed; also install an **iOS 26 runtime** (Xcode › Settings › Components) and run `check.sh` on it weekly |
| Liquid Glass | we build with the iOS 27 SDK, so `UIDesignRequiresCompatibility` is ignored: iOS 26+ phones always get Liquid Glass (Apple docs, checked) |

We **build** with the newest SDK but may only **use** iOS 26 APIs. One design, no old-iOS branches: Liquid Glass, the search-role
tab, `glassEffect`, `tabViewBottomAccessory`, `Observations` and the iOS 26 MapKit address APIs need no `#available`; iOS 27-only
APIs need `if #available(iOS 27, *)` or are avoided. Cost (team decision): iPhone XS, XS Max and XR cannot run iOS 26
(iOS 26 ran on 79% of iPhones in June 2026, Apple).

## 1. The big picture

```
┌─────────────────────────────────────────────────────────────┐
│ App target (Vybe/)                                          │
│ VybeApp · tab bar · thin ScreenFactory · builds the stores  │
│ · deep links · (Phase 2) backend setup                      │
└───────────────┬─────────────────────────────────────────────┘
                │ uses everything below
┌───────────────▼─────────────────────────────────────────────┐
│ Feature modules: one per area, never import each other      │
│ All 13 are in scope now (AGENTS.md 9): Discover ·           │
│ HangoutDetail · Live · Onboarding · Search · Profile ·      │
│ Community · Editor · Posting · Friends · Chat · Auth ·      │
│ Moderation. Each = Views + ViewModels (MVVM) and ONE        │
│ public type, its Screens (ADR 002)                          │
└──────┬──────────────────────┬─────────────────────┬─────────┘
       │                      │                     │
┌──────▼───────┐   ┌──────────▼──────────┐   ┌──────▼─────────┐
│ Components   │   │ Core                │   │ Design         │
│ HangoutCard, │   │ Route enums, Router,│   │ Theme tokens,  │
│ SpotRow, ... │   │ stores, repository  │   │ buttons, chips,│
│ (uses Models │   │ protocols, fakes,   │   │ LoadStateView  │
│  + Design)   │   │ rules, services     │   │ (uses Models)  │
└──────┬───────┘   └──────────┬──────────┘   └──────┬─────────┘
       └──────────────┬───────┴─────────────────────┘
               ┌──────▼──────┐
               │ Models      │  plain Sendable structs, typed IDs, LoadState,
               └─────────────┘  Page, AppError, sample data for previews
  Data sources (implement Core's repository protocols):
  LocalData (Phase 1: JSON in the app + saved items on the phone)
  VybeRemote (Phase 2: its own package, the only place allowed to import Firebase/Supabase; ADR 007)
```

Arrows point down only. A feature may use Core, Components, Design and Models, never another feature. Only the App target sees
everything. Same shape as **Ice Cubes** (13 packages, `@Observable`, a router per tab, Route → screen map in the app target) and
**IcySky**.

## 2. Building blocks (what every teammate must understand)

### 2.1 Models
Plain data: no logic, no SwiftUI, `Sendable`. Typed IDs stop a Place ID being used as a Hangout ID; in JSON they are plain strings.
Models is its own module, so every type and `init` used elsewhere is `public`, and we write the `public init` ourselves (Swift
never makes the memberwise `init` public).

```swift
public struct Hangout: Codable, Hashable, Sendable, Identifiable {   // SHORT EXAMPLE of the pattern; real fields: DATA-MODEL 5
    public let id: HangoutID
    public var title: String
    public var spots: [Spot]          // ordered, 2 to 10
    public var authorID: UserID
    public var isPick: Bool
    public init(id: HangoutID, title: String, spots: [Spot], authorID: UserID, isPick: Bool) { /* assign each */ }
}
```
Preview sample data sits next to the models (`Hangout.samples`), as in Ice Cubes, Backyard Birds and Landmarks.

### 2.2 Repositories: where data comes from
A repository is a promise such as "I can give you Hangouts": one per **data area** (Hangouts, Places, Library for saved and
drafts; later Feed, Friends, Chat, Users, Moderation), not one per screen.

```swift
public protocol HangoutRepository: Sendable {
    func hangout(id: HangoutID) async throws -> Hangout
    func hangouts(near area: Area, filters: Filters) async throws -> [Hangout]
}
```
Phase 1: `LocalHangoutRepository` reads JSON bundled in the app. Phase 2: `RemoteHangoutRepository` talks to the backend. Switching is
one line in the App target; screens never change; one shared contract-test suite runs against both. (Ice Cubes skips repositories
and calls its network client; we keep them because the backend is undecided. Confidence: medium-high.)

### 2.3 Stores: state many screens share
`@Observable` classes created once in `AppDependencies` and handed to ViewModels through `init` (**nothing is read from the SwiftUI
Environment**). A store exists **only if more than one tab needs the data.**

| Store | Holds |
|---|---|
| `SessionStore` | current user, onboarding done, blocked user IDs |
| `LibraryStore` | Saved, Drafts and finished runs not yet posted (on the phone in Phase 1) |
| `LiveHangoutStore` | the Hangout running now: creates or resumes the `HangoutRun`, survives tab switches, saves to disk on every change |
| `BadgeStore` (Phase 2) | unread chat, Activity and friend-request counts (Community badge, bell) |

Feed, search results and chat messages are **not** stores: they belong to their screen's ViewModel. **Small settings**
(onboarding done, chosen area, interests) live in `Core/Services/AppSettings`, a thin `UserDefaults` wrapper (Foundation only).
`@AppStorage` is SwiftUI-only: not allowed in Core or ViewModels (inside an `@Observable` class it fails to compile, verified).
Personal data (name, photo) never goes in `UserDefaults`.

### 2.4 MVVM: View, ViewModel, Model (team decision)
Every screen has exactly two files, `SomethingView` and `SomethingViewModel`:

| Layer | What it is | Rules |
|---|---|---|
| **Model** | the data structs (2.1), repositories (2.2) and stores (2.3) | no SwiftUI |
| **ViewModel** | a `@MainActor @Observable final class`, one per screen | holds the screen's state as a `LoadState`; loads through repositories; one method per user action; prepares display text; asks the router to navigate; **does not import SwiftUI** |
| **View** | a SwiftUI `struct` | lays out ViewModel properties; forwards taps to ViewModel methods; no loading, no logic |

Every screen gets a ViewModel, even simple ones, so four people and their AI tools produce one shape. Shared components
(HangoutCard, SpotRow) have no ViewModel; they take plain values. Evidence: Ice Cubes' README and Element X (a production chat app)
use a ViewModel per screen. Some experts (Ricouard, SwiftLee) call view models optional with `@Observable`; we chose MVVM for
consistency and testability, which suits beginners and AI agents.

```swift
// A ViewModel exposes VIEW-READY values, never raw models. Everything in a feature is internal; only <Name>Screens is public (ADR 002).
struct HangoutDetailContent: Equatable, Sendable {
    let title: String
    let budgetText: String        // "₹150–400 per person" built with .formatted
    let spots: [SpotRowData]      // plain values for the SpotRow component
}

@MainActor @Observable
final class HangoutDetailViewModel {
    private(set) var state: LoadState<HangoutDetailContent> = .loading
    private let id: HangoutID
    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let library: LibraryStore
    private let liveStore: LiveHangoutStore
    private let router: Router
    private var hasLoaded = false

    init(id: HangoutID, hangouts: any HangoutRepository, places: any PlaceRepository,
         library: LibraryStore, liveStore: LiveHangoutStore, router: Router) {
        self.id = id; self.hangouts = hangouts; self.places = places
        self.library = library; self.liveStore = liveStore; self.router = router   // cheap: no loading here
    }

    var isSaved: Bool { library.isSaved(id) }

    func load() async {
        guard !hasLoaded else { return }          // .task runs again whenever the screen reappears
        await fetch()
    }
    func reload() async { await fetch() }         // pull to refresh and the Retry button

    private func fetch() async {
        do {
            let hangout = try await hangouts.hangout(id: id)
            let spots = try await places.spots(for: hangout)
            state = .loaded(HangoutDetailContent(title: hangout.title,
                                                 budgetText: hangout.budgetPerPerson.formattedPerPerson,
                                                 spots: spots))
            hasLoaded = true
        } catch is CancellationError {
            return                                // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))          // only a first load can fail
            }
        }
    }
    func startTapped() {
        liveStore.startOrResume(hangoutID: id)    // creates the HangoutRun (or resumes the live one)
        router.presentCover(.live(id))
    }
    func saveTapped() { library.toggleSave(id) }
}

struct HangoutDetailView: View {
    @State private var viewModel: HangoutDetailViewModel
    init(viewModel: HangoutDetailViewModel) { _viewModel = State(initialValue: viewModel) }
    var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.reload() } }) { content in
            PrimaryButton("Start Hangout") { viewModel.startTapped() }      // layout only
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }
}
```
Rules that avoid known pitfalls:
- **`init`s are cheap.** SwiftUI may create the View struct many times; `@State` keeps only the first ViewModel, but every `init`
  still runs (Apple docs, Nil Coalescing). Load in `.task`, never in `init`.
- **`load()` is idempotent** (`guard !hasLoaded`): `.task` runs again whenever a screen reappears, for example after popping back.
- **Dependencies come through `init`**, never the Environment (an `@Observable` class cannot read `@Environment`).
- **Text:** fixed labels ("Start Hangout") are literals in the View and live in the String Catalog; computed or data-dependent
  text (budgets, counts, distances) is built in the ViewModel with `String(localized:)` and `.formatted(...)`.
- **ViewModels never write `router.cover = …`**; they call the Router's methods (2.6).
- **Testing:** ViewModels don't import SwiftUI, so each is tested directly with the stubs in `Core/Fakes` (2.7): call `load()` or
  `startTapped()`, check `state`, the router and the stores.
- **Xcode 27 `@State`** is now a macro that creates its value once per view lifetime (back-deploys to iOS 17; iOS 27 release notes,
  checked). Our ViewModels are still built by the parent on every redraw, so keep `init`s cheap, and never give a `@State` both a
  default value and an assignment in `init` (no longer compiles). Check at the first real screen that
  `_viewModel = State(initialValue:)` compiles.
- **Swift 6.4** warns when an error thrown inside a `Task` is ignored: handle it, never silence the warning.
- **Showing a photo:** `Components` can't read files. A ViewModel turns a `Photo` into a `URL` with Core's `PhotoStore` protocol
  (`LocalData` implements it with `Bundle.module`; `Remote` returns storage URLs) and passes the `URL?` to `PlaceImage(url:)`.

### 2.5 LoadState: one standard for loading, empty, error, offline
`LoadState`, `Page` and `AppError` live in **Models** (no UI), so `Design`'s `LoadStateView` can use them.
```swift
public enum LoadState<Content> {
    case loading
    case loaded(Content, isStale: Bool = false)   // isStale: cached or offline
    case empty
    case failed(AppError)
}
extension LoadState: Equatable where Content: Equatable {}   // so tests can write #expect(vm.state == .empty)
```
`Content` is a **view-ready struct** (title, price text, `[SpotRowData]`), never a raw model. One shared
`LoadStateView(state, onRetry:)` draws all four the same way: a placeholder skeleton (`.redacted(reason: .placeholder)`),
`ContentUnavailableView` for empty, a retry button for errors, the offline banner when stale (as in Ice Cubes). Lists that load
more use `Page<T>` with a cursor and a "loading more" flag. `LoadState` describes the **first** load: once content is on screen a
failed refresh keeps it and sets `isStale`; cancellation never changes the state; "not found" is its own `AppError`
(`docs/adr/005-state-and-persistence.md`).

### 2.6 Navigation: Router and Routes
```swift
public enum AppTab: Hashable, Codable, Sendable { case discover, community, profile, search }   // Search: separate, trailing

/// One NavigationStack per tab, one for onboarding, one inside each full-screen cover, one inside the sheet that is up.
public enum StackID: Hashable, Codable, Sendable { case onboarding, tab(AppTab), live, editor, sheet }

/// One case per feature, each carrying that feature's own route enum. F-4 declares ALL of them (every screen in docs/IA.md,
/// all phases). Pushes carry IDs only.
public enum Route: Hashable, Codable, Sendable {
    case onboarding(OnboardingRoute), auth(AuthRoute), hangoutDetail(HangoutDetailRoute),
         live(LiveRoute), posting(PostingRoute), search(SearchRoute), profile(ProfileRoute),
         community(CommunityRoute), friends(FriendsRoute), chat(ChatRoute),
         moderation(ModerationRoute), editor(EditorRoute)       // Discover has no pushed routes of its own
}

// Core/Navigation/Routes/HangoutDetailRoute.swift: a feature's cases + the short constructors the docs use
public enum HangoutDetailRoute: Hashable, Codable, Sendable {
    case detail(HangoutID)                      // HD1
    case remixTree(HangoutID)                   // HD3
}
public extension Route {
    static func hangout(_ id: HangoutID) -> Route { .hangoutDetail(.detail(id)) }
    static func remixTree(_ id: HangoutID) -> Route { .hangoutDetail(.remixTree(id)) }
}
// Same pattern elsewhere, e.g. OnboardingRoute: nameAndPhoto, interests, location, findFriends (O2 to O5) ·
// ProfileRoute: saved, drafts, readyToPost, settings, settingsPage(SettingsPage), deleteAccount ·
// ChatRoute: list, conversation(ConversationID), groupInfo(ConversationID) (CH1, CH2, CH4) · LiveRoute: summary(RunID) (H3)

/// Sheets that more than one feature can ask for. Shown by exactly one host at a time (see Rules).
public enum Sheet: Hashable, Codable, Sendable, Identifiable {
    case spot(PlaceID)                          // HD2: from Search, Hangout detail AND the live screen
    case report(ReportTarget)                   // R1
    case share(ShareItem)                       // CH5
    case suggestPlace                           // E3: from Search (empty) and the editor
    case editPost(RunID)                        // PO2: from the post detail
    case groupInvitation(ConversationID)        // CH7
    public var id: String {
        switch self {
        case .spot(let p): "spot-\(p.rawValue)"
        case .report: "report"
        case .share: "share"
        case .suggestPlace: "suggestPlace"
        case .editPost(let r): "editPost-\(r.rawValue)"
        case .groupInvitation(let c): "invite-\(c.rawValue)"
        }
    }
}

public enum Cover: Hashable, Codable, Sendable, Identifiable {   // full-screen
    case live(HangoutID)                        // H1 → H3 → PO1, on the `.live` stack
    case editor(EditorStart)                    // E1: .new, .draft(id) or .remix(id)
    public var id: String {
        switch self { case .live(let h): "live-\(h.rawValue)"; case .editor: "editor" }
    }
}

@MainActor @Observable public final class Router {
    public var selectedTab: AppTab = .discover { didSet { if selectedTab != .search { lastNonSearchTab = selectedTab } } }
    public private(set) var paths: [StackID: [Route]] = [:]   // tabs, onboarding, each cover and the sheet
    public private(set) var cover: Cover?
    public private(set) var sheet: Sheet?
    public private(set) var lastNonSearchTab: AppTab = .discover   // ranks Search results (read at query time)

    /// Push onto the stack on screen (the sheet's if one is up, else the cover's, else the selected tab's).
    public func open(_ route: Route) { paths[currentStack, default: []].append(route) }
    public func pop() { _ = paths[currentStack]?.popLast() }
    public func popToRoot() { paths[currentStack] = [] }
    /// The system popped a screen (back swipe): the host writes the new path back (a private(set) alone would not allow this).
    public func setPath(_ path: [Route], for stack: StackID) { paths[stack] = path }
    public func present(_ sheet: Sheet) { self.sheet = sheet; paths[.sheet] = [] }
    public func dismissSheet() { sheet = nil; paths[.sheet] = nil }
    public func presentCover(_ cover: Cover) { self.cover = cover }
    public func dismissCover() { if let c = cover { paths[stack(for: c)] = [] }; cover = nil; dismissSheet() }
    /// Leave whatever is up and show a screen in a tab (post made → Community, editor Done → Drafts).
    public func show(_ route: Route?, in tab: AppTab) {
        dismissCover(); selectedTab = tab; paths[.tab(tab)] = route.map { [$0] } ?? []
    }
    /// Sign out, account deletion, "reset onboarding": clear every stack, sheet and cover.
    public func reset() { paths = [:]; cover = nil; sheet = nil; selectedTab = .discover }

    private var currentStack: StackID { sheet != nil ? .sheet : (cover.map(stack(for:)) ?? .tab(selectedTab)) }
    private func stack(for cover: Cover) -> StackID { switch cover { case .live: .live; case .editor: .editor } }
}
```
(An earlier version was typechecked with `swiftc`; the grouped routes, the sheet stack and `setPath` are **unverified** until F-4
compiles them. The `Identifiable` `id`s are needed because an enum with payloads gets none automatically.)

**Rules**
- **F-4 declares every route for every screen in `docs/IA.md`, all phases.** Each feature's `Screens` shows a placeholder with the
  screen ID until its task replaces that one `case`, so adding a screen never touches the App or the router. `ReportTarget`,
  `ShareItem` and similar payloads are small IDs-only types.
- **Which presentation do I use?**

  | Situation | Use |
  |---|---|
  | only one feature shows it (Filters, Mark visited, Comments) | a flag in that screen's ViewModel + `.sheet` |
  | two or more features can open it (Spot, Report, Share, Suggest a Place) | a `Sheet` case through the router |
  | a sheet is already up and you need Report | push `Route.report` inside that sheet's own `NavigationStack` |
  | a long multi-step task (live Hangout, editor) | a `Cover` with its own stack |

- **Who shows the router's sheet.** A view under a full-screen cover cannot present a sheet, so `.sheet(item:)` is attached in
  **two** places: on `TabShell` (active only while `router.cover == nil`) and on the root of each cover's content (active only
  while a cover is up). Only the Spot sheet (HD2) and the local Mark-visited sheet (H2) are allowed inside the live cover. The
  sheet has its own `NavigationStack` bound to `StackID.sheet`, which is how Report is pushed inside the Spot sheet.
- **Onboarding** has its own stack: `RootView` shows `NavigationStack(path: …paths[.onboarding])` until `session.onboardingDone`,
  then `TabShell`. Finishing calls `session.completeOnboarding()` and `router.reset()`.
- **Each stack needs its own** `.navigationDestination(for: Route.self)` on its root view (every tab, onboarding, `.live`,
  `.editor` and the sheet), never inside a `List` or `LazyVStack`. Each path `Binding` reads `router.paths` and writes through
  `router.setPath(_:for:)`, so the system back swipe works.
- **Starting a Hangout:** `startTapped()` calls `liveStore.startOrResume(...)`, then `router.presentCover(.live(id))`. If a run is
  already live or minimised, Start asks to resume it instead of creating a second one.
- **Leaving a flow in another tab** uses `router.show(_, in:)`: post made → Community; editor Done → Profile › Drafts; Phase 1
  summary → Discover root.
- **Adding a screen:** 1) its route case already exists (F-4); if the screen is genuinely new, its owner adds the case and the
  short constructor in that feature's one file in `Core/Navigation/Routes/` (the lead reviews it); 2) replace the screen's
  placeholder `case` in `<Name>Screens.swift`; 3) write the View, ViewModel and Preview in your feature; 4) write the ViewModel
  test; 5) give the screen a row in `docs/IA.md`.

Decisions and why:
- **One `NavigationStack` per tab** with a typed `[Route]` array, not `NavigationPath` (which hides its contents). Same as IcySky;
  Damus reworked to this in Aug 2026 after a single shared path broke. (Confidence: high.)
- **Routes carry IDs only.** Each detail screen loads by ID and handles "not found" (Apple's Backyard Birds). Damus shows the
  alternative going wrong: routes holding live objects and bindings. (Confidence: high.)
- **Only the App target maps a route group to a feature.** Its thin `ScreenFactory` calls `<Name>Screens`, which is how Discover
  opens a Hangout without importing HangoutDetail (Ice Cubes, IcySky, adapted: ADR 002).
- **Routes are `Codable`** so they can be restored, deep-linked and opened by the debug launch options (ADR 003, 006).
- **Deep links** (`vybe://hangout/<id>`) arrive in **Phase 2** (a URL scheme is a project setting; Phase 1 shares plain text).
  When a link arrives:

  | App state | What happens |
  |---|---|
  | onboarding not finished | queue the link until onboarding is done |
  | live cover up | banner "End your Hangout first"; ignore the link |
  | editor cover up | ask to discard the draft first |
  | a sheet is up | dismiss it, then continue |
  | otherwise | `router.show(.hangout(id), in: router.selectedTab)` |

  Every ID in a link is validated. Universal links (Apple's recommendation) need a website, an entitlement and the paid Apple account.
- **`Router.selectedTab` must always be a visible tab.** With the iOS 27 SDK a `TabView` may crash if its selection is hidden or
  unavailable (iOS 27 release notes, checked). `TabView(selection:)` uses `Tab(..., value: AppTab.x)`; `TabShell` reads
  `lastNonSearchTab` for Search ranking.
- Never call `canOpenURL` (deprecated in iOS 27): call `openURL` and handle failure.

### 2.7 Dependency injection, fakes and previews
Dependencies flow through `init`s, which makes them explicit and testable (ADR 002).
- **`AppDependencies`** is a `Sendable` struct in `Core` holding the repositories (`hangouts`, `places`, `library`, `search`,
  `profile`, `photos`, ...), the stores, the `Router`, `FeatureFlags` and the clock. The App target builds the real one once
  (`AppDependencies.local()`: local data in Phase 1, remote in Phase 2); `Core/Fakes` builds the preview one
  (`AppDependencies.preview(.loaded)`).
- **Each feature owns its wiring.** Its one `public` type, `<Name>Screens`, builds that feature's Views and ViewModels from
  `AppDependencies`. A ViewModel's `init` takes only what it needs. Views never fetch dependencies themselves.
- The App's `ScreenFactory` is thin: it maps a route group, a `Sheet` or a `Cover` to the owning feature's `Screens` function and
  never names a View or ViewModel.
- **F-16 creates a placeholder (`Text("HD1")`) for every route** in every `Screens`; a screen's author replaces only their own
  `case`, in their own feature.

```swift
// HangoutDetailFeature/HangoutDetailScreens.swift: the only public thing in the feature (UNVERIFIED sketch)
public enum HangoutDetailScreens {
    @ViewBuilder
    public static func view(for route: HangoutDetailRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .detail(let id):
            HangoutDetailView(viewModel: HangoutDetailViewModel(
                id: id, hangouts: deps.hangouts, places: deps.places, library: deps.library,
                liveStore: deps.liveStore, router: deps.router))
        case .remixTree: Text("HD3")                       // replaced by task SC-HD3
        }
    }
    @ViewBuilder
    public static func spotSheet(_ id: PlaceID, _ deps: AppDependencies) -> some View {
        SpotSheetView(viewModel: SpotSheetViewModel(id: id, places: deps.places, router: deps.router))
    }
}

// App target: thin
@ViewBuilder func screen(for route: Route) -> some View {
    switch route {
    case .hangoutDetail(let r): HangoutDetailScreens.view(for: r, deps)
    case .profile(let r):       ProfileScreens.view(for: r, deps)
    // ...one case per feature
    }
}
@ViewBuilder func sheet(for sheet: Sheet) -> some View {
    switch sheet {
    case .spot(let id): HangoutDetailScreens.spotSheet(id, deps)
    // ...
    }
}
```
- **Isolation** (`docs/adr/001-concurrency.md`, verified in F-0): `Models`, `Core` and `LocalData` are **not** main-actor by default
  and do not enable `NonisolatedNonsendingByDefault`, so repository protocols, `Rules/` and services are plain `Sendable` types and
  a plain `async` repository method runs off the main thread. Only `Router`, the stores, `NetworkMonitor` and
  `AppDependencies.preview` are `@MainActor`, written explicitly. Design, Components and the Features default to the main actor.
  Nobody hand-writes `nonisolated`.
- **Fakes and previews:** `Core/Fakes/` holds the stubs (`StubHangoutRepository(result:)` with loaded, empty, failing and
  never-returning modes) and `AppDependencies.preview(_:)`. Each screen's `+Preview.swift` (in `#if DEBUG`) builds the **real**
  ViewModel from `AppDependencies.preview(mode)`: `HangoutDetailViewModel.preview(.loaded)`, `.preview(.empty)`, `.preview(.failing)`.
  Previews and ViewModel tests share the same stubs, and the contract checks (`Core/Fakes/Contracts`) hold every implementation to
  the same behaviour. No Environment setup is needed, so previews can't crash from a missing object.

## 3. Modules: how the folders enforce the rules

**One local Swift package `VybeKit` with several targets.** A target must list which other targets it may use, so the compiler
enforces "features never import each other" (most useful for AI tools, which otherwise import whatever is nearby).

```
VybeKit/Package.swift      (only Lohitaksh edits this)
VybeKit/Sources/
  Models/        no dependencies; Sendable structs; LoadState, Page, AppError; sample data
  Core/          uses Models
  Design/        uses Models (tokens, buttons, chips, LoadStateView)
  Components/    uses Models + Design (HangoutCard, SpotRow, PlaceImage, Avatar)
  LocalData/     uses Core (bundled JSON, saved items on the phone)
  <Name>Feature/ × 13, each uses Models, Core, Design, Components
                 (the backend is its own package, VybeRemote, next to VybeKit; ADR 007)
VybeKit/Tests/   one test target per module (ContentTests loads every JSON file)
Vybe/            app target: VybeApp, tabs, Route → screen map, store setup
```

- **One package with many targets**, not many packages (isowords and Majid recommend this for small teams; confidence high).
- **All 13 feature targets exist from day one** (empty, with a README each): the whole frontend is built on sample data now and
  only the backend package waits. Empty targets cost nothing to compile.
- **Known costs:** `public` everywhere (2.1), resources need `Bundle.module` (or `#bundle`), and `Package.swift` is a shared file
  with one owner.
- **Risk (real, checked): SwiftUI previews inside local packages broke in Xcode 26.4** ("Could not find target description").
  Apple said 26.5 beta 1 fixes it; users still reported it on 26.6 (Apple Developer Forums 820802); nobody has reported on 27.1.
  F-0 compiled preview code but did not open the canvas (ADR 002), so **the first real `#Preview` (SC-HD1 or F-9) is the check**.
  If it fails: keep each target's name equal to its library product name (the only workaround in the thread), build the package
  scheme once, accept "trust macro" prompts; still failing, fall back to same-named folders inside the app target (the Element X /
  Landmarks / Damus shape) and enforce the import rule by review. (Confidence: medium.)

### 3.1 Concurrency settings (decision: `docs/adr/001-concurrency.md`)
A Swift package **does not inherit** the app target's settings, so they are written for every target in `Package.swift`:
- `Design`, `Components` and every `*Feature`: `.defaultIsolation(MainActor.self)` plus `NonisolatedNonsendingByDefault` and
  `InferIsolatedConformances` (same as the app target).
- `Models`, `Core`, `LocalData`: **no default isolation and no `NonisolatedNonsendingByDefault`**; types are `Sendable` (otherwise
  `Codable` conformances become main-actor-only, SE-0470). The few main-actor types in Core are marked `@MainActor` explicitly.
- **Swift 6 language mode** for the package and `SWIFT_VERSION = 6.0` for the app: the code base was empty, the cheapest moment.
  Global mutable state does not compile. A backend package may opt down per target. `Package.swift` says
  `platforms: [.iOS(.v26)]` explicitly. (Checked: SE-0466, SE-0470; F-0 compiled it, ADR 001.)

### 3.2 Full application folder structure (the map every teammate and AI tool follows)
`●` = exists in the committed skeleton (empty folders hold a `.gitkeep`; every module has a `README.md`). `○` = created later by a
task. `★` = Lohitaksh only (`Package.swift`, `Vybe.xcodeproj`, signing; `docs/START-HERE.md` section 2).

```
MIT-IOS-COHORT26-4/
├── .github/                   CODEOWNERS ●, pull_request_template.md ●, ISSUE_TEMPLATE/ (story, bug) ● · ○ workflows/ (lint.yml, test.yml)
├── AGENTS.md ● · CLAUDE.md ● (@AGENTS.md) · README.md ● · .gitignore ● · .swiftlint.yml ● · Local.xcconfig.example ●
├── docs/ ●                    PRODUCT, IA, ARCHITECTURE, DATA-MODEL, MOTION, PROCESS, RISKS, PLAN, OPEN-QUESTIONS, tasks/, adr/, prompts/
├── scripts/ ●                 check.sh (lint + tests), build_task_index.py · ○ new_screen.py, check_architecture.sh, snap.sh, content import
├── Vybe.xcodeproj ★ ●         project settings: lead only
├── Vybe/                      THE APP TARGET: wiring only, no screens
│   ├── VybeApp.swift ★        @main; builds AppDependencies; one WindowGroup
│   ├── App/                   AppDependencies+Local ★ (real repositories, stores, router) · RootView ★ (onboarding gate → TabShell; live
│   │                          cover) · TabShell ★ (Discover, Community, Profile, Search(role: .search)) · ScreenFactory ★ (Route → feature
│   │                          Screens) · ○ DeepLinkHandler ★ (Phase 2: vybe:// links, needs a URL scheme)
│   └── Resources/             Assets.xcassets · Localizable.xcstrings · PrivacyInfo.xcprivacy (UserDefaults reason CA92.1) · Kothrud-Walk.gpx
├── VybeTests/ ● app smoke tests · VybeUITests/ ○ one smoke test + performAccessibilityAudit()
├── VybeKit/                   LOCAL SWIFT PACKAGE (Xcode › Add Package › Add Local)
│   ├── Package.swift ★        platforms [.iOS(.v26)]; settings per target (3.1)
│   ├── Sources/
│   │   ├── Models/ ●          no dependencies
│   │   │   ├── Content/       IDs, Coordinate, RupeeRange, Photo, Place, Spot, Hangout, HangoutRun, Visit, ...
│   │   │   ├── People/ · Community/ ○ · Chat/ ○ · Safety/ (ReportTarget; Report ○)
│   │   │   ├── State/         LoadState, Page, AppError (no UI)
│   │   │   ├── Coding/        JSONCoding · Formatting/ money, duration, distance, counts
│   │   │   └── Samples/       preview data (clearly fake EXAMPLE values)
│   │   ├── Core/ ●            uses Models
│   │   │   ├── Navigation/ ★  AppTab, StackID, Route, Routes/<Feature>Route (12), Sheet, Cover, Payloads, Router
│   │   │   ├── Repositories/  Sendable protocols (not main-actor): Hangout, Place, Library (saved, drafts, runs), Profile, Search,
│   │   │   │                  PhotoStore · ○ Feed, Friends, Chat, Safety (report, block), Auth, Admin
│   │   │   ├── Fakes/ (#if DEBUG)  Stub*Repository, AppDependencies.preview, Contracts/
│   │   │   ├── Stores/        SessionStore, LibraryStore, LiveHangoutStore · ○ BadgeStore
│   │   │   ├── Services/      AppSettings, FeatureFlags, LocationService (protocol + Live + Simulated), NetworkMonitor · ○ PhotoProcessor, AudioRecorder
│   │   │   ├── Rules/         HangoutRules (2…10 Spots, 70% Remix credit, post eligibility, photo limit, post delay): pure, heavily tested
│   │   │   └── Logging/       Log.swift (os.Logger helpers)
│   │   ├── Design/ ●          uses Models: Theme/ ★ (Theme, Colors, Typography, Spacing, Motion) · ImageLoader (actor with an NSCache;
│   │   │                      Components may import Design but not Core) · Views/ (LoadStateView, buttons, FilterChip, EmptyStateView,
│   │   │                      OfflineBanner) · Resources/Colors.xcassets
│   │   ├── Components/ ●      uses Models + Design: HangoutCard, SpotRow, PlaceImage, Avatar, PickBadge (plain values, no ViewModel)
│   │   ├── LocalData/ ●       uses Core: Local*Repository, LocalPhotoStore (Bundle.module → URL), ContentLoader (public), LibraryFile
│   │   │                      (library.json, atomic, schemaVersion), Resources/Content/ (Places/, Hangouts/, Photos/)
│   │   └── <Name>Feature/     one folder per feature, uses Models, Core, Design, Components
│   │       ├── <Name>Screens.swift        the feature's ONLY public type (ADR 002); everything else is internal
│   │       └── <Screen>/ <Screen>View.swift · <Screen>ViewModel.swift · <Screen>+Preview.swift (.preview(.loaded / .empty / .failing))
│   │           Onboarding: Welcome NameAndPhoto Interests Location FindFriends (O1 to O5) · Discover: Map (incl. PinClusterer) PinPreview Filters (D1 to D3)
│   │           HangoutDetail: Detail SpotSheet RemixTree (HD1 to HD3) · Live: Live MarkVisited Summary MiniBar (H1 to H4) · Search: Search SeeAll (S1, S2)
│   │           Profile: Profile Saved Drafts Settings EditProfile ReadyToPost SettingsPages DeleteAccount (PR1, PR2, PR4 to PR6, PR8, ST1 to ST8)
│   │           Community: Feed PostDetail Comments Trending Activity (CM1 to CM5) · Editor: Editor AddSpot SuggestPlace (E1 to E3)
│   │           Posting: Composer EditPost (PO1, PO2) · Friends: Hub OtherProfile MutualFriends (FR1, PR3, PR7)
│   │           Chat: List Conversation NewChat GroupInfo Invitation Poll ShareSheet (CH1 to CH7) · Auth: SignIn EmailCode AccountBasics (A1 to A3)
│   │           Moderation: Report BlockConfirm Admin (R1, R2, AD1 to AD3)
│   └── Tests/                 ContentTests (every JSON file loads and passes HangoutRules) · CoreTests (Router, deep links, rules, LoadState)
│                              · LocalDataTests · <Name>FeatureTests (one ViewModel test file per screen)
└── backend/ ○                 Phase 2, outside the app: firebase.json, firestore.rules, storage.rules, functions/ (TypeScript: feeds,
                               counters, deletion, push), web/ (WEB1 share pages), rules-tests/ (security-rule tests, run in CI)
```

**Who may import whom** (the compiler enforces this through each target's dependency list):

| Target | May import |
|---|---|
| `Models` | nothing (Foundation only) |
| `Core` | Models |
| `Design` | Models |
| `Components` | Models, Design |
| `LocalData` | Core |
| every `<Name>Feature` | Models, Core, Design, Components. **Never another Feature, LocalData or Remote.** |
| `VybeRemote` (own package, later) | Models and Core from VybeKit (+ the backend SDK) |
| App target (`Vybe/`) | everything |

**File rules**
- One screen = one folder = `SomethingView.swift` + `SomethingViewModel.swift` + `Something+Preview.swift` (ViewModels for the
  loaded, empty and failed previews). The test is `Tests/<Name>FeatureTests/SomethingViewModelTests.swift`.
- Models, `Core/Navigation`, Theme, `Package.swift` and the App target are reviewed by Lohitaksh (CODEOWNERS). Every route is declared
  in F-4 and every feature has its `Screens` from F-16, so screen authors do not touch them.
- In `Models` and `Core`, every type used across targets is `public` with an explicit `public init`. In a feature **nothing is
  `public` except its `<Name>Screens`**; tests use `@testable import`.

**Where does X go?**

| I am adding… | It goes in… |
|---|---|
| a screen | its `<Name>Feature/<Screen>/` folder (View + ViewModel + Preview), wired by replacing its `case` in `<Name>Screens.swift` |
| a route for a brand-new screen | the feature's one file in `Core/Navigation/Routes/` (lead reviews) |
| a view used by two features | `Components` (plain values, no ViewModel) |
| a colour, font size, spacing, animation timing | `Design/Theme` (ask Lohitaksh) |
| a data struct | `Models` (ask Lohitaksh) |
| "what the app can ask for" (e.g. Hangouts near me) | a protocol in `Core/Repositories`; implementations in `LocalData` (now) / `Remote` (later) |
| a rule such as "2 to 10 Spots" | `Core/Rules` as a pure function with tests |
| state that two tabs share | a store in `Core/Stores` (ask first) |
| text shown to people | a `String(localized:)` in the screen's ViewModel |
| a new permission or capability | stop and ask Lohitaksh |

**Package details.** Done in F-0: a package target finds its String Catalog (use `bundle: #bundle`) and its colour assets (ADR 004);
the package builds in Swift 6 mode. **Decided (F-0 proof e, X-3):** each target that shows text owns its own
`Localizable.xcstrings`; shared words live in `Design` and are exposed as `SharedStrings`. Still to check: previews inside the
package (above); `Bundle.module` finds `Content/` (`.copy` keeps subfolders for JSON and photos); the app target still picks up
new files in `Vybe/`. The real manifest is `VybeKit/Package.swift`: `uiSettings` (main-actor default) on Design, Components and
Features only, none on Models, Core and LocalData, one `.library` per target the App imports, a test target per module.

## 4. Apple platform decisions (from Apple's docs)

| Area | Decision | Why |
|---|---|---|
| Tabs | 4 tabs: Discover, Community, Profile, then Search as `Tab(role: .search)` at the trailing end (never in the middle); `.searchable(text: $viewModel.query)` inside `SearchView` on the search tab's NavigationStack, **not** on the TabView root (forum reports: it attaches to the first stack and glitches pushed screens); `SearchViewModel` reads `router.lastNonSearchTab` when a query runs, not in `init` | Apple's way; on iOS 26+ Search is drawn apart and morphs into the search field |
| iOS 26 features (allowed) | `tabBarMinimizeBehavior`, `tabViewSearchActivation`, `tabViewBottomAccessory` (the live Hangout mini-bar), `glassEffect` on floating map controls, `Observations`, drawn-on symbol effects | minimum is iOS 26: no `#available` |
| Tabs never hidden | Community shows an explained empty state | HIG |
| Map pins | `Marker` / `Annotation`, `Map(selection:)` | iOS 17+ |
| Route line | `MKDirections` (walking) only when the live screen opens; cache it; straight-line `MapPolyline` fallback if throttled | Apple docs warn about throttling |
| Look Around | **Not used** | not available in India (Apple feature availability, checked) |
| Apple place details | store `applePlaceID`; fetch live with `MKMapItemRequest`; show with `mapItemDetailSheet` | Apple's Landmarks sample; storing MapKit data is not allowed |
| MapKit item creation | iOS 26 APIs `MKMapItem(location:address:)`, `MKAddress`; **never** `MKMapItem(placemark:)` (deprecated in iOS 26) | AI tools trained on old code suggest the old one |
| iOS 27-only SwiftUI APIs | avoid `Tab(role: .prominent)`, `swipeActionsContainer`, `reorderable`, `toolbarMinimizationBehavior`, `topBarPinnedTrailing`, or guard with `#available(iOS 27, *)` | above our minimum |
| Pin clustering | SwiftUI `Map` can't cluster (Apple engineer, Developer Forums, checked). Version 1: our own grid clustering in the Discover ViewModel (works on `Coordinate` and a zoom span; the View converts `MapCameraPosition`), recomputed on camera change, plus filter chips and one pin per Hangout; wrap `MKMapView` only if that is too slow on the lab iPhone | no clustering API in SwiftUI |
| Confirmations | `alert(_:item:)` / `confirmationDialog(_:item:)` | back-deployed to iOS 15 |
| Images in the feed | the phone uploads two sizes (~1600 px, ~400 px); `URLCache` ~50 MB memory / 200 MB disk at launch; one small `ImageLoader` | no server image step; `AsyncImage` caching is only documented from iOS 27 |
| Voice notes | AAC mono 32 kbps (~240 KB per minute), max 2 minutes | arithmetic from the bitrate |
| Map legal | keep the Apple Maps logo and Legal link visible (`safeAreaInset`) | WWDC23 MapKit session |
| Pin preview | card overlay on the map (keeps the tab bar), not a sheet | a sheet covers the tab bar |
| Live Hangout | `fullScreenCover` | HIG: long tasks go full-screen |
| Photos | `PhotosPicker` (no permission prompt); downsample and re-encode with ImageIO **without metadata** (removes GPS) | Apple ImageIO docs; the GPS-only exclude flag misses some hidden metadata |
| Feed (Phase 2) | `ScrollView` + `LazyVStack`, a small model per card, downsampled images; measure on a real device | WWDC25 performance guidance |

## 4a. Apple fundamentals (audit of what we were missing)

| # | Area | Rule | When |
|---|---|---|---|
| 1 | **Location permission text** | `NSLocationWhenInUseUsageDescription` must exist or the O4 prompt never appears (project setting: lead's OK) | Phase 1 |
| 2 | **Live Hangout survives the app being closed** | save the run to disk on every change; time comes from `startedAt` (`Text(start, style: .timer)`), never a running timer; restore on launch | Phase 1 |
| 3 | **Dynamic Type** | Theme fonts are text styles or `relativeTo:`; never `.system(size:)`; spacing that grows with text uses `@ScaledMetric`; one preview at a large text size | Phase 1 |
| 4 | **VoiceOver and touch** | every icon-only button, map pin and meaningful photo has an `accessibilityLabel`; decorative images hidden; tap targets at least 44×44 pt; never colour alone for state | Phase 1 |
| 5 | **Text and numbers** | ViewModels give text as `String(localized:)` / `LocalizedStringResource` (Foundation, no SwiftUI import); money, distance, time with `.formatted(...)` (₹, km); plurals in one `Localizable.xcstrings` | Phase 1 |
| 6 | **Logging** | `os.Logger` per feature, never `print`; no names, coordinates or tokens without `privacy: .private` | Phase 1 |
| 7 | **Design system the Apple way** | colours are Asset Catalog colour sets used through Theme (no hex in Swift); SF Symbols; only system bars, tabs and sheets, no custom backgrounds (they get Liquid Glass automatically) | Phase 1 |
| 8 | **Modern location code** | only through Core's `LocationService`, using `CLLocationUpdate.liveUpdates` (iOS 17) and `CLServiceSession` (iOS 18); no delegate code; **never ask for "Always"** | Phase 1 |
| 9 | **Simulated walk** | a committed Kothrud `.gpx` route used by the Xcode scheme | Phase 1 |
| 10 | **Live Hangout with the phone locked** | would stop today: a When-In-Use app in the background gets no updates without a background session or Live Activity (WWDC24 location session). Fix: Background Modes → Location updates (**approved 3 Nov**) + a `CLBackgroundActivitySession` kept alive while the Hangout is live | **Phase 1** |
| 11 | Other permission texts | camera, microphone (voice notes) | Phase 2 |
| 12 | Accessibility audit test | one UI test calling `performAccessibilityAudit()` (iOS 17) | Phase 2 |
| 13 | Security | tokens only in the Keychain (the backend SDK does this); never add App Transport Security exceptions | Phase 2 |
| 14 | Notifications | ask at the first friend request or chat, not at sign-up | Phase 2 |
| 15 | Sharing | Phase 1: `ShareLink` with plain text (title + "Find it on Vybe"); Phase 2: the web link (WEB1) and `vybe://` deep links | Phase 1 / 2 |
| 16 | Live Activity on the lock screen | Apple's preferred way to show a live Hangout | Phase 2 / later |
| 17 | Diagnostics | Xcode Organizer crashes; Instruments (SwiftUI instrument) on the lab iPhone | Phase 2 |
| 18 | App Store | privacy labels; Accessibility Nutrition Labels (voluntary for now; we can never claim "Dark Interface"); age-rating answers incl. Social Media and Shared Location (due 12 Jan 2027); iPhone Duo screenshots and the iOS 27 SDK from April 2027; keep the generated launch screen (required with the iOS 27 SDK). Details: `docs/RISKS.md` | before submission |
| 19 | **Resizable iPhone apps** | iOS 27 lets iPhone apps be resized (iPhone Mirroring, iPad, the new iPhone Duo), so "portrait only" is no guarantee: no fixed widths, never `UIScreen.main.bounds`; check in Xcode 27's Resizable Canvas | Phase 1 |
| 20 | **Liquid Glass tint slider** (iOS 27) | never add `UIDesignRequiresCompatibility`; check key screens with the system tint at both ends | Phase 1 |
| 21 | **Search on the phone** | Hangouts and Places (under 1 MB) are searched on the phone; people are searched by username prefix on the server | Phase 1 (Hangouts, Places) / 2 (people) |

Motion rules and tokens: `docs/MOTION.md`. Storage and the data model: `docs/DATA-MODEL.md` (summary: **no database on the phone**;
JSON files in Phase 1; the backend SDK's cache in Phase 2).

## 4b. Web share page for Android friends (WEB1, version 1)
Decided 3 Nov. iOS is about 5% of phones in India, so every shared Hangout and post gets a public web page.
- **Shape:** `https://<project>.web.app/h/<id>` (Hangout) and `/p/<id>` (post). A Firebase Hosting rewrite sends the request to a
  small function that returns **plain server-rendered HTML** with `og:title`, `og:description` and `og:image` (WhatsApp's crawler
  reads those tags and does not run JavaScript). Cover image about 1200×630, under 300 KB. Content: cover photo, title, "3 Spots,
  ₹150 to 400", the Spots list, an "I'm in" button and "Get Vybe on iPhone".
- **Privacy:** only **Public** posts and Picks show content. A Friends-only post shows "Ask your friend to invite you" and nothing
  else. No exact times, no live location.
- **"I'm in" without an account:** the guest types a name; the function stores a `GuestResponse` (rate-limited, simple abuse check).
  Guests never appear in friend lists or chats; the host sees "2 friends said I'm in" on their post.
- **Opening the app from the link** (universal links) needs the Associated Domains capability and the paid Apple account, so it
  arrives with TestFlight; before that the share link opens the web page. No deferred deep linking (Firebase Dynamic Links shut
  down Aug 2025).
- **Owner:** the "server owner" teammate; code in `backend/web/`. On Supabase this needs a separate static host (its functions
  can't serve HTML).

## 5. Testing (that beginners will actually keep doing)
Swift Testing (`@Test`, `#expect`), built into Xcode.
1. **Content test:** every JSON file loads and passes the rules (IDs unique, 2 to 10 Spots, coordinates in Pune).
2. **Rule tests:** 70% Remix credit, at least 2 visited Spots to post, max photos 2 × Spots.
3. **ViewModel tests** (the main benefit of MVVM): fake repositories, call `load()` or a tap method, check `state` and the router;
   plus store tests; mark them `@MainActor`.
4. **Router and deep-link tests** (copy Ice Cubes' `RouterTests`).
5. **Three previews per screen:** loaded, empty, error. At most one UI smoke test.
The test suite is the "contract" AI agents must satisfy (Donny Wals, 2026).

## 6. Keeping four people and their AI tools consistent

| Guardrail | What |
|---|---|
| Golden example | one complete feature built by hand first (HangoutDetail), with a copy-me template and a generator (`scripts/new_screen.py`, X-5) |
| Machine checks | SwiftLint custom rules + `scripts/check_architecture.sh` (X-1, X-13, ADR 006): imports, `public` only in `Screens`, `RunTimes` confinement, a test file per ViewModel |
| Agent loop | debug launch options + `scripts/snap.sh` (X-14): open one screen in one state and screenshot it |
| Screen recipe in `AGENTS.md` | folder, `SomethingView` + `SomethingViewModel`, LoadStateView, Theme tokens, router calls from the ViewModel, three previews, a ViewModel test, `check.sh` |
| SwiftLint custom rules | ban hard-coded colours (`Color(red:`), `.foregroundColor(`, `NavigationLink(destination:`, `ObservableObject`, and the banned words (Plan, Trace, Stop, Node, outing, Fork, Organiser) **only inside string literals and type, case and file names, with word boundaries** (so `.sensoryFeedback(.stop)` and Apple API names are fine) |
| iOS 26 rule | "Use iOS 26 APIs only; iOS 27-only ones inside `if #available(iOS 27, *)`" in `AGENTS.md` |
| Shared files | `VybeKit/Package.swift`, `Vybe.xcodeproj`, signing: Lohitaksh only. `Route`/`Router`, Theme tokens, the feature `Screens` and the thin `ScreenFactory` are created once by their tasks (F-4, DS-1, F-16, F-9); after that a screen's author replaces only their own `case`, and Theme changes go through a PR to Lohitaksh |
| Short `AGENTS.md` | Anthropic's guidance: keep it short; hard rules belong in tools (lint, CI, hooks), not paragraphs |
| Claude Code settings (optional, lead's OK) | deny edits to `*.pbxproj`, `Local.xcconfig`, signing; run `check.sh` automatically at the end of a task |
| CI | `check.sh` on every PR (section 7) |

## 7. Team process (checked)
- **Git:** trunk-based, short branches (under a day), small PRs, squash merge (DORA, trunkbaseddevelopment.com); GitFlow is overkill.
- **Branch protection:** on GitHub's free plan, protected branches and required reviews for **private** repos are not included
  (Pro and Team). Options: (a) MIT faculty request GitHub Team via GitHub Education, (b) pay for Team (about $4 per user per
  month), (c) make the repo public, (d) the team rule plus local checks. Mentor question.
- **CI:** GitHub Actions macOS minutes on a private repo cost about 10× Linux; the free allowance covers only a few full test runs
  a month. Plan: SwiftLint on a Linux runner for every PR; Xcode build and tests on macOS only when a PR is marked ready. Xcode
  Cloud (25 hours a month included) becomes available once the Apple Developer Program is bought.
- **Free "Personal Team" account** (**UNVERIFIED**: a research agent's reading of Apple's capability table): no push notifications,
  Sign in with Apple, Associated Domains, App Attest or iCloud; App Groups and Keychain sharing are available. **Background
  location:** an Apple engineer says the `location` background mode is just the `UIBackgroundModes` Info.plist key and "does not
  require any specific entitlement" (Developer Forums, **checked**), so it very likely works on a free account; test on the lab
  iPhone on Fri 6 Nov. Free builds expire after 7 days; up to 3 devices and 3 apps per device (forum-sourced).
- **Xcode 27 agents** (Claude Agent, Codex, Gemini are built in): use plan mode, turn on the file-access security layer, never use
  "allow all", and don't convert the project to the new `.xcproj` format without the lead's OK. Check whether Xcode's built-in agent
  reads our `AGENTS.md` / `CLAUDE.md`.
- **Apple Developer Program:** buy on **16 Nov**, not 18 Dec (push notifications, Sign in with Apple and TestFlight need it). An
  individual account shows the person's legal name as the seller; an organisation needs a registered company and a D-U-N-S number.
- **Privacy manifest:** add `PrivacyInfo.xcprivacy` early (`@AppStorage`/UserDefaults is a "required reason" API, reason CA92.1).
- **TestFlight:** the first external build goes through Beta App Review. A privacy policy is required for the App Store; whether
  external TestFlight needs one is unclear.

## 8. Backend (Phase 2), not decided

| Criterion | Firebase | Supabase |
|---|---|---|
| Beginner-friendly iOS SDK | good (SDK 13.x needs Xcode 26.2+, checked) | fair (supabase-swift needs Swift 6.2, Xcode 26+) |
| Offline read-only cache | built in (on by default on iOS) | build our own |
| Push notifications | built in (FCM) | build our own (webhook + function) |
| Friends, privacy, blocking rules | harder (no joins, copied data) | natural (SQL + row-level security) |
| Real-time chat | good | good |
| Photo and voice storage | **needs the paid Blaze plan since 3 Feb 2026** (checked) | 1 GB free |
| Cost control | budget alerts only, no hard cap on Firestore/Storage | free tier pauses after 7 days idle |
| India reliability | Mumbai and Delhi regions | Mumbai region; **blocked by some Indian ISPs 24 Feb to 3 Mar 2026** (checked) |
| Lock-in | higher | lower (open source) |
| Search later, at scale | new Enterprise text search (no offline; the edition can't change after the database is created) or a paid service | free built-in full-text and fuzzy search |
| People search hiding blocked users | prefix query; block filtering on the phone | prefix query + row-level security |
| "Near me" later | geohash code by hand; Enterprise geo is preview | PostGIS (official map-area example) |
| Link preview pages for WhatsApp | Hosting + a function in one place | Edge Functions can't serve web pages without a paid custom domain |
| Admin tools | console + roles + a hidden admin section in the app | Studio table editor + roles in row-level security + in-app admin |
| Server code | about 8 to 10 TypeScript functions | about 2 or 3 functions + SQL triggers |
| Extensions | **Firebase Extensions shut down 31 Mar 2027** (checked): don't depend on them | n/a |

Version 1 plan that works with either backend:
- search Hangouts and Places on the phone; "near me" filtered on the phone; photo sizes made on the phone;
- web preview pages for shared Hangouts on Firebase Hosting (free `*.web.app` domain); universal links need the paid Apple account;
- admin = Places and Picks as JSON in git with an import script, plus a hidden admin section in Settings for reports, suggestions
  and bans (enforced by server rules);
- one "server owner" on the team; every function or trigger tested in the local emulator first. Firebase Dynamic Links shut down
  in Aug 2025, so no deferred deep links.

Current lean: **Firebase** (offline caching and push are built in; avoids the India block risk). The data model and security rules
must be designed up front. Either way the "no third-party libraries" rule needs one exception for the backend SDK (and possibly
Google Sign-In). Plan: a one-day test of both on 16 to 17 Nov (BK-1).

## 9. What we are deliberately NOT doing (and why)

| Not doing | Why |
|---|---|
| TCA (The Composable Architecture) | a third-party library; Point-Free itself does not recommend it for people learning SwiftUI |
| Clean Architecture / VIPER | too much ceremony for about 40 screens and 6 weeks |
| Logic or data loading inside Views | MVVM: Views only lay out; all logic lives in the ViewModel (2.4) |
| `NavigationPath` | type-erased; `[Route]` is simpler to test and deep-link |
| A global sheet for everything | only sheets that more than one feature opens are global (`spot`, `report`, `share`, ...); the rest stay in their screen's ViewModel (2.6) |
| Many packages / Tuist / XcodeGen | synchronized folders already remove project-file conflicts |
| Snapshot tests | need a third-party library |
| Look Around | not available in India |

## 10. Risks
Project-level risks are ranked in `docs/RISKS.md` and the schedule risk is in `docs/BEFORE-BUILD.md` 4. Specific to this document:
previews inside packages (section 3; fallback ready), shared files with one owner (section 6), AI tools using iOS 27-only or
deprecated APIs (lint rules and review; `AGENTS.md` 5a), and backend lock-in and cost surprises (Firebase has no hard spending cap;
section 8).

## 11. Questions for mentors
The question list is `docs/MENTOR-SESSION.md`; open product, legal and backend decisions are in `docs/OPEN-QUESTIONS.md`. Already
decided: Swift 6 now (ADR 001); a Screens factory per feature (ADR 002); routes grouped per feature and `Codable` (ADR 003); iOS 26
minimum. Still open and specific to architecture: one package with a target per feature, or plain folders in the app target with
lint rules (is 13 feature targets too much structure for four beginners?) · rely on the backend SDK's offline cache or write our own
· Firestore Enterprise edition (permanent; no offline search) · server-side photo screening in version 1 · grid clustering we write
ourselves or wrapping `MKMapView` · whether the iOS 26 minimum (about 21% of iPhones in June 2026 cannot install) is acceptable for
a student audience.

## Sources
Evidence links: `docs/SOURCES.md` (section "Architecture").
