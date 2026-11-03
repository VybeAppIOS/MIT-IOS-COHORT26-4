# Vybe: Technical Architecture (PROPOSAL, for mentor review)

Status: **proposal, not approved.** Written 3 Nov 2026. Based on:
- the source code of real open-source SwiftUI apps (Ice Cubes, IcySky, Element X,
  Damus, Apple's Backyard Birds, Food Truck and Landmarks samples, Point-Free's isowords),
- Apple's documentation, WWDC sessions and the Human Interface Guidelines,
- articles by SwiftUI experts (SwiftLee, Swift with Majid, Donny Wals, Nil Coalescing,
  Point-Free, Hacking with Swift),
- Firebase, Supabase, GitHub and Apple developer documentation.

Every recommendation says how confident we are and why. Sources are at the end.

---

## 0. Our environment (checked on the lead's Mac)

| | Value |
|---|---|
| Xcode | 27.1 (Swift 6.4), iOS 27 simulators |
| App deployment target | **iOS 26.0** (decided 3 Nov), iPhone, portrait, light |
| App target settings | Swift language mode 5, default actor isolation = MainActor, "approachable concurrency" on |
| Project | Xcode synchronized folders (new files don't edit the project file) |
| Simulators installed | iOS 27.0 and 27.1. Our minimum is iOS 26, so also install an **iOS 26 simulator runtime** and run `check.sh` on it weekly (Xcode › Settings › Components). |
| Liquid Glass | Because we build with the iOS 27 SDK, the opt-out key `UIDesignRequiresCompatibility` is ignored (Apple docs, **checked**). On iOS 26+ phones the app always has the Liquid Glass look. |
| Real-device debugging | Xcode 27 debugs devices on iOS 17 or later. |

Meaning: we **build** with the newest tools (iOS 27 SDK) but may only **use** APIs that
exist on iOS 26. **One design, no old-iOS branches:** Liquid Glass, the search-role tab
that separates from the other tabs, `glassEffect`, `tabViewBottomAccessory`,
`Observations` and the iOS 26 MapKit address APIs are all allowed without `#available`.
Only iOS 27-only APIs need `if #available(iOS 27, *)` (or are avoided in Phase 1).
Cost of this choice: iPhone XS, XS Max and XR cannot run iOS 26, so they are excluded
(Apple: iOS 26 ran on 79% of all iPhones in June 2026). This was the team's decision.

## 1. The big picture

```
┌─────────────────────────────────────────────────────────────┐
│ App target (Vybe/)                                          │
│ VybeApp · tab bar · Route → screen map · builds the stores  │
│ · deep links · (Phase 2) backend setup                      │
└───────────────┬─────────────────────────────────────────────┘
                │ uses everything below
┌───────────────▼─────────────────────────────────────────────┐
│ Feature modules: one per area, never import each other      │
│ Phase 1: Discover · Community (placeholder) · Profile ·     │
│          Search · HangoutDetail · Live · Onboarding         │
│ Each feature = Views + ViewModels (MVVM)                    │
│ Phase 2: + Editor · Posting · Friends · Chat · Auth · Moderation │
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
  Remote   (Phase 2: the only module allowed to import Firebase/Supabase)
```

Rule: arrows point down only. A feature may use Core, Components, Design and Models.
It may never use another feature. Only the App target sees everything.

This is the same shape as **Ice Cubes** (a SwiftUI social app, 13 packages, @Observable,
router per tab, Route → screen map in the app target) and **IcySky** (same author,
generic router with one path per tab plus sheets).

## 2. Building blocks (what every teammate must understand)

### 2.1 Models
Plain data. No logic, no SwiftUI, `Sendable` (safe to pass between threads).
Typed IDs stop mixing up a Place ID and a Hangout ID; in JSON they are plain strings.

```swift
public struct Hangout: Codable, Hashable, Sendable, Identifiable {
    public let id: HangoutID
    public var title: String
    public var spots: [Spot]          // ordered, 2 to 10
    public var authorID: UserID
    public var isPick: Bool
    public init(id: HangoutID, title: String, spots: [Spot], authorID: UserID, isPick: Bool) {
        self.id = id; self.title = title; self.spots = spots; self.authorID = authorID; self.isPick = isPick
    }
}
// SHORT EXAMPLE to show the pattern. The real fields are in docs/DATA-MODEL.md section 5.
```
Because Models is a separate module, every type and `init` used elsewhere must be
`public`. Swift never makes the automatic memberwise `init` public, so we write
public `init`s ourselves. (Confidence: high; Swift language rule.)

Sample data for previews lives next to the models (`Hangout.samples`), as in Ice Cubes,
Backyard Birds and Landmarks.

### 2.2 Repositories: where data comes from
A repository is a promise such as "I can give you Hangouts". One per **data area**
(Hangouts, Places, Library for saved and drafts; later Feed, Friends, Chat, Users,
Moderation). Not one per screen.

```swift
public protocol HangoutRepository: Sendable {
    func hangout(id: HangoutID) async throws -> Hangout
    func hangouts(near area: Area, filters: Filters) async throws -> [Hangout]
}
```
- Phase 1: `LocalHangoutRepository` reads JSON bundled in the app.
- Phase 2: `RemoteHangoutRepository` talks to the backend.
- Switching is one line in the App target. Screens never change.
- One shared "contract test" suite runs against both, so they behave the same.

Ice Cubes skips repositories and calls its network client directly. We keep them
because our backend is undecided and Phase 1 runs on local data. (Confidence: medium-high.)

### 2.3 Stores: state many screens share
`@Observable` classes created once in `AppDependencies` and handed to ViewModels through
their `init`s (**nothing is read from the SwiftUI Environment**). Rule: a store exists
**only if more than one tab needs the data.**

| Store | Holds |
|---|---|
| `SessionStore` | current user, onboarding done, blocked user IDs |
| `LibraryStore` | Saved, Drafts and finished runs not yet posted (on the phone in Phase 1) |
| `LiveHangoutStore` | the Hangout running right now: creates or resumes the `HangoutRun`, survives tab switches, saves to disk on every change |
| `BadgeStore` (Phase 2) | unread chat, Activity and friend-request counts for the Community tab badge and the bell |

Feed, search results and chat messages are **not** stores; they belong to their screen's
ViewModel.

**Small settings** (onboarding done, chosen area, interests) live in `Core/Services/AppSettings`,
a tiny wrapper around `UserDefaults` (Foundation only). `@AppStorage` is a SwiftUI
property wrapper: it is not allowed in Core or ViewModels, and inside an `@Observable`
class it fails to compile ("invalid redeclaration of synthesized property", verified).
Personal data (name, photo) is never put in `UserDefaults`.

### 2.4 MVVM: View, ViewModel, Model (team decision)
The app uses **MVVM** (Model, View, ViewModel). Every screen has exactly two files:

| Layer | What it is | Rules |
|---|---|---|
| **Model** | the data structs (2.1), repositories (2.2) and stores (2.3) | no SwiftUI |
| **ViewModel** | `SomethingViewModel`, a `@MainActor @Observable final class`, one per screen | holds the screen's state as a `LoadState`; loads through repositories; one method per user action; prepares text for display; asks the router to navigate; **does not import SwiftUI** |
| **View** | `SomethingView`, a SwiftUI `struct` | lays things out from ViewModel properties; forwards taps to ViewModel methods; no loading, no logic |

Every screen gets a ViewModel, even simple ones, so all four people and their AI tools
produce the same shape. Shared components (HangoutCard, SpotRow) have no ViewModel;
they take plain values.

Evidence: MVVM is what Ice Cubes' README describes for most of the app, and Element X
(a production chat app) gives every screen a ViewModel. Some experts (Thomas Ricouard,
SwiftLee) now say view models are optional with `@Observable`; the team chose MVVM for
consistency and testability, which suits beginners and AI agents.

```swift
// A ViewModel exposes VIEW-READY values, never raw models (a raw Hangout has no Place names).
public struct HangoutDetailContent: Equatable, Sendable {
    public let title: String
    public let budgetText: String        // "₹150–400 per person" built with .formatted
    public let spots: [SpotRowData]      // plain values for the SpotRow component
}

@MainActor @Observable
public final class HangoutDetailViewModel {
    public private(set) var state: LoadState<HangoutDetailContent> = .loading
    private let id: HangoutID
    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let library: LibraryStore
    private let liveStore: LiveHangoutStore
    private let router: Router
    private var hasLoaded = false

    public init(id: HangoutID, hangouts: any HangoutRepository, places: any PlaceRepository,
                library: LibraryStore, liveStore: LiveHangoutStore, router: Router) {
        self.id = id; self.hangouts = hangouts; self.places = places
        self.library = library; self.liveStore = liveStore; self.router = router   // cheap: no loading here
    }

    public var isSaved: Bool { library.isSaved(id) }

    public func load() async {
        guard !hasLoaded else { return }          // .task runs again whenever the screen reappears
        do {
            let hangout = try await hangouts.hangout(id: id)
            let spots = try await places.spots(for: hangout)
            state = .loaded(HangoutDetailContent(title: hangout.title,
                                                 budgetText: hangout.budgetPerPerson.formattedPerPerson,
                                                 spots: spots))
            hasLoaded = true
        } catch { state = .failed(AppError(error)) }
    }
    public func startTapped() {
        liveStore.startOrResume(hangoutID: id)    // creates the HangoutRun (or resumes the live one)
        router.presentCover(.live(id))
    }
    public func saveTapped() { library.toggleSave(id) }
}

public struct HangoutDetailView: View {
    @State private var viewModel: HangoutDetailViewModel
    public init(viewModel: HangoutDetailViewModel) { _viewModel = State(initialValue: viewModel) }
    public var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.load() } }) { content in
            // layout only
            PrimaryButton("Start Hangout") { viewModel.startTapped() }
        }
        .task { await viewModel.load() }
    }
}
```
Rules that avoid known pitfalls:
- **ViewModel `init`s must be cheap.** SwiftUI may create the View struct many times;
  `@State` keeps only the first ViewModel, but each `init` still runs (Apple docs, Nil
  Coalescing). Load data in `.task`, never in `init`.
- **`load()` is idempotent** (`guard !hasLoaded`): `.task` runs again whenever a screen
  reappears, for example after popping back.
- **ViewModels get dependencies through `init`**, never from the Environment (an
  `@Observable` class cannot read `@Environment`).
- **Text:** fixed labels that never change ("Start Hangout") are literals in the View and
  go into the String Catalog; any computed or data-dependent text (budgets, counts,
  distances) is built in the ViewModel with `String(localized:)` and `.formatted(...)`.
- **ViewModels never write `router.cover = …`**; they call the Router's methods (2.6).
- **Testing:** ViewModels don't import SwiftUI, so each is tested directly with the
  stubs in `Core/Fakes` (2.7): call `load()` or `startTapped()`, check `state`, the
  router and the stores.
- **Xcode 27 `@State` change (checked in the iOS 27 release notes):** `@State` is now a
  macro that creates its value once per view lifetime (back-deploys to iOS 17). Our
  ViewModels are still built by the parent on every redraw, so keep `init`s cheap. Never
  give a `@State` both a default value and an assignment in `init`: that no longer
  compiles. Check in F0 that `_viewModel = State(initialValue:)` still compiles.
- **Swift 6.4** warns when an error thrown inside a `Task` is ignored: handle it, never
  silence the warning.
- **Showing a photo:** `Components` can't read files. A ViewModel turns a `Photo` into a
  `URL` with Core's `PhotoStore` protocol (`LocalData` implements it with `Bundle.module`;
  `Remote` returns storage URLs) and passes the `URL?` to `PlaceImage(url:)`.

