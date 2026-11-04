# Rules for every AI tool in this repo

Applies to every tool and every teammate.
- Product and scope: `docs/PRODUCT.md`. Screens and navigation: `docs/IA.md`.
- Code structure (MVVM): `docs/ARCHITECTURE.md`. Data and storage: `docs/DATA-MODEL.md`.
- Motion: `docs/MOTION.md`. How we work: `docs/PROCESS.md`. Schedule: `docs/PLAN.md`.
- Risks, safety and legal: `docs/RISKS.md`. Never weaken a safety default without a human.
- Before building: `docs/START-HERE.md` (reading list), `docs/TASKS.md` (the task pool),
  `docs/BEFORE-BUILD.md` (setup, risks). Later decisions: `docs/LATER.md`.
- Unanswered questions: `docs/OPEN-QUESTIONS.md`. If your task touches one, stop and ask a human.

## 1. Start of every task
Read `AGENTS.md`, `docs/START-HERE.md` and **your task in `docs/tasks/`** (the person gives you its
ID). Then **plan only, no code yet**. Wait for the human to say OK before writing or changing files.
Build exactly what the task says, in the folder it names, and nothing else.

## 2. Who you are helping
Four college students who are new to shipping code and rely heavily on AI.
- Explain in plain language. Explain any jargon once.
- Keep tasks small: one screen or one concern per change, about 300 lines.
- After writing code, explain it line by line in plain words.
- Never produce code the author could not explain. Never merge what a teammate cannot explain.
- If stuck for over 30 minutes, tell the human to ask a teammate or Lohitaksh.

## 3. Vocabulary (code, comments and UI text)
| Use | Never use |
|---|---|
| Hangout | Plan, Trace, outing |
| Spot | Stop, Node |
| Remix | Fork, Make it yours |
| Picks (official Vybe Hangouts) | Featured, Curated |
| Start Hangout (the main button) | Go, Begin |

- A **Hangout** is a multi-spot day out. The same word is used whether it is saved,
  being done live, or posted.
- A **Spot** is one place inside a Hangout. A **Place** is the real venue on the map
  (code-level word; a Spot points to a Place).
- No "Organiser" and no voting in Phase 1. Polls ("I'm in" / "Not for me") come later,
  inside group chats only, never inside a Hangout.

## 4. Ask first (never do these without a human saying yes)
- Change signing, project settings, targets, or the iOS minimum.
- Add a library. No third-party libraries at all.
- Edit files outside your task or outside your own `<Name>Feature/` folder.
- Push to main, force-push, or commit. Only commit when asked.
- Invent data. Places, coordinates, hours, prices and photos must be real.
- Copy data out of Apple Maps (MapKit) or Google Maps into our files. Their terms forbid
  storing it. Storing Apple's Place ID is allowed.

## 5. Architecture
- SwiftUI with `@Observable`. **iOS 26 minimum.** iPhone, portrait, light only.
- Xcode folders are synchronized: a new file inside `Vybe/` or `VybeTests/` is picked
  up automatically. Do not edit `Vybe.xcodeproj` or `project.pbxproj` by hand.
- Never touch signing settings or `Local.xcconfig` (per-machine, git-ignored).
- **MVVM.** Every screen is `SomethingView` + `SomethingViewModel`.
  - The View only lays things out and forwards taps to the ViewModel. No data loading,
    no business logic, no formatting in the View.
  - The ViewModel is `@MainActor @Observable final class`. It holds the screen's state
    (a `LoadState`), loads data through repositories, and has one method per user action
    (`startTapped()`). It does not import SwiftUI.
  - The App creates each ViewModel with its dependencies and passes it into the View's
    `init`. Load data in `.task`, never in `init`.
  - Shared components (HangoutCard, SpotRow) have no ViewModel; they take plain values.
- Tabs: Discover, Community, Profile, and Search as a separate search-role tab at the
  trailing end. Never put Search in the middle. Chat lives inside Community.
- Models are plain `Codable` structs with stable string IDs. IDs never change once set.
- Screens never open other screens directly. They ask the router for a `Route`
  (for example `.hangout(id)`), and routes carry IDs only.
- One `NavigationStack` per tab.
- Data reaches a screen only through its ViewModel, which gets repositories and stores
  through its `init`. Views never read files, the Environment for data, or a server.
- No database on the phone: JSON files, and `UserDefaults` through Core's `AppSettings` for
  small settings only (see `docs/DATA-MODEL.md`). `@AppStorage` is SwiftUI-only: not in Core
  or ViewModels. Never put personal data or tokens in `UserDefaults`.
- Import rules: Features never import each other, **`LocalData` or `Remote`**. Shared views go
  in `Components`. (Full list: `docs/ARCHITECTURE.md` 3.2.)
