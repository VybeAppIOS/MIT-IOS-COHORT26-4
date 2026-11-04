# Cross-cutting, content and project-setting tasks

Anyone can take these (except the ones marked *Lohitaksh only*, which change project settings or shared
files). They run in parallel with the screen work.

## Content (real data only: `AGENTS.md` section 4, `docs/PRODUCT.md` section 8)

### X-C1 — First sample data: 5 Places + 2 Hangouts (with photos)  `[M]`
- **Depends on:** nothing
- **Note:** blocks the content test in F-8.
- **Read:** DATA-MODEL 4 (the JSON shape) and 2 (IDs) · PRODUCT 8 (content rules) · RISKS 3 (no residential places)
- **Build:** by hand, **real Kothrud places** you have visited and checked on a map: 5 `Place` JSON files in
  `VybeKit/Sources/LocalData/Resources/Content/Places/` and 2 `Hangout` files (3 Spots each; **one Place in
  both**) in `…/Hangouts/`; photos you took, each with a written OK and a `credit`, resized to ~1600 px long
  side plus a 400 px thumbnail, **location data stripped**, in `…/Photos/`. IDs `place-<slug>-<4 chars>`,
  never changed. Do **not** copy data from Apple Maps or Google Maps; hours and cost come from visiting.
  Keep every bundled photo under about 300 KB (and the thumbnail much smaller) and at most 3 per Place: git never forgets
  a big file, and the full verified dataset will live in the backend, not in this repository.
  Use the author `user-vybe-team` and `isPick: true` for team Hangouts (they must be real past visits).
- **Done when:** the content test (F-8) passes; every photo has a credit.

### X-C2 — Content batch: +15 Places with photos  `[M]` *(repeatable)*
- **Depends on:** X-C1
- Same rules as X-C1. Aim for variety across the categories in `docs/OPEN-QUESTIONS.md` 4 (cafés, street
  food/chai, parks, viewpoints, gaming, a trek with `trekInfo` and safety note, a library/study spot).
  Include one `closedByAuthorities` example place for testing.