### 2.5 LoadState: one standard for loading, empty, error, offline
`LoadState`, `Page` and `AppError` live in **Models** (no UI), so `Design`'s `LoadStateView`
can use them.
```swift
public enum LoadState<Content> {
    case loading
    case loaded(Content, isStale: Bool = false)   // isStale: cached or offline
    case empty
    case failed(AppError)
}
extension LoadState: Equatable where Content: Equatable {}   // so tests can write #expect(vm.state == .empty)
```
`Content` is a **view-ready struct** (title, price text, `[SpotRowData]`), never a raw
model. One shared `LoadStateView(state, onRetry:)` draws all four the same way:
placeholder skeleton (`.redacted(reason: .placeholder)`), `ContentUnavailableView` for
empty, a retry button for errors, and the offline banner when stale. Copied from how Ice
Cubes does it. Lists that load more pages use `Page<T>` with a cursor and a "loading more" flag.

### 2.6 Navigation: Router and Routes
```swift
// Tab bar order: Discover, Community, Profile, then Search as a separate
// search-role tab at the trailing end.
public enum AppTab: Hashable { case discover, community, profile, search }

/// Every NavigationStack has an ID: one per tab, one for onboarding, one inside each full-screen cover.
public enum StackID: Hashable { case onboarding, tab(AppTab), live, editor }

public enum Route: Hashable {                   // pushes; carries IDs only
    // onboarding (P1: O2-O4; P2: sign-in)
    case nameAndPhoto, interests, location
    case signIn, emailSignIn, accountBasics, findFriends                        // P2
    // content
    case hangout(HangoutID)                     // HD1
    case remixTree(HangoutID)                   // HD3 (P2)
    case post(RunID)                            // CM2 (P2)
    case profile(UserID)                        // PR3 (P2)
    case mutualFriends(UserID)                  // PR7 (P2)
    // profile area
    case saved, drafts, readyToPost, settings   // PR4, PR5, PR8, PR2
    case settingsPage(SettingsPage)             // ST1...ST7 (P2)
    case deleteAccount                          // ST8 (P2)
    case admin(AdminPage)                       // AD1-AD3 (P2, team accounts only)
    // community area (P2 except the placeholder feed)
    case friends, activity, trending            // FR1, CM5, CM4
    case chats, conversation(ConversationID), groupInfo(ConversationID)   // CH1, CH2, CH4
    // inside the live-Hangout cover
    case liveSummary(RunID)                     // H3
    case composePost(RunID)                     // PO1
    // search
    case searchSeeAll(SearchKind)               // S2
    // when a sheet is already up, Report opens as a push inside that sheet
    case report(ReportTarget)                   // R1 (P2)
}

/// Sheets that more than one feature can ask for. Shown by exactly one host at a time (see below).
public enum Sheet: Identifiable {
    case spot(PlaceID)                          // HD2: opened from Search, Hangout detail AND the live screen
    case report(ReportTarget)                   // R1 (P2)
    case share(ShareItem)                       // CH5 (P2)
    case suggestPlace                           // E3 (P2): opened from Search (empty) and the editor
    case editPost(RunID)                        // PO2 (P2): opened from the post detail
    case groupInvitation(ConversationID)        // CH7 (P2)
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

public enum Cover: Identifiable {               // full-screen
    case live(HangoutID)                        // H1 → H3 → PO1, on the `.live` stack
    case editor(EditorStart)                    // E1: .new, .draft(id) or .remix(id)
    public var id: String {
        switch self { case .live(let h): "live-\(h.rawValue)"; case .editor: "editor" }
    }
}

@MainActor @Observable public final class Router {
    public var selectedTab: AppTab = .discover { didSet { if selectedTab != .search { lastNonSearchTab = selectedTab } } }
    public private(set) var paths: [StackID: [Route]] = [:]   // one stack per tab, onboarding and each cover
    public private(set) var cover: Cover?
    public private(set) var sheet: Sheet?
    public private(set) var lastNonSearchTab: AppTab = .discover   // used to rank Search results (read at query time)

    /// Push onto the stack that is on screen (the cover's if one is up, else the selected tab's).
    public func open(_ route: Route) { paths[currentStack, default: []].append(route) }
    public func pop() { _ = paths[currentStack]?.popLast() }
    public func popToRoot() { paths[currentStack] = [] }
    public func present(_ sheet: Sheet) { self.sheet = sheet }
    public func dismissSheet() { sheet = nil }
    public func presentCover(_ cover: Cover) { self.cover = cover }
    public func dismissCover() { if let c = cover { paths[stack(for: c)] = [] }; cover = nil; sheet = nil }
    /// Leave whatever is up and show a screen in a tab (e.g. "post made → show it in Community", "Done → Drafts").
    public func show(_ route: Route?, in tab: AppTab) {
        dismissCover(); selectedTab = tab; paths[.tab(tab)] = route.map { [$0] } ?? []
    }
    /// Sign out, account deletion, "reset onboarding": clear every stack, sheet and cover.
    public func reset() { paths = [:]; cover = nil; sheet = nil; selectedTab = .discover }

    private var currentStack: StackID { cover.map(stack(for:)) ?? .tab(selectedTab) }
    private func stack(for cover: Cover) -> StackID { switch cover { case .live: .live; case .editor: .editor } }
}
```
(Typechecked with `swiftc` in Swift 5 and 6 language modes; the `Identifiable` `id`
properties are required because an enum with payloads gets none automatically.)