- In Core, repository protocols, `Rules/` functions and anything `LocalData` or `Remote` calls
  are written `nonisolated`. ViewModels never write `router.cover = …`; they call Router methods.
- A ViewModel exposes view-ready values (title text, `[SpotRowData]`), not raw models.
  Only `App` sees everything.
- All visual values (colour, font, spacing) come from `Theme` tokens.
  Do not hard-code them in views.

## 5a. Apple basics (every screen)
- **iOS 26 APIs are fine; no old-iOS branches.** `glassEffect`, `tabViewBottomAccessory`,
  `Observations` and `MKMapItem(location:address:)` are allowed. Anything iOS 27-only
  (`Tab(role: .prominent)`, `swipeActionsContainer`, `reorderable`,
  `toolbarMinimizationBehavior`, `topBarPinnedTrailing`) is avoided, or guarded with
  `#available(iOS 27, *)`. Never use deprecated APIs (`NavigationView`, `ObservableObject`,
  `MKMapItem(placemark:)`).
- **Layouts work at any width** (iOS 27 can resize iPhone apps): no fixed screen widths,
  never `UIScreen.main.bounds`.
- **Tabs:** the router's selected tab is always a visible tab (iOS 27 can crash otherwise).
- Never call `canOpenURL`; use `openURL` and handle failure.
- Never add `UIDesignRequiresCompatibility` (ignored with the iOS 27 SDK anyway).
- **Fonts:** Theme text styles only, never `.system(size:)`. Spacing that grows with
  text: `@ScaledMetric`.
- **Accessibility:** every icon-only button, map pin and photo has an
  `accessibilityLabel`; tap targets at least 44×44 pt; never colour alone for state.
- **Text:** ViewModels give display text as `String(localized:)` or
  `LocalizedStringResource`. Money, distance and time only with `.formatted(...)`
  (₹, km). Plurals in `Localizable.xcstrings`. Never type "Rs" or "km" by hand.
- **Icons:** SF Symbols. **Colours:** Asset Catalog colours through Theme, no hex.
- **System components only** for tab bar, navigation bars and sheets; no custom backgrounds.
- **Logging:** `os.Logger`, never `print`. No personal data in logs.
- **Location:** only through Core's `LocationService` (`CLLocationUpdate.liveUpdates`).
  Never ask for "Always" permission.
- **Motion:** system animations first; only `Theme.Motion` tokens; one hero moment per
  screen; respect Reduce Motion; haptics only with their Apple meaning
  (`docs/MOTION.md`).

## 6. Definition of done
- `./scripts/check.sh` passes (SwiftLint, then tests on an iPhone simulator).
  If it fails, say so and show the output. Never silence, skip or weaken a check.
- It builds and runs on the simulator.
- Every data screen has loading, empty and error states (plus a stale/offline state from Phase 2).
- It uses Theme tokens.
- It has `#Preview`s for loaded, empty and error (plus one at a large text size), using
  real Kothrud names, never lorem ipsum.
- It has a ViewModel test.
- The PR has the pasted `check.sh` output and a simulator screenshot next to the Figma
  frame (see `docs/PROCESS.md`).
- The author can explain every line.

## 7. Git
- Branch: `<initial>/<task-id>-<short-name>`, for example `t/sc-d1-discover-map`. Short-lived.
- Everything goes through a pull request. Squash-merge. Small PRs.
- PR title: `<task-id>: what it does`, for example `SC-D1: show pins on the map` (task IDs are in
  `docs/TASKS.md`; screen IDs like D1 are in `docs/IA.md`).
- PR description: how to test, a screenshot, which AI was used,
  and "In my own words" (3 to 5 sentences written by the author).

## 8. Safety
Never paste passwords, keys or personal data into any AI.

## 9. Scope (decided 3 Nov: build the whole frontend on sample data first, backend after)
- **Your task file is your scope.** Build what `docs/tasks/` says for your task ID, nothing more.
- **In scope now:** every screen with a task in `docs/TASKS.md`, including Community, Friends, Chat,
  Editor, Remix, Posting, Report and Settings. They run on the stub repositories and the sample
  data (F-5, F-7, F-8), never on a server.
- **Not yet (no task, backend phase):** real network calls, the `Remote` module, any server SDK,
  real sign-in and accounts, push notifications, deep links and URL schemes, universal links.
  Sign-in screens are built against stubs only.
- **Not in version 1:** Dynamic Island, Live Activity, turn-by-turn navigation, dark mode, iPad,
  landscape, multi-person live Hangouts.
- **"Phase 1 / Phase 2"** (in `docs/IA.md`, Route comments, `docs/DATA-MODEL.md`) means *build order
  only*. It never means "skip this" and never means "this week". Phase 1 = frontend on sample
  data, Phase 2 = backend swap and release. Everything ships in version 1 (18 Dec).
- If you are not sure whether something is in scope, stop and ask a human.
