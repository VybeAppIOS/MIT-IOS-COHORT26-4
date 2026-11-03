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
- **Read:** ARCHITECTURE 6 · MOTION 3 (rule 8) · AGENTS 5 and 5a
- **Build in `.swiftlint.yml`:** custom rules that fail on: `Color(red:`/hex colour literals outside
  `Design/Theme`; `.system(size:`; raw animation curves (`.easeInOut`, `.spring(` …) outside `Design/Theme`;
  bare `withAnimation {`; `ObservableObject`, `NavigationView`, `NavigationLink(destination:`; `print(`;
  `@AppStorage` outside the app target; `canOpenURL`; banned words (Plan, Trace, Stop, Node, outing, Fork,
  Organiser) **only inside string literals and type/case/file names**, with word boundaries.
- **Done when:** a deliberate violation of each rule is caught (keep the examples in a test file excluded
  from lint); `./scripts/check.sh` still green.

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
- **Read:** ARCHITECTURE 3.2 ("Package details to verify" #2) · AGENTS 5a
- **Build:** decide and document how `String(localized:)` finds strings in a **package**: add a
  `Localizable.xcstrings` to each target that shows text (resources + `bundle: .module`), put shared words in
  `Design`, and prove it with one string in `DiscoverFeature` and one in `Design`. Update the screen template
  with the exact call.
- **Done when:** a string added to the catalog appears at runtime; the template and AGENTS 5a say how.

### X-4 — Accessibility review (repeat per feature)  `[M]`
- **Depends on:** SC-HD1 (then repeat for each feature once its screens are merged)
- **Read:** AGENTS 5a · ARCHITECTURE 4a (#3, #4) · PROCESS 3
- **Build/Do:** per feature: VoiceOver walk-through (every control reachable, sensible order and labels),
  largest text size (`.accessibility3` and the real Settings extreme), Reduce Motion, Increase Contrast,
  44 pt targets, colour never the only signal; fix findings; record a short checklist in the PR.
- **Done when:** the checklist is ticked for that feature.

### X-5 — Golden example + template refresh  `[S]`
- **Depends on:** SC-HD1 merged
- **Build:** update `docs/templates/new-screen/README.md` and each feature folder's `README.md` to point to
  the real files of the first finished screen; write a 30-minute walk-through script for the team.

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
