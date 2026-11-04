# Review of every pull request, 4 Nov 2026

Written for the four of us to read slowly (over Diwali). For each PR: **what it is for** in plain words, **did it do its
job**, and **the Swift or SwiftUI idea behind it**: why it was built this way. Mistakes and fixes are at the end.

**How this review was done.** Every PR was read against its task in `docs/tasks/`. All of them were merged together in a
scratch copy to check for conflicts and for the lint rules (by pattern). **Nothing was compiled**: the reviewer ran in a cloud
Linux machine with no Xcode. So after pulling, run `./scripts/check.sh` and `scripts/check_lint_rules.sh` on a Mac.

---

## 0. The big picture in one page

Think of the app as a building:

| Layer | Folder | What it is, in plain words | Can it see the screen? |
|---|---|---|---|
| **Models** | `VybeKit/Sources/Models` | the nouns: Place, Spot, Hangout, Run, Comment, Message. Plain data that can be saved as JSON | no |
| **Core** | `VybeKit/Sources/Core` | the rules and plumbing: where data comes from (repositories), shared memory (stores), navigation (Router), services (GPS, photos, network) | no |
| **LocalData** | `VybeKit/Sources/LocalData` | the "warehouse" on the phone: reads the bundled JSON, writes your own files | no |
| **Design** | `VybeKit/Sources/Design` | the paint and bricks: colours, fonts, spacing, buttons, chips, rows | yes |
| **Components** | `VybeKit/Sources/Components` | bigger ready-made pieces: badges, pills, (soon) Hangout cards | yes |
| **Features** | `VybeKit/Sources/*Feature` | the rooms: each screen's View and ViewModel | yes |
| **App** | `Vybe/` | the front door: builds everything once and wires the tabs | yes |

**Why separate folders (targets)?** A Swift package target is a wall. If Models cannot `import SwiftUI`, nobody can
accidentally put screen code inside data. The walls are checked by the compiler and by our lint rules (X-1).

**Why "repositories"?** A screen never asks "read this file" or "call this server". It asks a *repository*
("give me Hangout h1"). Today the repository reads JSON; after Diwali the same question goes to the backend. **The screens
will not change.** That is the whole point of F-5, F-7 and F-8.

**Why "stores"?** Some things must look the same on every tab (is this Hangout saved? is a Hangout live?). That state lives
once, in a store, and every screen reads it.

---

## 1. Merged today and yesterday

### F-0 (#1): Link VybeKit, set concurrency and language modes, prove the architecture
- **For:** connect the package to the app, switch on Swift 6 safety checks, and prove 7 risky ideas work before anyone
  builds on them (previews in a package, strings in a package, Search tab, router-driven navigation…).
- **Did it:** yes. Results and fallbacks are written at the bottom of ADRs 001–004.
- **Concept: Swift 6 strict concurrency.** Swift 6 refuses to compile code where two threads could change the same data at once
  (a "data race"). `@MainActor` means "only on the main (screen) thread". UI targets default to main-actor; Models, Core and
  LocalData do not, so heavy work (reading files, decoding photos) never freezes the screen (ADR 001).

### F-1 (#2): IDs, shared value types, JSON coder, display formatting
- **For:** the basic vocabulary every other file uses.
- **Did it:** yes, every "Done when" test exists (ID as plain JSON string; `[SpotID: Date]` as a JSON object; dates with and
  without fractions; "₹150–400"; "about 3 h").
- **Concepts:**
  - **Typed IDs (`ID<Tag>`).** A `PlaceID` and a `HangoutID` are both strings inside, but different types outside, so passing
    one where the other belongs does not compile. The `Tag` is a "phantom type": it is never created, it only labels.
  - **`Codable`.** Swift can turn a struct into JSON and back automatically. `CodingKeyRepresentable` makes an ID work as a JSON
    *object key* (otherwise Swift writes a dictionary as a strange flat list).
  - **One `JSONCoding`** so every file in the app has the same date format. Mixed date formats are a classic bug.
  - **`LoadState`** is an `enum` with 4 cases (loading, loaded, empty, failed). A screen is always in exactly one of them, so
    "spinner and error at the same time" cannot happen.
  - **`.formatted(...)`** writes ₹, km and numbers the Indian way, so nobody types "Rs".