**Rules**
- **Declare Phase 1 cases only in F0** (types for Phase 2 cases don't exist yet); the
  `ScreenFactory` `switch` must stay exhaustive, so each Phase 2 case is added by the owner together with
  its stub when that feature starts. `ReportTarget`, `ShareItem` and similar payloads are small
  IDs-only structs.
- **Which presentation do I use?**

  | Situation | Use |
  |---|---|
  | only one feature shows it (Filters, Mark visited, Comments) | a flag in that screen's ViewModel + `.sheet` |
  | two or more features can open it (Spot, Report, Share, Suggest a Place) | a `Sheet` case through the router |
  | a sheet is already up and you need Report | push `Route.report` inside that sheet's own `NavigationStack` |
  | a long multi-step task (live Hangout, editor) | a `Cover` with its own stack |

- **Who shows the router's sheet.** A view underneath a full-screen cover cannot present
  a sheet. So `.sheet(item:)` is attached in **two** places: on `TabShell` (active only
  while `router.cover == nil`) and on the root of each cover's content (active only while a
  cover is up). Only the Spot sheet (HD2) and the local Mark-visited sheet (H2) are allowed
  inside the live cover.
- **Onboarding** has its own stack: `RootView` shows
  `NavigationStack(path: …paths[.onboarding])` until `session.onboardingDone`, then
  `TabShell`. Finishing calls `session.completeOnboarding()` and `router.reset()`.
- **Each stack needs its own** `.navigationDestination(for: Route.self)` on its root view
  (every tab, onboarding, `.live` and `.editor`), never inside a `List` or `LazyVStack`.
- **Starting a Hangout:** `HangoutDetailViewModel.startTapped()` calls
  `liveStore.startOrResume(...)` and then `router.presentCover(.live(id))`. If a run is
  already live or minimised, Start asks to resume it instead of creating a second one.
- **Leaving a flow in another tab** uses `router.show(_, in:)`: post made → show it in
  Community; editor Done → Profile › Drafts; Phase 1 summary → Discover root.
- **Adding a Route (checklist):** 1) Lohitaksh adds the `Route` case; 2) a stub for it is
  added to `ScreenFactory`; 3) the author writes the View, ViewModel and Preview in their
  feature; 4) the author writes the ViewModel test; 5) the screen gets a row in `docs/IA.md`.

Decisions and why:
- **One `NavigationStack` per tab** with a typed `[Route]` array (not `NavigationPath`,
  which hides its contents). Same as IcySky's router; Damus had to rework to this in
  Aug 2026 after a single shared path broke. (Confidence: high.)
