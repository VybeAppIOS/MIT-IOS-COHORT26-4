# Screen tasks: live Hangout, Search, Profile and Settings

Same rules as `docs/tasks/20-screens-start-discover-detail.md` (template, DoD, common dependencies
F-4, F-5, F-9, DS-1/2/3, previews, ViewModel tests, PR with screenshot). IDs are in `docs/IA.md` 4.

## Live Hangout (folder `LiveFeature/`; shown in `Cover.live`, stack `StackID.live`)

### SC-H1 — Hangout live  `[L]`
- **Depends on:** common, F-10 (LiveHangoutStore), F-11 (LocationService), CP-2, DS-4
- **Read:** IA 4 (H1), 6 (flow 3) · ARCHITECTURE 4 (Route line, Look Around not used), 4a #2/#10 · MOTION 4
  (moment 4) · PRODUCT 4 (Doing and posting) · RISKS 3 (live run is never visible to anyone else)
- **Build:** `Live/`: big glanceable text for the **current Spot** (name, "250 m · 4 min walk"), a map with
  the route line (`MKDirections` walking, requested **once** when the screen opens, cached; if throttled or
  failing, fall back to a straight `MapPolyline` between Spots), the next Spots as `SpotRow`s, elapsed time via
  `Text(startedAt, style: .timer)` (no running timer), **Mark visited** (`PrimaryButton`) opening SC-H2,
  **Minimise** (`router.dismissCover()`; the run stays alive for SC-H4) and **End Hangout** (confirmation
  dialog if Spots remain; then `liveStore.end()` and `router.open(.liveSummary(runID))`). Location from
  `LocationService` (use `SimulatedLocationService` in previews and desk demos); works if location is
  denied (the person just taps Mark visited). Haptics `.start`/`.stop`. Look Around is **not** used.
- **Done when:** ViewModel tests with the simulated walk: distance updates, next Spot advances after Mark
  visited, ending with Spots left asks for confirmation; works offline; largest text keeps the current Spot
  and the primary button on screen without scrolling.