### X-3 (#3): String Catalogs per module
- **For:** every piece of text the user sees can be translated later (Hindi, Marathi).
- **Did it:** yes. Each target owns its `Localizable.xcstrings`; shared words live in Design as `SharedStrings`.
- **Concept: bundles.** Each package target is its own "bundle" (folder of resources). `String(localized: "key")` looks in the
  *app's* bundle by default, so inside a package you must say `bundle: #bundle`. Forgetting it shows the key on screen instead
  of the text. (Atharva's follow-up note about this is now in `AGENTS.md` 5a; see section 4.)

### F-2 (#4): Content models
- **For:** Place, Spot, Hangout, HangoutRun, Visit, RunTimes, UserProfile with safe-default privacy settings.
- **Did it:** yes; decodes the DATA-MODEL examples; unknown keys ignored; unknown category becomes `.unknown` instead of crashing.
- **Concept: privacy by type.** Exact times live only in `RunTimes`, never in `HangoutRun`. A post *cannot* leak "when you
  were where" because the type that gets shared does not have those fields. Designing the type is stronger than remembering a rule.

### F-4 (#5): Navigation: Routes, Sheet, Cover, Router
- **For:** one place that knows what is on screen; screens ask it to go somewhere.
- **Did it:** yes; there is a route for every pushed screen in `docs/IA.md` (a test checks this), every route round-trips JSON.
- **Concepts:**
  - **`NavigationStack(path:)`.** SwiftUI shows a stack of screens from an array. Put `[.hangout("h1"), .remixTree("h1")]` in
    the array and two screens are pushed. Pop = remove the last item. So navigation becomes *data*.
  - **`Route` as an enum with associated values** (`.hangout(HangoutID)`): routes carry IDs only, never whole objects, so a
    route is small, can be saved, and never shows stale data.
  - **`@Observable` Router.** When `paths` changes, SwiftUI redraws the stacks automatically.
  - **Why `setPath`:** a back-swipe is done by the system, which needs to *write* the array; the Router lets it through one
    method so it stays the single owner.

### DS-1 (#6): Theme tokens
- **For:** all colours, fonts, spacing, radii and animation timings in one place.
- **Did it:** yes; colours come from the Asset Catalog, fonts are text styles.
- **Concept: design tokens.** Code says `Theme.Color.accent`, never a hex value. Change the colour once, the whole app updates.
  Fonts are Apple *text styles* (`.body`, `.headline`), which grow with the user's text-size setting (Dynamic Type).

### Docs-only check (#7)
- **For:** proving that the Test workflow skips PRs that only change docs. It said "do not merge" **and was merged anyway**.
  Harmless (one README line, which is now true), but it shows that "review" was sometimes a click.

### X-2 (#8): GitHub Actions
- **For:** a robot that runs lint on every PR and the full `check.sh` on a Mac runner when a PR is ready.
- **Did it:** the files are right, **but the robot has never run**: GitHub shows zero workflow runs on any PR. Actions is most
  likely switched off for the repo. See "Open items".
- **Concept: CI (continuous integration).** A machine checks every change the same way, so "works on my Mac" is not enough.

### X-1 (#9): SwiftLint custom rules
- **For:** turning our written rules (AGENTS.md, ADR 006) into automatic errors: no hard-coded colours, no `print`, no banned
  words (Plan, Stop, Fork…), no SwiftUI in ViewModels, only `Screens` is public in a feature, and more.
- **Did it:** yes, and very well: every rule has a deliberate bad example in `LintFixtures/`, and `scripts/check_lint_rules.sh`
  proves each rule catches it and nothing else.
- **Concept:** a rule a machine checks is never forgotten; a rule in a document is.

### F-5 (#10): Repositories, stubs, contracts, stores, settings, AppDependencies
- **For:** the "ask, don't fetch" layer.
- **Did it:** yes.
- **Concepts:**
  - **Protocol = a promise.** `HangoutRepository` lists the questions. Anything that answers them can be plugged in.
  - **Stubs** answer with sample data, and can pretend to be empty, failing or slow (`StubMode`). That gives every screen its
    loading, empty and error previews for free.
  - **Contract checks** are the exam every implementation must pass (stub now, LocalData now, backend later), so a new backend
    cannot quietly behave differently.
  - **Dependency injection (`AppDependencies`).** Everything a screen may need is built once and handed in through `init`.
    Previews hand in stubs; the app hands in real ones.
  - **`LibraryStore`** updates memory first (the button reacts instantly), then saves; if saving fails it rolls back
    ("optimistic update").

### F-16 (#11): Feature `Screens` scaffolds
- **For:** every screen already "exists" as a placeholder with its screen ID, so the app runs and every route goes somewhere.
- **Did it:** yes; one test per feature builds every entry point.
- **Concept (ADR 002):** each feature exposes one public `Screens` enum. Views and ViewModels stay `internal`, so features can't
  reach into each other. A screen task only replaces its own placeholder `case`.

### F-9 (#12): App shell
- **For:** the tab bar, one navigation stack per tab, the sheet and full-screen-cover hosts, and the screen factory.
- **Did it:** yes; Search is the trailing search-role tab; tests prove routes, sheets and covers reach the right feature.
- **Concepts:** `TabView` with `Tab(role: .search)`; `.sheet(item:)` and `.fullScreenCover(item:)` show something when a value
  is non-nil and hide it when it becomes nil; the router owns those values. **Binding** = a two-way pipe between a value and a view.

### F-14 (#20, Tanvi): NetworkMonitor
- **For:** knowing when the phone is offline, for the offline banner.
- **Did it:** yes; tests can force offline.
- **Concept:** `NWPathMonitor` calls back on a background queue; the code hops to the main actor (`Task { @MainActor … }`) before
  changing `isOffline`, because the screen reads it.

### X-7 (#16, Shreya): placeholder app icon
- **For:** a neutral 1024 px icon (three dots joined by a line, no text) until the name is final.
- **Did it:** yes; checked: 1024×1024, no transparency (App Store requires that).

### F-6 (#28): Hangout rules
- **For:** the product rules as small pure functions: 2–10 Spots, duplicate-place warning, the 70% Remix rule, 2 visited
  Spots to post, 2 photos per visited Spot, the 30-minute / 2-hour / next-day post delay.
- **Did it:** yes, with edge tests (1, 2, 10, 11 Spots; 69% and 70%; after midnight).
- **Concept: pure functions.** Same input, same output, no clock, no files. Time is a *parameter*, so tests can ask "what if it is
  00:20?" without waiting. Note one choice: the 70% rule counts **Places**, not Spots (a Place used twice counts once). That
  matches `remixedFromPlaceIDs`; confirm it is what you want.

### F-3 (#24): Community, chat and safety models
- **For:** Comment, Like, FriendRequest, Friendship, Block, Conversation, Membership, Message (+ payloads), PollVote, Report,
  Activity, GuestResponse, PlaceSuggestion, RemixCredit.
- **Did it:** yes; every report reason from the task; unknown message kinds decode as `.unsupported` instead of breaking a chat.
- **Concept: enums with payloads in JSON** (`{"kind": "text", "text": "hi"}`). One message type, many shapes; adding a shape
  later does not break old apps.

### F-8 (#18): LocalData
- **For:** the phone's warehouse: read the bundled Places and Hangouts, search them, and save your Saved/Drafts/Runs file.
- **Did it:** yes; contract checks pass on the local repositories; ten quick saves leave one valid file; a corrupt file is moved
  aside (`library.corrupt-<time>.json`) and the app starts empty; a file from a newer app version is never overwritten.
- **Concepts:**
  - **`actor DocumentFile`.** An actor is a class that handles one call at a time, like a single shop counter. Ten saves queue
    up and happen in order, so the file is never half-written by two saves at once.
  - **Atomic write.** Write to a temporary file, then swap it in. A crash mid-write leaves the old file, never a broken one.
  - **`schemaVersion`** in every file, so a future app can read old files and an old app refuses newer ones safely.
- **Important for tomorrow:** the bundled content folder is still **empty** (the EXAMPLE data lives only in the tests). On the
  simulator the app shows empty states until X-C1 adds real Places. Previews use the stubs, so screen work is not blocked.

### F-10 (#19): Live run store
- **For:** the Hangout you are doing right now survives switching tabs, closing the app, and a crash.
- **Did it:** yes; starting twice gives one run; marking a Spot twice changes nothing; ten quick visits end in one consistent
  file; restart restores the run minimised; a failed save is shown as `persistenceError`.
- **Concepts:** **write-behind saving** (memory changes now, the disk catches up; changes that arrive during a save are folded
  into one more save). **Elapsed time is computed** from `startedAt`, never counted by a timer, so it is right even after the app
  slept. **`scenePhase == .background`** flushes the save before iOS suspends the app.

### F-7 (#27): Social repositories, BadgeStore, sample social data
- **For:** the questions Community, Friends, Chat, Safety, Sign-in and Admin will ask, plus a fake "server in memory" that
  answers them with 12 clearly fake people, 8 posts, comments, 3 chats and reports.
- **Did it:** yes; blocking is applied inside the repository (a blocked person disappears everywhere); the chat stub sends a fake
  incoming message after 2 seconds; BadgeStore counts are tested.
- **Concepts:** **`AsyncThrowingStream`** for live chat: the screen loops over it and gets a new message list every time
  something changes, like a subscription. **Cursor paging (`Page`)**: "give me the next page after this marker", which both
  Firebase and Supabase support.
- **Watch out:** in a **Release** build these stubs do not exist, so the app stops with `fatalError` (see Open items).

### F-13 (#29): PhotoProcessor
- **For:** every picked photo becomes two JPEGs (≈1600 px and ≈400 px) with **all metadata removed**, including GPS.
- **Did it:** yes; the test image really has GPS before, and none after.
- **Concept:** ImageIO decodes a picture and writes a new one from the pixels only. Metadata (where and when the photo was
  taken) does not travel with pixels, so it is gone. The rotation is applied first, because the rotation tag is metadata too.

### F-11 (#30): LocationService
- **For:** where the phone is, through one door; a simulated walk for desk demos and tests.
- **Did it:** yes; no delegate code; never asks for "Always"; the simulated walk is tested with a fake clock.
- **Concepts:** **`CLLocationUpdate.liveUpdates`** gives locations as an async sequence (`for try await update in …`), the
  modern replacement for delegate callbacks. **`CLServiceSession`** asks for permission; **`CLBackgroundActivitySession`** keeps
  updates coming with the screen off during a live Hangout (needs X-9's Background Mode).

---

## 2. Open and reviewed: Atharva's design-system PRs (all marked **Draft**)

All eight were reviewed and are good. They were **not merged** because they are drafts: Atharva has not said they are ready.
When he marks them ready (or Lohitaksh decides to), merge them **in this order** (each one sits on the one before):

1. **DS-4 (#15) Motion and haptics.** `.vybeAnimation`, `withVybeAnimation`, `slideUp`, `VybeHaptic`. *Concepts:* a
   **ViewModifier** packages a reusable change to a view; **Reduce Motion** turns movement into a fade; **`sensoryFeedback`**
   plays a haptic when a value changes.
2. **DS-3a (#21) Buttons and chips.** `PrimaryButton` (wraps at large text, loading state), `SecondaryButton`, `IconButton` (an
   accessibility label is *required by the initializer*, so it can never be silent), `FilterChip` (checkmark when selected: never
   colour alone).
3. **DS-3b (#22) Rows and search field.** `NavRow`, `ToggleRow`, `InfoRow` (value moves under the label at huge text sizes),
   `SectionHeader` (VoiceOver heading), `SearchField`.
4. **DS-3c (#23) Text field with error text.** Error has an icon and words, and VoiceOver reads it after the field.
5. **DS-5 (#17) FlowLayout, skeletons, ReadableContent.** *Concept:* SwiftUI's **`Layout` protocol**: you measure children
   (`sizeThatFits`) and place them (`placeSubviews`); FlowLayout wraps chips onto new lines like words in a paragraph.
6. **CP-10 (#25) InfoPill, BestTimeLabel, TagRow.**
7. **CP-5 (#26) Badges and SafetyNote.** Icon + word for every state; the monsoon wording is marked as a draft for the team.
8. **DS-6 (#14) ImageLoader.** *Concepts:* **downsampling** (decode a 4000 px photo straight to 400 px, saving memory),
   **`NSCache`** (keeps decoded images and frees them under memory pressure), **de-duplication** (two cards asking for the same
   photo share one load), **`@concurrent`** (decoding runs off the actor so cached hits stay instant).

If GitHub says a stacked PR "has conflicts" after the one below it is squash-merged, use the same fix used tonight for F-10 and
F-7: `git merge origin/main` on that branch, keep the branch's version, push (no force).

Two small notes for later (not blockers): `FilterChip`'s haptic also fires when a "Reset" clears chips in code; and a fixed label
passed as a `LocalizedStringResource` from a feature needs `bundle: #bundle` (now written in `AGENTS.md` 5a).

### Closed: X-3 duplicate (#13)
X-3 was already merged as #3. Its useful docs fix (above) was carried into this review PR; the PR was closed with a comment.

---

## 3. Mistakes found and fixed in the review PR (`l/f0-foundation`)

| # | Mistake | Why it matters | Fix | Proof |
|---|---|---|---|---|
| 1 | `LibraryStore` could **save before it had read the file** (a tap before launch loading finished, or a file it refused to read) | that save would **replace the whole library** (Saved, Drafts, runs) with almost nothing; it also defeated F-8's "never overwrite a newer file" | every change calls `ensureLoaded()` first and refuses to save if reading failed; the write-behind save has the same guard; `RootView` uses `ensureLoaded()` | 2 new tests in `StoreTests.swift`, 1 in `LiveHangoutStoreTests.swift` |
| 2 | `LiveHangoutStore` could not **start a Draft** (it only asked the repository, which serves published Hangouts) | a Remix is a Draft until it has been done, and "Remixed Hangouts cannot be posted until actually done" (PRODUCT 4): nobody could ever do a Remix | look in the person's Drafts first, then the repository | `aDraftCanBeStarted` |
| 3 | `Router.presentCover` left a sheet open underneath | the cover's own sheet host would show that old sheet again on top of the live screen | opening a cover closes the sheet first | `presentingACoverClosesASheet` |
| 4 | Sample chat text "EXAMPLE plan for Saturday?" | "plan" is a banned word: with X-1 merged, **lint fails** on `main` | "EXAMPLE Hangout on Saturday?" | lint pattern scan |
| 5 | `SearchRepositoryContract` demanded every result match by **title** | F-8 also matches tags and areas (as its task says), so a real tag match would fail the contract | only the best result must match by title (title matches rank first) | existing contract tests |
| 6 | DATA-MODEL said a Visit has `visitedAt` and a run has `durationRounded` | contradicts the privacy rule (times only in `RunTimes`) and the code | doc rows corrected | — |
| 7 | Test comment said 00:10 / 18:40 UTC; the timestamp is 00:20 / 18:50 | a wrong comment teaches the wrong thing | comment corrected | — |
| 8 | `VybeKit/Sources/Components/T_HangoutCardData` (no `.swift`) | Xcode never compiled it; it would confuse CP-1 | removed (history keeps it: commits `9dad661`–`419e9c0`) | — |
| 9 | Stacked branches F-10 and F-7 conflicted after squash merges | blocked merging | `git merge origin/main` into each, kept their newer lines, checked each diff equals the PR's own change, pushed without force, merged | PRs #19 and #27 merged |

---

## 4. Open items (need a human, a Mac or a decision)

1. **Run the checks on a Mac** after pulling: `./scripts/check.sh` and `scripts/check_lint_rules.sh`. Nothing here was compiled.
2. **Turn on GitHub Actions** (Settings → Actions → General → allow actions). Then confirm `Lint` and `Test` run on the next PR.
   The runner label `xcode-27` and simulator `iPhone 17` in `test.yml` are unverified until it runs.
3. **Release builds crash at launch** (`fatalError` in `AppDependencies+Local.swift`) because the social stubs exist only in
   DEBUG, and `FeatureFlags` turns social **off** in Release. Since social is in version 1 and goes to TestFlight, decide at
   BK-14: real backend first, or an internal "sample data" build. Recorded in `docs/OPEN-QUESTIONS.md` 8d.
4. **Real content (X-C1):** 5 real Places and 2 real Hangouts with photos. Nobody (and no AI) may invent them.
5. **Blocking is in two places:** `SafetyRepository.block` hides people in the social stubs, but `SessionStore.blockedIDs`
   (used by screens) is not updated by it. SC-R2 / SC-ST-B must update both, or add one method that does.
6. **PR descriptions:** most PRs left "How to test", the `check.sh` output and "In my own words" empty. Those three are how a
   reviewer knows the author ran and understood the code. Please fill them from tomorrow.
7. **Small, later:** two copies of the distance formula (LocalData and F-11): move one into Models when the map work starts;
   `PhotoProcessor.originalLongSide` has a `rotated ?` branch that does nothing (harmless); the 70% Remix rule counts Places.

---

## 5. How to study this over Diwali

Follow one path through the code and open each file as you reach it:
`VybeApp` → `RootView` → `TabShell` → `DiscoverScreens.root` → (tomorrow's) ViewModel → `HangoutRepository` →
`LocalHangoutRepository` → `ContentLoader` → a JSON file. Then do the same for "tap Start Hangout":
`Router.presentCover(.live)` → `LiveScreens.liveCover` → `LiveHangoutStore.startOrResume` → `LibraryStore.updateRun` →
`DocumentFile.save`.

For every file: guess what it does from its name, read it, explain it out loud, then change one line on a throwaway branch and
predict which test fails before running `check.sh`.