- **Routes carry IDs only.** Each detail screen loads by ID and handles "not found"
  (Apple's Backyard Birds pattern). Damus shows the alternative going wrong: routes
  holding live objects and bindings. (Confidence: high.)
- **The Route → screen `switch` lives only in the App target.** That is how Discover
  opens a Hangout without importing the HangoutDetail feature. (Ice Cubes, IcySky.)
- **Deep links** (vybe://hangout/<id>) arrive in **Phase 2** (registering a URL scheme is a
  project setting; Phase 1 shares plain text). Policy when a link arrives:

  | App state | What happens |
  |---|---|
  | onboarding not finished | queue the link until onboarding is done |
  | live cover up | banner "End your Hangout first"; ignore the link |
  | editor cover up | ask to discard the draft first |
  | a sheet is up | dismiss it, then continue |
  | otherwise | `router.show(.hangout(id), in: router.selectedTab)` |

  Every ID in a link is validated. Universal links (Apple's recommendation) need a website,
  an entitlement and the paid Apple account.
- **`Router.selectedTab` must always be a visible tab.** With the iOS 27 SDK, a TabView
  may crash if its selection is a hidden or unavailable tab (iOS 27 release notes,
  **checked**). `TabView(selection:)` uses `Tab(..., value: AppTab.x)`; `TabShell` reads
  `lastNonSearchTab` for Search ranking.
- Never call `canOpenURL` (deprecated in iOS 27): call `openURL` and handle failure.

### 2.7 Dependency injection, fakes and previews
With MVVM, dependencies flow through `init`s, which makes them explicit and testable.
- `VybeApp` creates one `AppDependencies` (App target) holding the repositories
  (`hangouts`, `places`, `library`, `search`, `profile`, `photos`, ...), the stores and the
  `Router` (local data in Phase 1, remote in Phase 2).
- `ScreenFactory` (App target) has three builders: `screen(for: Route)`,
  `sheet(for: Sheet)` and `cover(for: Cover)`. Each builds the ViewModel with exactly what
  it needs and passes it to the View. Views never fetch dependencies themselves.
- **F0 puts a stub case (`Text("HD1")`) for every Phase 1 route.** A screen's author
  replaces only their own case; the `switch` stays Lohitaksh's.

```swift
// App target only
@ViewBuilder func screen(for route: Route) -> some View {
    switch route {
    case .hangout(let id):
        HangoutDetailView(viewModel: HangoutDetailViewModel(
            id: id, hangouts: deps.hangouts, places: deps.places, library: deps.library,
            liveStore: deps.liveStore, router: deps.router))
    // ...one case per Route
    }
}
@ViewBuilder func sheet(for sheet: Sheet) -> some View {
    switch sheet {
    case .spot(let id):
        SpotSheetView(viewModel: SpotSheetViewModel(id: id, places: deps.places, router: deps.router))
    // ...
    }
}
```
- **Isolation rule** (verified by compiling): UI targets default to MainActor, so in Core
  every **repository protocol**, every function in `Rules/` and everything `LocalData` or
  `Remote` implements or calls must be written `nonisolated`, for example
  `public nonisolated protocol HangoutRepository: Sendable` and
  `public nonisolated static func isValid(...)`. Otherwise `LocalData` fails to compile and
  JSON loading silently runs on the main thread.
- **Fakes and previews:** `Core/Fakes/` holds `nonisolated` stubs
  (`StubHangoutRepository(result:)` with loaded, empty, failing and never-returning modes).
  Each screen's `+Preview.swift` (wrapped in `#if DEBUG`) builds the **real** ViewModel on
  the stubs: `HangoutDetailViewModel.preview(.loaded)`, `.preview(.empty)`, `.preview(.failed)`.
  Previews and ViewModel tests share the same stubs. No Environment setup is needed, so
  previews can't crash from a missing object.

## 3. Modules: how the folders enforce the rules

Recommended: **one local Swift package `VybeKit` with several targets.** A target is a
mini-project that must list which other targets it may use, so Swift's compiler
enforces "features never import each other". That matters most for AI tools, which
otherwise import whatever is nearby.

```
VybeKit/Package.swift      (only Lohitaksh edits this)
VybeKit/Sources/
  Models/        no dependencies; Sendable structs; LoadState, Page, AppError; sample data
  Core/          uses Models
  Design/        uses Models (tokens, buttons, chips, LoadStateView)
  Components/    uses Models + Design (HangoutCard, SpotRow, PlaceImage, Avatar)
  LocalData/     uses Core (bundle JSON, saved items on the phone)
  OnboardingFeature/ DiscoverFeature/ HangoutDetailFeature/ LiveFeature/
  SearchFeature/ ProfileFeature/ CommunityFeature/
                 each uses Models, Core, Design, Components
  (Phase 2: EditorFeature, PostingFeature, FriendsFeature, ChatFeature,
   ModerationFeature, Remote)
VybeKit/Tests/   ModelsTests (content test), CoreTests (router, rules), LocalDataTests
Vybe/            app target: VybeApp, tabs, Route → screen map, store setup
```

Choices and evidence:
- **One package with many targets**, not many packages. Point-Free's isowords and
  Majid both recommend this for small teams. (Confidence: high.)
- **All 13 feature targets exist from day one** (empty, with a README each), because the whole
  frontend is built on sample data now; only `Remote` waits for the backend. Empty targets cost
  nothing to compile.
- **Known costs:** `public` everywhere (2.1), resources need `Bundle.module`, and
  `Package.swift` becomes a shared file (one owner).
- **Risk (real, checked):** SwiftUI previews inside local packages broke in **Xcode 26.4**
  ("Could not find target description"). Apple said 26.5 beta 1 should fix it, but users
  still reported it on 26.6 (Apple Developer Forums thread 820802). Nobody has reported on
  Xcode 27.1 yet. **We test this in the first hour of F0, with a 60-minute limit.** Things
  to try first: keep each target's name equal to its library product name (the only
  workaround seen in the thread), build the package scheme once, accept any "trust macro"
  prompts. If previews still fail, fall back to same-named folders inside the app target
  (the Element X / Landmarks / Damus shape) and enforce the import rule by review.
  (Confidence: medium; this is mentor question 1.)

### 3.1 Concurrency settings must match (a real bug we found)
The app target uses Swift 5 mode with "default MainActor" and "approachable
concurrency". A Swift package **does not inherit** those settings, so the same code
could compile in the app and fail in the package, which would confuse AI agents badly.
Fix, in `Package.swift` (swift-tools-version 6.2 or newer):
- Screen, Core, Design, Components and feature targets:
  `.defaultIsolation(MainActor.self)` plus the same upcoming features the app uses.
- Models and LocalData stay non-isolated, with `Sendable` types (Apple and SE-0470:
  otherwise `Codable` conformances become main-actor-only). Inside Core, repository
  protocols and everything in `Rules/` must be written `nonisolated` (see 2.7).
- **Language mode: `swiftLanguageModes: [.v5]`** on the package, to match the app
  (`SWIFT_VERSION = 5.0`). Without it, `swift-tools-version: 6.2` turns on Swift 6 mode
  for every target, and ordinary code such as a global `var` stops compiling (verified).
  Moving the app and package to Swift 6 mode together is a mentor question.
(Confidence: high; checked in our project file and Swift Evolution SE-0466 and SE-0470.)
- `Package.swift` must say `platforms: [.iOS(.v26)]` explicitly; never rely on the default.

### 3.2 Full application folder structure (the map every teammate and AI tool follows)

`●` = the folder/file exists in the committed skeleton (empty folders hold a `.gitkeep`; every module has a
`README.md`). `○` = created later by a task (Remote, backend, deep links, UI tests, CI workflows).
`★` = Lohitaksh only (`Package.swift`, `Vybe.xcodeproj`, signing; see `docs/START-HERE.md` section 2).

```
MIT-IOS-COHORT26-4/                          repo root
├── .github/                                 ○ CODEOWNERS, pull_request_template.md,
│   ├── ISSUE_TEMPLATE/ (story.md, bug.md)     workflows/ (lint.yml, test.yml)
│   └── workflows/
├── AGENTS.md ● · CLAUDE.md ● (@AGENTS.md) · README.md ● · .gitignore ● · .swiftlint.yml ●
├── Local.xcconfig.example ●                 template; the real Local.xcconfig is git-ignored (signing)
├── docs/ ●                                  PRODUCT, IA, ARCHITECTURE, DATA-MODEL, MOTION, PROCESS,
│                                            RISKS, PLAN, OPEN-QUESTIONS, prompts/, research/, adr/ ○
├── scripts/ ●                               check.sh (lint + tests); import_content.py (K1); ○ seed scripts
│
├── Vybe.xcodeproj ★ ●                       project settings: lead only
├── Vybe/                                    THE APP TARGET: wiring only, no screens
│   ├── VybeApp.swift ★                      @main; builds AppDependencies; one WindowGroup
│   ├── App/
│   │   ├── AppDependencies.swift ★          creates repositories, stores, router (local now, remote later)
│   │   ├── RootView.swift ★                 onboarding gate → TabShell; live-Hangout full-screen cover
│   │   ├── TabShell.swift ★                 TabView: Discover, Community, Profile, Search(role: .search)
│   │   ├── ScreenFactory.swift ★            Route → View: builds each ViewModel with its dependencies
│   │   └── DeepLinkHandler.swift ★ ○        Phase 2: vybe:// links → Route (needs a URL scheme: project setting)
│   └── Resources/
│       ├── Assets.xcassets                  AppIcon, AccentColor
│       ├── Localizable.xcstrings            tab titles and other app-level text
│       ├── PrivacyInfo.xcprivacy            privacy manifest (UserDefaults reason CA92.1)
│       └── Kothrud-Walk.gpx                 simulated walk for desk demos (scheme option)
├── VybeTests/ ●                             app-level smoke tests
├── VybeUITests/ ○                           one smoke test + performAccessibilityAudit()
│
├── VybeKit/                                 LOCAL SWIFT PACKAGE (add via Xcode: Add Package → Add Local)
│   ├── Package.swift ★                      platforms [.iOS(.v26)]; settings per target (section 3.1)
│   ├── Sources/
│   │   ├── Models/ ●                        no dependencies
│   │   │   ├── IDs.swift, Coordinate.swift, RupeeRange.swift, Photo.swift
│   │   │   ├── Place.swift, Spot.swift, Hangout.swift, HangoutRun.swift, Visit.swift
│   │   │   ├── UserProfile.swift ○, Comment.swift ○, Friendship.swift ○, Conversation.swift ○,
│   │   │   │   Message.swift ○, Report.swift ○, GuestResponse.swift ○
│   │   │   ├── State/                       LoadState.swift, Page.swift, AppError.swift (no UI)
│   │   │   └── Samples/SampleData.swift     preview data (clearly fake EXAMPLE values)
│   │   ├── Core/ ●                          uses Models
│   │   │   ├── Navigation/ ★                AppTab.swift, Route.swift, Cover.swift, Router.swift
│   │   │   ├── Repositories/                nonisolated protocols: HangoutRepository, PlaceRepository,
│   │   │   │                                LibraryRepository (Saved, Drafts, runs), ProfileRepository,
│   │   │   │                                SearchRepository, PhotoStore · ○ FeedRepository,
│   │   │   │                                FriendsRepository, ChatRepository, SafetyRepository (report,
│   │   │   │                                block), AuthRepository
│   │   │   ├── Fakes/ (#if DEBUG)           Stub*Repository for previews and ViewModel tests
│   │   │   ├── Stores/                      SessionStore, LibraryStore, LiveHangoutStore · ○ BadgeStore
│   │   │   ├── Services/                    AppSettings (UserDefaults wrapper), LocationService (protocol +
│   │   │   │                                Live + Simulated), NetworkMonitor
│   │   │   │                                · ○ PhotoProcessor, AudioRecorder
│   │   │   ├── Rules/                       HangoutRules.swift (2…10 Spots, 70% Remix credit, post eligibility,
│   │   │   │                                photo limit, post delay): pure functions, heavily tested
│   │   │   └── Logging/Log.swift            os.Logger helpers
│   │   ├── Design/ ●                        uses Models
│   │   │   ├── Theme/ ★                     Theme.swift, Colors.swift, Typography.swift, Spacing.swift, Motion.swift
│   │   │   ├── ImageLoader.swift            actor with an NSCache; Components may import Design but not Core
│   │   │   ├── Views/                       LoadStateView, PrimaryButton, SecondaryButton, FilterChip,
│   │   │   │                                EmptyStateView, OfflineBanner
│   │   │   └── Resources/Colors.xcassets    colour sets used by Theme
│   │   ├── Components/ ●                    uses Models + Design: HangoutCard, SpotRow, PlaceImage,
│   │   │                                    Avatar, PickBadge (take plain values, no ViewModel)
│   │   ├── LocalData/ ●                     uses Core
│   │   │   ├── LocalHangoutRepository, LocalPlaceRepository, LocalLibraryRepository, LocalProfileRepository,
│   │   │   │   LocalSearchRepository, LocalPhotoStore (Bundle.module → URL), ContentLoader (public)
│   │   │   ├── LibraryFile.swift            library.json read/write (atomic, schemaVersion)
│   │   │   └── Resources/Content/           Places/ (place-*.json) · Hangouts/ (hangout-*.json) · Photos/
│   │   ├── <Name>Feature/                   one folder per feature: uses Models, Core, Design, Components
│   │   │   ├── <Screen>/<Screen>View.swift
│   │   │   ├── <Screen>/<Screen>ViewModel.swift
│   │   │   └── <Screen>/<Screen>+Preview.swift   .preview(.loaded / .empty / .failed)
│   │   │
│   │   │   ● OnboardingFeature   Welcome/ NameAndPhoto/ Interests/ Location/ · FindFriends/ (O1–O4, O5)
│   │   │   ● DiscoverFeature     Map/ (incl. PinClusterer) PinPreview/ Filters/        (D1–D3)
│   │   │   ● HangoutDetailFeature Detail/ SpotSheet/ · RemixTree/                    (HD1–HD2, HD3)
│   │   │   ● LiveFeature         Live/ MarkVisited/ Summary/ · MiniBar/              (H1–H3, H4)
│   │   │   ● SearchFeature       Search/ · SeeAll/                                   (S1, S2)
│   │   │   ● ProfileFeature      Profile/ Saved/ Drafts/ Settings/                     (PR1, PR2, PR4, PR5 list)
│   │   │   ●                     EditProfile/ ReadyToPost/ SettingsPages/ DeleteAccount/ (PR6, PR8, ST1–ST8)
│   │   │   ● CommunityFeature    Feed/ (placeholder) · PostDetail/ Comments/ Trending/ Activity/  (CM1–CM5)
│   │   │   ● EditorFeature       Editor/ AddSpot/ SuggestPlace/ (Drafts list stays in ProfileFeature)  (E1–E3)
│   │   │   ● PostingFeature      Composer/ EditPost/                                   (PO1–PO2)
│   │   │   ● FriendsFeature      Hub/ OtherProfile/ MutualFriends/                     (FR1, PR3, PR7)
│   │   │   ● ChatFeature         List/ Conversation/ NewChat/ GroupInfo/ Invitation/ Poll/ ShareSheet/  (CH1–CH7)
│   │   │   ● AuthFeature         SignIn/ EmailCode/ AccountBasics/                     (A1–A3)
│   │   │   ● ModerationFeature   Report/ BlockConfirm/ Admin/ (Reports, Suggestions, Users)  (R1–R2, AD1–AD3)
│   │   └── Remote/ ○                        uses Core; the ONLY target allowed to import the backend SDK
│   └── Tests/
│       ├── ContentTests/ ●                  content test: every JSON file loads and passes HangoutRules
│       ├── CoreTests/ ●                     Router, deep links, HangoutRules, LoadState
│       ├── LocalDataTests/ ●
│       └── <Name>FeatureTests/ ●            one ViewModel test file per screen
│
└── backend/ ○                               Phase 2, outside the app
    ├── firebase.json, firestore.rules, storage.rules, firestore.indexes.json
    ├── functions/                           TypeScript server code (feeds, counters, deletion, push)
    ├── web/                                 WEB1 share pages (Firebase Hosting + a rendering function)
    └── rules-tests/                         unit tests for the security rules (run in CI)
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
| `Remote` | Core (+ the backend SDK) |
| App target (`Vybe/`) | everything |

**File rules**
- One screen = one folder = `SomethingView.swift` + `SomethingViewModel.swift` +
  `Something+Preview.swift` (sample ViewModels for the loaded, empty and failed previews).
  The ViewModel test lives in `Tests/<Name>FeatureTests/SomethingViewModelTests.swift`.
- Models, Route, Router, Theme, `Package.swift`, `ScreenFactory.swift`: Lohitaksh only.
  All Phase 1 `Route` cases are declared in F0, so nobody else needs to touch them.
- Every type used across targets is `public` with an explicit `public init`.

**Where does X go?** (for people and AI tools)

| I am adding… | It goes in… |
|---|---|
| a screen | its `<Name>Feature/<Screen>/` folder (View + ViewModel + Preview) |
| a view used by two features | `Components` (plain values, no ViewModel) |
| a colour, font size, spacing, animation timing | `Design/Theme` (ask Lohitaksh) |
| a data struct | `Models` (ask Lohitaksh) |
| "what the app can ask for" (e.g. Hangouts near me) | a protocol in `Core/Repositories`; implementations in `LocalData` (now) / `Remote` (later) |
| a rule such as "2 to 10 Spots" | `Core/Rules` as a pure function with tests |
| state that two tabs share | a store in `Core/Stores` (ask first) |
| text shown to people | a `String(localized:)` in the screen's ViewModel |
| a new permission or capability | stop and ask Lohitaksh |

**Package details to verify in the first-hour spike of F0** (cheap to fix now):
1. SwiftUI previews work for a feature target that depends on Core, Design and Components.
2. Asset catalogs and String Catalogs inside a package resolve: colours need `bundle: .module`,
   and `String(localized:)` in a package needs `bundle: .module` too. Decide whether each
   target owns its own `Localizable.xcstrings` (proposal: yes, plus shared words in `Design`).
3. `Bundle.module` finds `Content/` (JSON and photos use a folder copy so subfolders survive).
4. The synchronized-folder feature of the app target still picks up new files in `Vybe/`.

The real file is `VybeKit/Package.swift` (it also declares a test target for every module); the sketch
below only shows the pattern.

```swift
// VybeKit/Package.swift (sketch)
// swift-tools-version: 6.2
import PackageDescription
let ui: [SwiftSetting] = [.defaultIsolation(MainActor.self),
                          .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                          .enableUpcomingFeature("InferIsolatedConformances")]
let package = Package(
    name: "VybeKit",
    platforms: [.iOS(.v26)],
    products: [ .library(name: "Models", targets: ["Models"]), /* every target the App imports needs a .library */ ],
    targets: [
        .target(name: "Models"),                                   // non-isolated, Sendable
        .target(name: "Core", dependencies: ["Models"], swiftSettings: ui),
        .target(name: "Design", dependencies: ["Models"], resources: [.process("Resources")], swiftSettings: ui),
        .target(name: "Components", dependencies: ["Models", "Design"], swiftSettings: ui),
        .target(name: "LocalData", dependencies: ["Core"], resources: [.copy("Resources/Content")]),
        .target(name: "DiscoverFeature",
                dependencies: ["Models", "Core", "Design", "Components"], swiftSettings: ui),
        // …one per feature
        .testTarget(name: "ContentTests", dependencies: ["Models", "Core", "LocalData"]),
    ],
    swiftLanguageModes: [.v5])      // match the app target (SWIFT_VERSION = 5.0)
```

## 4. Apple platform decisions (from Apple's docs)

| Area | Decision | Why |
|---|---|---|
| Tabs | 4 tabs: Discover, Community, Profile, then Search as `Tab(role: .search)` at the trailing end (never in the middle); `.searchable(text: $viewModel.query)` inside `SearchView` on the search tab's NavigationStack (**not** on the TabView root: forum reports say it attaches to the first stack and glitches pushed screens); `SearchViewModel` reads `router.lastNonSearchTab` when a query runs, not in `init` | Apple's way; on iOS 26+ (our minimum) Search is drawn apart and morphs into the search field |
| iOS 26 features (allowed) | `tabBarMinimizeBehavior`, `tabViewSearchActivation`, `tabViewBottomAccessory` (the live Hangout mini-bar), `glassEffect` on floating map controls, `Observations`, drawn-on symbol effects | our minimum is iOS 26, so no `#available` needed |
| Tabs never hidden | Community shows an explained empty state | HIG |
| Map pins | `Marker` / `Annotation`, `Map(selection:)` | iOS 17+ |
| Route line | `MKDirections` (walking) only when the live screen opens; cache it; straight-line `MapPolyline` fallback if throttled | Apple docs warn about throttling |
| Look Around | **Not used** | Not available in India (Apple feature availability page, checked) |
| Apple place details | Store `applePlaceID`; fetch live with `MKMapItemRequest`; show with `mapItemDetailSheet` | Apple's Landmarks sample does exactly this; storing MapKit data is not allowed |
| MapKit item creation | Use the iOS 26 APIs: `MKMapItem(location:address:)`, `MKAddress`. **Do not use** `MKMapItem(placemark:)` (deprecated in iOS 26) | AI tools trained on older code will suggest the old one |
| iOS 27-only SwiftUI APIs | Avoid: `Tab(role: .prominent)`, `swipeActionsContainer`, `reorderable`, `toolbarMinimizationBehavior`, `topBarPinnedTrailing` (or guard with `#available(iOS 27, *)`) | below our minimum + 1 |
| Pin clustering | SwiftUI `Map` can't cluster (Apple engineer, Developer Forums, **checked**). Version 1: our own grid clustering in the Discover ViewModel (it works with `Coordinate` and a zoom span; the View converts to `MapCameraPosition`, which needs SwiftUI), recomputed on camera change, plus filter chips and one pin per Hangout; wrap `MKMapView` only if that is too slow on the lab iPhone | no clustering API in SwiftUI |
| Confirmations | `alert(_:item:)` / `confirmationDialog(_:item:)` | back-deployed to iOS 15 |
| Images in the feed | the phone uploads two sizes (~1600 px and ~400 px); `URLCache` set to ~50 MB memory / 200 MB disk at launch; one small `ImageLoader` for the feed | no server image step needed; `AsyncImage` caching is only documented from iOS 27 |
| Voice notes | AAC mono 32 kbps (~240 KB per minute), max 2 minutes | arithmetic from the bitrate |
| Map legal | Keep the Apple Maps logo and Legal link visible (`safeAreaInset`) | WWDC23 MapKit session |
| Pin preview | Card overlay on the map (keeps tab bar), not a sheet | a sheet covers the tab bar |
| Live Hangout | `fullScreenCover` | HIG: long tasks go full-screen |
| Photos | `PhotosPicker` (no permission prompt); downsample and re-encode with ImageIO **without metadata**, which removes GPS location | Apple ImageIO docs; GPS-only removal flag misses some hidden metadata |
| Feed (Phase 2) | `ScrollView` + `LazyVStack`, small model per card, downsampled images; measure on a real device | WWDC25 performance guidance |

## 4a. Apple fundamentals (audit of what we were missing)

| # | Area | Rule | When |
|---|---|---|---|
| 1 | **Location permission text** | `NSLocationWhenInUseUsageDescription` must exist or the O4 prompt never appears (project setting: lead's OK) | Phase 1 |
| 2 | **Live Hangout survives the app being closed** | save the run to disk on every change; time is worked out from `startedAt` (`Text(start, style: .timer)`), never a running timer; restore on launch | Phase 1 |
| 3 | **Dynamic Type** | Theme fonts are text styles (`.title`, `.body`) or `relativeTo:`; never `.system(size:)`; spacing that grows with text uses `@ScaledMetric`; one preview at a large text size | Phase 1 |
| 4 | **VoiceOver and touch** | every icon-only button, map pin and meaningful photo has an `accessibilityLabel`; decorative images hidden; tap targets at least 44×44 pt; never colour alone for state | Phase 1 |
| 5 | **Text and numbers** | ViewModels give text as `String(localized:)` / `LocalizedStringResource` (Foundation, so no SwiftUI import); money, distance, time with `.formatted(...)` (₹, km); plurals in one `Localizable.xcstrings` String Catalog | Phase 1 |
| 6 | **Logging** | `os.Logger` per feature, never `print`; no names, coordinates or tokens in logs without `privacy: .private` | Phase 1 |
| 7 | **Design system the Apple way** | colours are Asset Catalog colour sets used through Theme (no hex in Swift); icons are SF Symbols; only system bars, tabs and sheets with no custom backgrounds (they get Liquid Glass on iOS 26+ automatically) | Phase 1 |
| 8 | **Modern location code** | only through Core's `LocationService`, using `CLLocationUpdate.liveUpdates` (iOS 17) and `CLServiceSession` (iOS 18); no old delegate code; **never ask for "Always"** | Phase 1 |
| 9 | **Simulated walk** | a committed Kothrud `.gpx` route used by the Xcode scheme | Phase 1 |
| 10 | **Live Hangout with the phone locked** | today it would stop: Apple's WWDC24 location session says a When-In-Use app in the background gets no updates without a background session or Live Activity. Fix: Background Modes → Location updates (**approved 3 Nov**) + a `CLBackgroundActivitySession` kept alive while the Hangout is live | **Phase 1** |
| 11 | Other permission texts | camera, microphone (voice notes) | Phase 2 |
| 12 | Accessibility audit test | one UI test calling `performAccessibilityAudit()` (iOS 17) | Phase 2 |
| 13 | Security | tokens only in the Keychain (the backend SDK does this); never add App Transport Security exceptions | Phase 2 |
| 14 | Notifications | ask at the first friend request or chat, not at sign-up | Phase 2 |
| 15 | Sharing | Phase 1: `ShareLink` with plain text (title + "Find it on Vybe"); Phase 2: the web link (WEB1) and `vybe://` deep links | Phase 1 / 2 |
| 16 | Live Activity on the lock screen | Apple's preferred way to show a live Hangout | Phase 2 / later |
| 17 | Diagnostics | Xcode Organizer crashes; Instruments (SwiftUI instrument) on the lab iPhone | Phase 2 |
| 18 | App Store | privacy labels; Accessibility Nutrition Labels (voluntary for now; we can never claim "Dark Interface"); age-rating answers incl. Social Media and Shared Location (due 12 Jan 2027); iPhone Duo screenshots and iOS 27 SDK from April 2027; keep the generated launch screen (required with the iOS 27 SDK). Details in `docs/RISKS.md` | before submission |
| 19 | **Resizable iPhone apps** | iOS 27 lets iPhone apps be resized (iPhone Mirroring, iPad, the new iPhone Duo). "Portrait only" is not a guarantee: no fixed widths, never `UIScreen.main.bounds`; check in Xcode 27's Resizable Canvas | Phase 1 |
| 20 | **Liquid Glass tint slider** (iOS 27) | never add `UIDesignRequiresCompatibility`; check key screens with the system tint setting at both ends | Phase 1 |
| 21 | **Search on the phone** | Hangouts and Places (under 1 MB) are searched on the phone; people are searched by username prefix on the server | Phase 1 (Hangouts, Places) / 2 (people) |

Motion rules and tokens are in `docs/MOTION.md`. Storage and the data model are in
`docs/DATA-MODEL.md` (summary: **no database on the phone**; JSON files in Phase 1;
the backend SDK's cache in Phase 2).

## 4b. Web share page for Android friends (WEB1, version 1)
Decided 3 Nov. iOS is about 5% of phones in India, so every shared Hangout and post gets
a public web page.
- **Shape:** `https://<project>.web.app/h/<id>` (Hangout) and `/p/<id>` (post). A
  Firebase Hosting rewrite sends the request to a small function that returns **plain HTML
  rendered on the server** with `og:title`, `og:description` and `og:image` (WhatsApp's
  crawler reads those tags and does not run JavaScript). Cover image about 1200×630,
  under 300 KB. Content: cover photo, title, "3 Spots, ₹150 to 400", the Spots list, an
  "I'm in" button and "Get Vybe on iPhone".
- **Privacy:** only **Public** posts and Picks show content. A Friends-only post shows
  "Ask your friend to invite you" and nothing else. No exact times, no live location.
- **"I'm in" without an account:** the guest types a name; the function stores a
  `GuestResponse` (rate-limited, with a simple abuse check). Guests never appear in friend
  lists or chats; the host sees "2 friends said I'm in" on their post.
- **Opening the app from the link** (universal links) needs the Associated Domains
  capability and the paid Apple account, so it arrives with TestFlight. Before that the
  iOS share link opens the web page. There is no deferred deep linking (Firebase Dynamic
  Links shut down in Aug 2025).
- **Owner:** the "server owner" teammate; code lives in `backend/web/`. If the backend
  becomes Supabase, this needs a separate static host (its functions can't serve HTML).

## 5. Testing (that beginners will actually keep doing)

Swift Testing (`@Test`, `#expect`), built into Xcode.
1. **Content test:** every JSON file loads and passes rules (IDs unique, 2 to 10 Spots, coordinates in Pune).
2. **Rule tests:** 70% Remix credit, at least 2 visited Spots to post, max photos 2 × Spots.
3. **ViewModel tests** (the main benefit of MVVM): create the ViewModel with fake
   repositories, call `load()` or a tap method, check `state` and the router. Plus
   store tests. Mark them `@MainActor`.
4. **Router and deep-link tests** (copy Ice Cubes' `RouterTests`).
5. **Three previews per screen:** loaded, empty, error.
6. At most one UI smoke test.
Donny Wals (2026): the test suite is the "contract" AI agents must satisfy.

## 6. Keeping four people and their AI tools consistent

| Guardrail | What |
|---|---|
| Golden example | One complete feature built by hand first (HangoutDetail), with a copy-me template |
| Screen recipe in `AGENTS.md` | folder, `SomethingView` + `SomethingViewModel`, LoadStateView, Theme tokens, router calls from the ViewModel, three previews, a ViewModel test, `check.sh` |
| SwiftLint custom rules | ban hard-coded colours (`Color(red:`), `.foregroundColor(`, `NavigationLink(destination:`, `ObservableObject`, and banned words (Plan, Trace, Stop, Node, outing, Fork, Organiser) **only inside string literals and type, case and file names, with word boundaries** (so `.sensoryFeedback(.stop)` and Apple API names are fine) |
| iOS 26 rule | "Use iOS 26 APIs only; iOS 27-only ones inside `if #available(iOS 27, *)`" stated in `AGENTS.md` |
| Shared files | `VybeKit/Package.swift`, `Vybe.xcodeproj` and signing: Lohitaksh only. `Route`/`Router`, Theme tokens and `ScreenFactory` are created once by their tasks (F-4, DS-1, F-9); after that a screen's author replaces only their own `ScreenFactory` case, and Theme changes go through a PR to Lohitaksh |
| Short `AGENTS.md` | Anthropic's guidance: keep it short; hard rules belong in tools (lint, CI, hooks), not paragraphs |
| Claude Code settings (optional, needs the lead's OK) | deny edits to `*.pbxproj`, `Local.xcconfig`, signing; run `check.sh` automatically at the end of a task |
| CI | `check.sh` on every PR (see section 7) |

## 7. Team process (checked)

- **Git:** trunk-based with short branches (under a day), small PRs, squash merge. This
  is what DORA and trunkbaseddevelopment.com recommend. GitFlow would be overkill.
- **Branch protection:** on GitHub's free plan, protected branches and required reviews
  for **private** repositories are not included (they are under GitHub Pro and Team).
  Options: (a) ask MIT faculty to request GitHub Team via GitHub Education,
  (b) pay for Team (about $4 per user per month), (c) make the repo public,
  (d) rely on the team rule plus local checks. Mentor question.
- **CI:** GitHub Actions macOS minutes on a private repo cost roughly 10× Linux; the free
  allowance covers only a few full test runs per month. Plan: SwiftLint on a Linux
  runner for every PR; Xcode build and tests on macOS only when a PR is marked ready.
  Xcode Cloud (25 hours per month included) becomes available once the Apple
  Developer Program is bought.
- **What works before buying the account (free "Personal Team")**: reported (by a
  research agent reading Apple's capability table, which I could not re-read myself:
  **UNVERIFIED**) that push notifications, Sign in with Apple, Associated Domains
  (universal links), App Attest and iCloud are NOT available, and that App Groups and
  Keychain sharing are. **Background location:** an Apple engineer says the `location`
  background mode is just the `UIBackgroundModes` Info.plist key and "does not require any
  specific entitlement" (Developer Forums, **checked**), so it very likely works on a free
  account, but test it on the lab iPhone on Fri 6 Nov to be sure. Free builds expire after
  7 days; up to 3 devices and 3 apps per device (forum-sourced).
- **Xcode 27 agents** (Claude Agent, Codex, Gemini are built in): use plan mode, turn on
  the file-access security layer, never use "allow all" options, and don't convert the
  project to the new `.xcproj` format without the lead's OK. Check in F0 whether Xcode's
  built-in agent reads our `AGENTS.md` / `CLAUDE.md`.
- **Apple Developer Program:** buy on **16 Nov**, not 18 Dec (push notifications, Sign in
  with Apple and TestFlight need it). An individual account shows the person's legal
  name as the seller; an organisation needs a registered company and a D-U-N-S number.
- **Privacy manifest:** add `PrivacyInfo.xcprivacy` early (`@AppStorage`/UserDefaults
  is a "required reason" API, reason CA92.1).
- **TestFlight:** first external build goes through Beta App Review. Privacy policy is
  required for the App Store; whether external TestFlight needs it is unclear.

## 8. Backend (Phase 2), not decided

| Criterion | Firebase | Supabase |
|---|---|---|
| Beginner-friendly iOS SDK | good | fair |
| Offline read-only cache | built in (on by default on iOS) | build our own |
| Push notifications | built in (FCM) | build our own (webhook + function) |
| Friends, privacy, blocking rules | harder (no joins, copied data) | natural (SQL + row-level security) |
| Real-time chat | good | good |
| Storage for photos and voice notes | **needs the paid Blaze plan since 3 Feb 2026** (checked) | 1 GB free |
| Cost control | budget alerts only, no hard cap on Firestore/Storage | free tier pauses after 7 days idle |
| India reliability | Mumbai and Delhi regions | Mumbai region; **blocked by some Indian ISPs 24 Feb to 3 Mar 2026** (checked) |
| Lock-in | higher | lower (open source) |
| Requirements | SDK 13.x needs **Xcode 26.2+** (checked; our Xcode 27.1 is fine) | supabase-swift needs Swift 6.2, Xcode 26+ |

More capability rows (added 3 Nov after a second round of research):

| Criterion | Firebase | Supabase |
|---|---|---|
| Search later, at scale | new Enterprise text search (no offline; edition can't be changed after the database is created) or a paid search service | free built-in full-text and fuzzy search |
| People search hiding blocked users | prefix query; block filtering on the phone | prefix query + row-level security |
| "Near me" later | geohash code by hand; Enterprise geo is preview | PostGIS (official map-area example) |
| Link preview pages for WhatsApp | Hosting + a function in one place | Edge Functions can't serve web pages without a paid custom domain |
| Admin tools | console + roles + a hidden admin section in the app | Studio table editor + roles in row-level security + in-app admin |
| Server code | about 8 to 10 TypeScript functions | about 2 or 3 functions + SQL triggers |
| Extensions | **Firebase Extensions shut down 31 Mar 2027** (**checked**): don't depend on them | n/a |

Version 1 plan that works with either backend:
- search Hangouts and Places on the phone; "near me" filtered on the phone;
- photo sizes made on the phone;
- web preview pages for shared Hangouts on Firebase Hosting (free `*.web.app` domain);
  universal links need the paid Apple account;
- admin = Places and Picks as JSON in git with an import script, plus a hidden admin
  section in Settings for reports, suggestions and bans (enforced by server rules);
- one "server owner" on the team; every function or trigger tested in the local
  emulator first. Firebase Dynamic Links shut down in Aug 2025, so no deferred deep links.

Current lean: **Firebase**, because offline caching and push are built in and it avoids
the India block risk. The data model and security rules must be designed up front.
Either way, the "no third-party libraries" rule needs one exception for the backend SDK
(and possibly Google Sign-In). Plan: a one-day test of both on 16 to 17 Nov.

## 9. What we are deliberately NOT doing (and why)

| Not doing | Why |
|---|---|
| TCA (The Composable Architecture) | a third-party library; Point-Free itself does not recommend it for people learning SwiftUI |
| Clean Architecture / VIPER | too much ceremony for about 40 screens and 6 weeks |
| Logic or data loading inside Views | MVVM: Views only lay out; all logic lives in the ViewModel (2.4) |
| `NavigationPath` | type-erased; `[Route]` is simpler to test and deep-link |
| A global sheet for everything | only sheets that more than one feature opens are global (`spot`, `report`, `share`, ...); all others stay in their screen's ViewModel (2.6) |
| Many packages / Tuist / XcodeGen | synchronized folders already remove project-file conflicts |
| Snapshot tests | need a third-party library |
| Look Around | not available in India |

## 10. Risks

1. **Scope vs time.** About 4.5 weeks of Mac time (16 Nov to 18 Dec) for backend,
   accounts, friends, feed, comments, chat, moderation and TestFlight. Cut order:
   voice notes, polls, threaded replies, Remix credit on the map.
2. **Previews inside packages** may break (tested in hour one of F0, fallback ready).
3. **Shared files** (`Package.swift`, `Route`, the App's screen map, Theme) cause merge
   conflicts if several people edit them. One owner.
4. **AI tools using iOS 27-only APIs** on an iOS 26 app, or old deprecated ones (`NavigationView`, `ObservableObject`). Lint rules and review.
5. **Backend lock-in and cost surprises** (Firebase has no hard spending cap).

## 11. Questions for mentors (the hard ones)

### Architecture
1. One package with a target per feature (compiler-enforced boundaries, but `public`
   everywhere and preview risk), or plain folders in the app target with lint rules?
2. Swift 6 language mode now, or Swift 5 mode until Phase 2?
3. MVVM with every ViewModel built in the App's Route → screen map: will that map get
   too big with 12 features, and is a small factory per feature better?
4. Is a central `Route` enum plus one Route → screen map going to become a bottleneck
   with 12 features and deep links?
5. Offline read-only cache: rely on the backend SDK's cache, or our own?

### Backend and data
6. Firebase vs Supabase for friends, a feed, threaded comments and chat, built by a
   beginner in about 4.5 weeks? Would you use a chat service (e.g. Stream) instead?
7. How do you build "friends first, then newest, plus trending" with paging and
   blocking, without slow or expensive reads?
8. Chat details: message order, read receipts in groups, edit and delete for everyone,
   sending on bad signal, voice-note storage and moderation.
9. Real costs for photos and voice notes at 1,000 and 10,000 users?
10. How did you enforce privacy (friends-only posts, private profiles, blocking) on the
    server so an app bug can't leak data?

### Legal and accounts
11. Who should legally publish the app: an individual Apple account (legal name shown,
    personal liability for user content) or a company?
12. India's IT Rules 2021 (grievance officer, 24-hour acknowledgement, 15-day
    resolution) and the DPDP Rules: what did you actually build to comply?
13. Email, Apple and Google sign-in without phone numbers: how bad were fake accounts?
14. Keeping posts as "[deleted]" after account deletion: did Apple accept it?

### Platform (added 3 Nov)
- **iOS 26 minimum was decided** (one design, no old-iOS branches, tab-bar accessory and
  Liquid Glass APIs). Cost: iPhone XS/XR and phones not updated to iOS 26 (about 21% of
  all iPhones in June 2026 per Apple; likely more in India) can't install. Is that
  acceptable for a student audience, and can the first-college survey confirm it?
- If Firebase: create the database as the Enterprise edition (for text and geo search
  later), knowing the choice is permanent and search queries don't work offline?
- Server-side photo screening (e.g. Google SafeSearch) in version 1, or reports plus a
  fast team response enough for Apple 1.2 and India's 2026 rules?
- Grid clustering we write ourselves, or wrapping `MKMapView`?

### Process
15. GitHub Team (paid or via GitHub Education), a public repo, or honour rules?
16. How do you review AI-written pull requests quickly without rubber-stamping them?
17. What got your social app rejected by App Review, and how long did external
    TestFlight review take?
18. Is 18 Dec realistic for this scope? What would you cut first?

## Sources

Open-source apps:
[Ice Cubes](https://github.com/Dimillian/IceCubesApp) ·
[Ice Cubes Router](https://github.com/Dimillian/IceCubesApp/blob/main/Packages/Env/Sources/Env/Router.swift) ·
[Ice Cubes Route → screen map](https://github.com/Dimillian/IceCubesApp/blob/main/IceCubesApp/App/Router/AppRegistry.swift) ·
[Ice Cubes loading/empty/error](https://github.com/Dimillian/IceCubesApp/blob/main/Packages/Conversations/Sources/Conversations/List/ConversationsListView.swift) ·
[Ice Cubes router tests](https://github.com/Dimillian/IceCubesApp/blob/main/Packages/Env/Tests/RouterTests.swift) ·
[IcySky](https://github.com/Dimillian/IcySky) ·
[AppRouter](https://github.com/Dimillian/AppRouter/blob/main/Sources/AppRouter/Router.swift) ·
[Element X](https://github.com/element-hq/element-x-ios) ·
[Damus router](https://github.com/damus-io/damus/blob/master/damus/Shared/Utilities/Router.swift) ·
[Damus per-tab stacks commit](https://github.com/damus-io/damus/commit/204c325) ·
[Backyard Birds](https://github.com/apple/sample-backyard-birds/blob/main/Multiplatform/Backyards/BackyardNavigationStack.swift) ·
[Food Truck](https://github.com/apple/sample-food-truck) ·
[Landmarks with Liquid Glass](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass) ·
[isowords](https://github.com/pointfreeco/isowords)

Apple:
[Managing model data](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app) ·
[NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack) ·
[Tab navigation](https://developer.apple.com/documentation/swiftui/enhancing-your-app-content-with-tab-navigation) ·
[PreviewModifier](https://developer.apple.com/documentation/swiftui/previewmodifier) ·
[MapKit for SwiftUI](https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui) ·
[MKMapItem.identifier](https://developer.apple.com/documentation/mapkit/mkmapitem/identifier-swift.property) ·
[ImageIO GPS metadata](https://developer.apple.com/documentation/imageio/kcgimagemetadatashouldexcludegps) ·
[Performant scrollable stacks](https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks) ·
[WWDC25 session 256](https://developer.apple.com/videos/play/wwdc2025/256/) ·
[WWDC25 session 306](https://developer.apple.com/videos/play/wwdc2025/306/) ·
[WWDC24 session 10097](https://developer.apple.com/videos/play/wwdc2024/10097/) ·
[WWDC23 session 10043](https://developer.apple.com/videos/play/wwdc2023/10043/) ·
[iOS feature availability](https://www.apple.com/ios/feature-availability/) ·
[Required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) ·
[TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview) ·
[Apple Developer enrollment](https://developer.apple.com/programs/enroll/)

Swift Evolution:
[SE-0466 default actor isolation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md) ·
[SE-0470 isolated conformances](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0470-isolated-conformances.md)

Expert writing:
[Ricouard: SwiftUI in 2025, forget MVVM](https://dimillian.medium.com/swiftui-in-2025-forget-mvvm-262ff2bbd2ed) ·
[SwiftLee: MVVM](https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/) ·
[Point-Free TCA FAQ](https://www.pointfree.co/blog/posts/141-composable-architecture-frequently-asked-questions) ·
[Majid: microapps scaling](https://swiftwithmajid.com/2025/05/27/microapps-architecture-in-swift-scaling/) ·
[Majid: @Entry](https://swiftwithmajid.com/2024/07/09/introducing-entry-macro-in-swiftui/) ·
[Nil Coalescing: initialising @Observable](https://nilcoalescing.com/blog/InitializingObservableClassesWithinTheSwiftUIHierarchy) ·
[Donny Wals: agentic iOS pipeline](https://www.donnywals.com/setting-up-a-delivery-pipeline-for-your-agentic-iOS-projects/) ·
[Hacking with Swift: SwiftUI agent skill](https://www.hackingwithswift.com/articles/282/swiftui-agent-skill-claude-codex-ai) ·
[isowords modularisation discussion](https://github.com/pointfreeco/isowords/discussions/115)

Process and backend:
[DORA trunk-based development](https://dora.dev/capabilities/trunk-based-development/) ·
[Short-lived branches](https://trunkbaseddevelopment.com/short-lived-feature-branches/) ·
[GitHub plans](https://docs.github.com/en/get-started/learning-about-github/githubs-plans) ·
[GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) ·
[Xcode Cloud](https://developer.apple.com/xcode-cloud/) ·
[agents.md](https://agents.md/) ·
[Claude Code best practices](https://code.claude.com/docs/en/best-practices) ·
[Firebase iOS release notes](https://firebase.google.com/support/release-notes/ios) ·
[Firebase Storage plan change](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024) ·
[Firestore offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline) ·
[Firestore locations](https://firebase.google.com/docs/firestore/locations) ·
[Supabase pricing](https://supabase.com/pricing) ·
[Supabase regional blocks](https://supabase.com/blog/navigating-regional-network-blocks) ·
[supabase-swift](https://github.com/supabase/supabase-swift)