### SC-H2 — Mark visited  `[M]`
- **Depends on:** common, F-13, F-10
- **Read:** IA 4 (H2) · MOTION 3 and 4 (moment 5: the app's hero moment) · RISKS 3 (photos, no GPS)
- **Build:** `MarkVisited/`: a small-detent **local sheet** (flag in `LiveViewModel`): "Mark <Spot> as
  visited?", optional **Add a photo** (`PhotosPicker` → `PhotoProcessor`, allowed up to `2 × visited`), a
  "Done" button → `liveStore.markVisited`. Success: circle → checkmark with SF Symbol replace + bounce,
  `.success` haptic; on the **last** Spot also a one-time confetti (skipped with Reduce Motion).
- **Done when:** tests: photo limit respected; marking twice is idempotent; Reduce Motion preview shows
  a plain fade with the checkmark and text.

### SC-H3 — Summary  `[M]`
- **Depends on:** common, F-6, F-10, CP-3
- **Read:** IA 4 (H3), 6 (flow 3) · PRODUCT 4 (Doing and posting) · RISKS 3
- **Build:** `Summary/`: "You visited 3 of 5 Spots", rounded duration ("about 3 h", **never exact times**),
  approximate distance, a photo grid (remove allowed), counters that roll once with `.numericText`.
  Buttons: **Post** (→ `router.open(.composePost(runID))` on the live stack; disabled with the reason
  "Visit at least 2 Spots to post" until `HangoutRules.canPost`), **Not now** (keeps the run as Done in Ready to
  post; then `router.show(nil, in: .discover)`).
- **Done when:** tests for the disabled reason and for the destination of Not now; 0-photo and 8-photo previews.

### SC-H4 — Live mini-bar  `[M]`
- **Depends on:** common, F-10, SC-H1
- **Read:** IA 4 (H4) · ARCHITECTURE 4 (iOS 26 features: `tabViewBottomAccessory`)
- **Build:** `MiniBar/`: while a run is live and the live cover is dismissed, show a bar above the tab bar
  (`tabViewBottomAccessory`, wired in `TabShell` by Lohitaksh or via a small hook) with the current Spot and
  a timer; tap → `router.presentCover(.live(id))`. Disappears when the run ends.
- **Done when:** previews with and without a live run; VoiceOver label "Live Hangout, <Spot>, tap to return".

## Search (folder `SearchFeature/`; the separate trailing tab)

### SC-S1 — Search  `[L]`
- **Depends on:** common, CP-1, CP-4, F-8 (`LocalSearchRepository`)
- **Read:** IA 2 (Search tab), 4 (S1) · PRODUCT 3 (Search) · ARCHITECTURE 4 (Tabs row: `.searchable` placement)
- **Build:** `Search/`: `.searchable(text: $viewModel.query)` **inside `SearchView` on the search tab's own
  `NavigationStack`** (not on the TabView root). Empty query: recent searches (kept in `AppSettings`) and
  suggestions (Picks near you). Results grouped **Hangouts, Places, People** (no segmented control); the group
  order depends on `router.lastNonSearchTab` read **when a query runs** (Discover → Hangouts first, Community →
  People first, Profile → your Saved first). Tap Hangout → `.open(.hangout)`; Place → `router.present(.spot)`;
  Person → `.open(.profile)`. No results: "Nothing yet. Know a good spot?" → `router.present(.suggestPlace)`.
  Search runs on the phone for Hangouts/Places and through the repository for People; blocked people never
  appear. Debounce typing (0.25 s).
- **Done when:** tests: ordering by previous tab; debounce; blocked people hidden; empty/no-result/error;
  works with the keyboard and at the largest text size.

### SC-S2 — See all  `[S]`
- **Depends on:** SC-S1
- **Build:** `SeeAll/`: full list for one group (`Route.searchSeeAll(kind)`), paged with `Page<T>`.
- **Done when:** paging test; empty state.

## Profile and Settings (folder `ProfileFeature/`)

### SC-PR1 — My profile  `[L]`
- **Depends on:** common, CP-1, CP-9, CP-6
- **Read:** IA 4 (PR1) · PRODUCT 4 (Accounts) · DATA-MODEL 3 (UserProfile)
- **Build:** `Profile/`: `ProfileHeader(.own)` (banner, avatar, name, @username, bio, stats: Hangouts done,
  Spots visited, friends), rows **Saved (n)** → `.saved`, **Drafts (n)** → `.drafts`, **Ready to post (n)** →
  `.readyToPost`, a grid/list of my posted Hangouts (→ `.post`), gear → `.settings`, **Edit** (SC-PR6, local
  sheet). Empty state for no posts ("Your first Hangout will show up here").
- **Done when:** states + tests (counts, navigation); the stats never show times.

### SC-PR2 — Settings (root)  `[M]`
- **Depends on:** common, DS-3
- **Build:** `Settings/`: grouped list with `NavRow`s to the settings pages (SC-ST-A/B/C), plus the Phase 1
  items inline: edit name and photo, change area, reset onboarding, About. The hidden **Admin** row
  (→ SC-AD1) appears only when `session.isTeamAccount`.
- **Done when:** tests: the Admin row is hidden for normal accounts; reset onboarding calls
  `session.resetOnboarding()` and `router.reset()`.

### SC-PR4 — Saved  `[M]`
- **Depends on:** common, CP-1
- **Build:** `Saved/`: `LibraryStore` saved Hangouts as `HangoutCard(.regular)`; swipe to unsave with undo;
  a Hangout that can no longer be opened shows "No longer available" (and can be removed); empty state
  ("Save a Hangout from Discover"); tap → `.hangout(id)`.
- **Done when:** tests for unsave/undo and the unavailable state.

### SC-PR5 — Drafts  `[M]`
- **Depends on:** common, CP-1, CP-5
- **Build:** `Drafts/`: list of your Drafts with `StatusBadge(.draft)`, swipe to delete (confirm), tap →
  `router.presentCover(.editor(.draft(id)))`, **New Hangout** → `.editor(.new)`. Empty: "Start a Hangout from
  scratch or Remix one."
- **Done when:** tests for delete confirm and the New button.

### SC-PR6 — Edit profile  `[M]`
- **Depends on:** common, F-13, DS-3, DS-5
- **Read:** IA 4 (PR6) · DATA-MODEL 3 (UserProfile)
- **Build:** local sheet in `EditProfile/`: name, **username** (unique check; shows the 30-day hold rule when
  freeing an old one), photo and **banner** (via `PhotosPicker` + `PhotoProcessor`), bio (≤150), **interests**
  chips (≥3). Save is disabled until valid; discard confirm.
- **Done when:** validation tests (username rules, bio limit, ≥3 interests).

### SC-PR8 — Ready to post  `[M]`
- **Depends on:** common, F-6, CP-5
- **Read:** IA 4 (PR8) · DATA-MODEL 3 (HangoutRun states)
- **Build:** `ReadyToPost/`: two sections. **Finished, not posted** (a card with date, "3 of 5 Spots", photo
  count; buttons **Post** → `.composePost(runID)` and **Delete**); **Scheduled** ("Scheduled for 8:30 pm";
  **Cancel**). Empty state for both.
- **Done when:** tests: Post is disabled with the reason below 2 visited; cancel returns the run to Done.

### SC-ST-A — Account settings and delete account (ST1, ST8)  `[M]`
- **Depends on:** common, DS-3
- **Read:** IA 4 (ST1, ST8) · RISKS 4 (deletion) · DATA-MODEL 7 (decision 8)
- **Build:** `SettingsPages/` (ST1: email/sign-in method, **Sign out**, change area, reset onboarding) and
  `DeleteAccount/` (ST8: explains what happens, re-confirm by typing the username, then deletes
  `library.json`, run photos and `profile.json`, ends any live run, calls the repository's delete (stub),
  `router.reset()` and returns to O1). **All of the person's photos are deleted; posts stay as "[deleted]"**
  (decided 3 Nov); the username is held 30 days.
- **Done when:** tests: sign out clears the session and router; delete clears the local files and the live
  run; the confirm text must match.

### SC-ST-B — Privacy, Blocked, Notifications (ST2, ST3, ST4)  `[M]`
- **Depends on:** common, DS-3, F-7
- **Read:** IA 4 (ST2–ST4) · RISKS 3 (defaults) · DATA-MODEL 3 (UserProfile settings)
- **Build:** ST2 Privacy: **private profile** toggle (explains "all your posts become friends-only"), default
  audience (Friends by default), who can comment, who can send friend requests, who can add me to groups ("Ask
  me" by default), "show me in search". ST3 Blocked: list with Unblock. ST4 Notifications: switches per event
  (friend requests, messages, likes, comments, reminders); asking for system permission happens at the first
  friend request or chat, **not here at sign-up**.
- **Done when:** tests that each setting persists through the repository stub and the defaults are the
  accepted ones in RISKS 3.

### SC-ST-C — Help, Place suggestions, About (ST5, ST6, ST7)  `[S]`
- **Depends on:** common, DS-3
- **Build:** ST5 Help and contact (support email shown as selectable text, **grievance officer name and
  contact**, links to Terms and Privacy placeholders, "Report a problem"); ST6 My Place suggestions (status:
  pending / approved / rejected with the team's note); ST7 About and credits (version, photo credits from the
  content, licences).
- **Done when:** previews; the credits list reads `Photo.credit` from the sample content.