### X-C3 — Content batch: +10 Hangouts / Picks from real past visits  `[M]` *(repeatable)*
- **Depends on:** X-C1
- 2 to 6 Spots each from existing Places (budget range, time estimate, best time, tags like "good for
  groups"). Picks are posts by the official Vybe account made from **real past visits** (decided 3 Nov).
  Include a Remix example (`remixedFromID` + `remixedFromPlaceIDs`, ≥70% of Spots kept).

### X-C4 — Sheet → JSON script (K1)  `[M]`
- **Depends on:** X-C1
- **Read:** DATA-MODEL 4 · PROCESS 4
- **Build:** `scripts/import_content.py` (standard library only): a Google Sheet exported as CSV (tabs:
  Places, Hangouts) → the JSON files above; validates and fails loudly with the row number (IDs, 2…10 Spots,
  Pune bounds, photo files exist, credits present). Add a short "how to add a Place" guide in `docs/`.
- **Done when:** running it on the EXAMPLE rows produces files that pass the content test.

## Tooling and quality

### X-1 — SwiftLint custom rules  `[S]`
- **Depends on:** nothing
- **Read:** `docs/adr/006-guardrails-and-agent-loop.md` · ARCHITECTURE 6 · MOTION 3 (rule 8) · AGENTS 5 and 5a
- **Build in `.swiftlint.yml`** (custom rules, path-scoped with `included:`/`excluded:`) that fail on: `Color(red:`/hex colour
  literals outside `Design/Theme`; `.system(size:`; raw animation curves (`.easeInOut`, `.spring(` …) outside `Design/Theme`;
  bare `withAnimation {`; `ObservableObject`, `NavigationView`, `NavigationLink(destination:`; `print(`; `@AppStorage` outside the
  app target; `canOpenURL`; banned words (Plan, Trace, Stop, Node, outing, Fork, Organiser) **only inside string literals and
  type/case/file names**, with word boundaries; and the architecture rules of ADR 006 that a regex can see: `import SwiftUI` /
  `UIKit` / `MapKit` in `*ViewModel.swift`, `Models/`, `Core/`, `LocalData/`; `public ` in `*Feature/` outside
  `*Screens.swift`; `AppDependencies` outside `*Screens.swift`, `Core/` and `Vybe/`; `@MainActor` in `Core/` outside
  `Router`, `Stores/`, `NetworkMonitor`; `@unchecked Sendable`, `nonisolated(unsafe)` and `assumeIsolated` without a
  `// allowed: <reason>` comment on the same line.
- **Done when:** a deliberate violation of each rule is caught (keep the examples in a test file excluded from lint);
  `./scripts/check.sh` still green.

### X-2 — GitHub Actions: lint on every PR  `[S]`
- **Depends on:** nothing
- **Read:** PROCESS 2, ARCHITECTURE 7
- **Build:** `.github/workflows/lint.yml`: SwiftLint (`--strict`) on an Ubuntu runner using the
  `ghcr.io/realm/swiftlint` container on every pull request; a second workflow `test.yml` that runs
  `./scripts/check.sh` on macOS **only when the PR is marked ready for review**, cancels superseded runs and
  skips docs-only PRs. Pin the Xcode version (check the runner image first).
- **Done when:** both workflows run on a test PR. (Branch protection depends on the GitHub plan: not here.)

### X-3 — String Catalogs per module  `[M]`
- **Depends on:** F-0
- **Read:** ARCHITECTURE 3.2 ("Package details to verify" #2) · AGENTS 5a · F-0 proof (e)
- **Build:** use F-0's result to decide and document how `String(localized:)` finds strings in a **package**. Proposal: one
  `Localizable.xcstrings` **per target that shows text** (a single shared catalog is one big JSON file that Xcode rewrites, so
  every PR would conflict), with shared words in `Design`. Prove it with one string in `DiscoverFeature` and one in `Design`.
  Update the screen template with the exact call.
- **Done when:** a string added to the catalog appears at runtime; the template and AGENTS 5a say how.

### X-4 — Accessibility review (repeat per feature)  `[M]`
- **Depends on:** SC-HD1 (then repeat for each feature once its screens are merged)
- **Read:** AGENTS 5a · ARCHITECTURE 4a (#3, #4) · PROCESS 3
- **Build/Do:** per feature: VoiceOver walk-through (every control reachable, sensible order and labels),
  largest text size (`.accessibility3` and the real Settings extreme), Reduce Motion, Increase Contrast,
  44 pt targets, colour never the only signal; fix findings; record a short checklist in the PR.
- **Done when:** the checklist is ticked for that feature.

### X-5 — Golden example, template refresh and screen generator  `[M]`
- **Depends on:** SC-HD1 merged
- **Read:** `docs/adr/006-guardrails-and-agent-loop.md`
- **Build:** update `docs/templates/new-screen/README.md` and each feature folder's `README.md` to point to the real files of the
  first finished screen; write `scripts/new_screen.py <Feature> <Screen>` (standard library only) that copies SC-HD1's View,
  ViewModel, Preview and test into `VybeKit/Sources/<Feature>/<Screen>/`, renames the types, and prints the two lines the author
  still has to edit (the route case from F-4 and the `case` in `<Feature>Screens.swift`); write a 30-minute walk-through script
  for the team.
- **Done when:** running the generator for a dummy screen produces files that build and whose test passes; the dummy is deleted.

### X-6 — Create GitHub issues from the task files  `[S]`
- **Depends on:** nothing
- **Build:** `scripts/create_issues.py` that reads `docs/tasks/*.md` (the `### ID — Title` headings) and
  runs `gh issue create` with the task text as the body (**dry-run by default**; labels by area). Lohitaksh
  runs it once the team agrees.
- **Done when:** the dry run prints one issue per task with correct titles and dependency lines.

### X-7 — App icon and launch screen placeholder  `[S]`
- **Depends on:** nothing
- **Build:** a simple placeholder icon (1024 px, no text that might change with the name) in
  `Vybe/Assets.xcassets/AppIcon.appiconset`; the generated launch screen stays (required by the iOS 27 SDK). Final art
  waits for the app name.

### X-13 — Architecture check script  `[S]`
- **Depends on:** F-16
- **Read:** `docs/adr/006-guardrails-and-agent-loop.md` · ARCHITECTURE 3.2
- **Build:** `scripts/check_architecture.sh` (bash and grep only, so it also runs on the Linux lint runner) for the rules a lint
  regex cannot express: every `*Feature` has `<Name>Screens.swift`; every `FooViewModel.swift` has a `FooViewModelTests.swift`
  somewhere under `VybeKit/Tests/`; `RunTimes` appears only in Models, Core, LocalData, Remote, LiveFeature, PostingFeature and
  ProfileFeature; no feature's `Package.swift` dependency list names another feature, `LocalData` or `Remote`. Prints the file
  and line of each violation and exits non-zero. Call it from `scripts/check.sh` and from `.github/workflows/lint.yml` (X-2).
- **Done when:** a deliberate violation of each rule makes it fail; the real tree passes.

### X-14 — Agent loop: debug launch options and screenshot script  `[M]`
- **Depends on:** F-9, F-4
- **Read:** `docs/adr/006-guardrails-and-agent-loop.md`, `docs/adr/003-navigation.md`
- **Build (App target, `#if DEBUG` only):** launch options read from `UserDefaults` arguments: `-stubMode loaded|empty|failing|loading`
  (selects `AppDependencies.preview(_:)`-style stubs for the whole app), `-debugRoute <JSON of a Route, or a short form such as
  hangout/<id>>`, `-skipOnboarding`, `-resetState`, `-simulateWalk`. Then `scripts/snap.sh <name> <route> <mode>`: boots an iPhone
  simulator, installs and launches the app with those options, waits, saves `build/screenshots/<name>.png`. No personal data,
  nothing compiled into release builds.
- **Files:** `Vybe/App/LaunchOptions.swift`, `scripts/snap.sh`, a line in `.gitignore` for `build/`, a paragraph in `docs/PROCESS.md`
- **Done when:** one command opens the Hangout detail placeholder in each of the four stub modes and saves four screenshots; the
  options are absent from a Release build (check with `#if DEBUG`).

## Project settings and device checks (*Lohitaksh only*)

### X-9 — Permissions, capabilities, simulated walk, privacy manifest  `[S]`
- **Depends on:** F-0
- **Read:** ARCHITECTURE 4a #1, #10, #11, #18 · OPEN-QUESTIONS 8b · BEFORE-BUILD 4
- **Do (in Xcode, all project-setting changes):** add `NSLocationWhenInUseUsageDescription` (clear human
  wording), Background Modes › Location updates, `NSMicrophoneUsageDescription` and
  `NSCameraUsageDescription` when voice/camera arrive; add `Kothrud-Walk.gpx` and select it in the scheme;
  add `PrivacyInfo.xcprivacy` (UserDefaults reason `CA92.1`); wire `Config/Local.xcconfig`
  (signing, git-ignored). **Test on the lab iPhone on Fri 6 Nov:** background location with a free account,
  and the Apple Place ID on a real device. Record results in `docs/OPEN-QUESTIONS.md`.

### X-10 — UI-test target + accessibility audit  `[M]`
- **Depends on:** SC-O1 and SC-HD1
- **Do:** add a `VybeUITests` target (Lohitaksh, project setting), then one smoke test that launches, walks
  Discover → Hangout detail, and calls `performAccessibilityAudit()`.

### X-11 — Quality and performance pass on the lab iPhone  `[M]`
- **Depends on:** SC-D1, SC-HD1, SC-H1, SC-CM1, SC-CH2
- **Do:** run `docs/PROCESS.md` section 3 (Q1 checklist) on the iOS 26 simulator and the iPhone; profile with
  Instruments (SwiftUI instrument): map with many pins, long feed scroll, chat with 500 messages, live screen
  with the simulated walk; fix the worst three findings; file the rest as issues.

### X-12 — Demo build and walkthrough  `[S]`
- **Depends on:** SC-D1, SC-HD1, SC-H1, SC-CM1, SC-CH2
- **Do:** record a 2-minute screen video and 6 screenshots of the main flows (Discover → Hangout → Live →
  Summary → Post → Community → Chat) for mentors and advertising (no college name in the app). Seed the demo
  data so every screen looks real.
