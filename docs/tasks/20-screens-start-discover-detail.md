# Screen tasks: onboarding, sign-in, Discover, Hangout detail

Every screen task follows `docs/templates/new-screen/README.md` and the DoD in `AGENTS.md` section 6: View + ViewModel + three
previews (loaded / empty / error, plus one at `.accessibility3`) + a ViewModel test + `./scripts/check.sh` + a PR with screenshot and
"In my own words". Data comes only from repositories/stores injected into the ViewModel (sample data via `LocalData` or the
`Core/Fakes` stubs); navigation only through `router`. Screen IDs (`O1`, `D1`…) are defined in `docs/IA.md` section 4: read your row
there first; general reading is `docs/START-HERE.md` section 1.

Common "Depends on" for every screen: **F-4** (router), **F-5** (repositories/stubs/stores), **F-9** (app shell with your route stub),
**DS-1/DS-2/DS-3** (Theme, state views, buttons). Only extras are listed.

**Wiring (ADR 002 and 003):** your screen's route already exists (F-4) and its placeholder `case` is in
`<Name>Feature/<Name>Screens.swift` (F-16). Replace that one `case` with your View built on your ViewModel; keep Views and
ViewModels `internal` (the feature's only `public` type is its `Screens`); do not edit the App target, `Core/Navigation`, `Models` or
`Package.swift`. Start from `scripts/new_screen.py` once X-5 exists, otherwise from the template. Stop and ask if you need a change in
any of those shared places.

---

## Onboarding (stack `StackID.onboarding`; folder `OnboardingFeature/`)

### SC-O1 — Welcome  `[S]`
- **Depends on:** common
- **Read:** IA 4 (O1), 6 (flow 1) · PRODUCT 1 (tone)
- **Build:** `Welcome/`: wordmark (text for now; the name is not final), one-line pitch in our tone
  ("Find your Vybe." / "One more spot?"), a photo-led hero (sample photo), `PrimaryButton` "Get started"
  → `router.open(.nameAndPhoto)`; a small "I have an account" link → `router.open(.signIn)`.
  No tab bar here. First launch only (RootView decides).
- **Done when:** previews incl. small screen and `.accessibility3`; VoiceOver order: pitch, button.

### SC-O2 — Name and photo  `[M]`
- **Depends on:** common, F-13 (PhotoProcessor)
- **Read:** IA 4 (O2) · DATA-MODEL 3 (UserProfile) · AGENTS 5a
- **Build:** `NameAndPhoto/`: name field (2–30 characters, trimmed; inline error text), optional photo via
  `PhotosPicker` → `PhotoProcessor` (location data stripped) → preview circle; Continue → `.interests`.
  The values are held in the `SessionStore` onboarding draft, **not** in `UserDefaults`.
- **Done when:** ViewModel tests: invalid name keeps Continue disabled; photo processing failure shows an
  error and lets the person continue without a photo.

### SC-O3 — Interests  `[S]`
- **Depends on:** common, DS-5 (FlowLayout)
- **Read:** IA 4 (O3) · PRODUCT 4 (Accounts: interests affect suggestions, changeable later)
- **Build:** `Interests/`: heading + `FilterChip`s in a `FlowLayout` from a fixed list of ~14 interests
  (Cafés, Street food, Treks, Gaming, Live music, Movies, Board games, Study spots, Sports, Art and culture,
  Thrift, Photography, Sunsets, Budget eats); choose **at least 3**; Continue → `.location`.
- **Done when:** Continue disabled until 3 chosen; selection kept when going back; test for the minimum rule.

### SC-O4 — Location  `[M]`
- **Depends on:** common, F-11 (LocationService)
- **Read:** IA 4 (O4) · ARCHITECTURE 4a #1, #8 · RISKS 3
- **Build:** `Location/`: explain *why* ("To show Hangouts near you and guide you while you walk") **before**
  the system prompt, "Allow location" (`requestWhenInUse`; never Always), "Not now". If denied or skipped:
  an **area picker** (areas from `PlaceRepository`, default Kothrud). Finishing calls
  `session.completeOnboarding()` and `router.reset()`. Lohitaksh adds the purpose string (X-9); until then
  the prompt cannot appear, so test the denied path.
- **Done when:** tests: denied → area picker → completes; allowed → completes; onboarding flag persists.

### SC-O5 — Find friends  `[M]`
- **Depends on:** common, F-7, CP-4
- **Read:** IA 4 (O5) · PRODUCT 4 (Friends: mutual friends only)
- **Build:** `FindFriends/` (screen for new accounts): "People you may know" from `FriendsRepository`
  (mutual-friends reason text "3 mutual friends"), **Add** button per row (→ request sent state), **Skip**.
  No phone contacts, no college.
- **Done when:** states: empty ("No suggestions yet. Invite friends from a Hangout."), error, loaded; test.

## Sign-in (folder `AuthFeature/`)

### SC-A1 — Sign in  `[M]`
- **Depends on:** common, F-7
- **Read:** IA 4 (A1) · RISKS 1 and Apple guideline note in OPEN-QUESTIONS 1
- **Build:** `SignIn/`: **Sign in with Apple** (`SignInWithAppleButton`, UI only; calls
  `AuthRepository` stub), **Continue with Google** (UI), **Continue with email** → `.emailSignIn`; terms and
  privacy links (placeholders). Handles: loading, provider failed (retry), cancelled.
- **Done when:** stubbed success moves to `.accountBasics` for a new user or finishes for an existing one.

### SC-A2 — Email sign-in  `[M]`
- **Depends on:** SC-A1
- **Build:** `EmailCode/`: email field (validation) → "We sent you a code" → 6-digit code entry with
  auto-advance, paste support, resend countdown; errors: invalid or expired code; rate-limit message.
- **Done when:** tests for validation and the resend timer (injected clock).

### SC-A3 — Account basics  `[M]`
- **Depends on:** SC-A1, F-6
- **Read:** PRODUCT 4 (Accounts) · RISKS 1, 3 (under-18) · DATA-MODEL 3 (UserProfile, AccountPrivate)
- **Build:** `AccountBasics/`: **unique username** (3–20 chars, lower-case letters, digits, `_` and `.`,
  not a reserved word; live availability check through the repository stub with debounce), **date of birth**
  (`DatePicker`, wording is neutral: do not hint at "18" in the label). If under 18: a calm blocking screen
  ("Vybe is for people 18 and over") and the device remembers it. Otherwise continue to `.nameAndPhoto`.
- **Done when:** tests: username rules, taken username, under-18 path, boundary on the 18th birthday.

## Discover (folder `DiscoverFeature/`)

### SC-D1 — Discover map  `[L]`
- **Depends on:** common, CP-1, CP-11, F-8 (sample content)
- **Read:** IA 4 (D1, D2), 1 (principle 4) · ARCHITECTURE 4 (Map pins, Pin clustering, Route line) ·
  MOTION 4 (moments 1 and 3)
- **Build:** `Map/`: full-screen SwiftUI `Map` with `Annotation(HangoutPin)` for each Hangout at its first
  Spot; selection via `Map(selection:)`; a row of 2–3 category `FilterChip`s plus a **More filters** button
  (opens SC-D3 through a ViewModel flag); a bottom strip of Picks (`HangoutCard(.featured)`); a recenter
  button (`MapUserLocationButton`); keep Apple's logo and Legal link visible (`safeAreaInset`). **Pin
  clustering** is done by us: a pure `PinClusterer` (grid cells by zoom span, tested) in the ViewModel
  working with `Coordinate`s; the **View** converts `MapCameraPosition`. Pin tap selects and shows the
  SC-D2 card. A "monsoon" `SafetyNote` appears June to September.
- **Files:** `DiscoverFeature/Map/MapView.swift`-style `DiscoverMapView/ViewModel`, `PinClusterer.swift`
- **Done when:** tests for `PinClusterer` (same point, far points, zoom change) and for filtering; states:
  loading, empty ("No Hangouts here. Try zooming out."), error, stale (offline); VoiceOver can reach every
  pin; works with location denied.

### SC-D2 — Pin preview card  `[M]`
- **Depends on:** common, CP-1, SC-D1 (shares its ViewModel state)
- **Read:** IA 4 (D2) · ARCHITECTURE 4 (Pin preview row) · MOTION 4 (moment 1)
- **Build:** `PinPreview/`: an **overlay card** (not a sheet: a sheet would hide the tab bar) showing
  `HangoutCard(.compact)` with Save and **See Hangout**; slides up with `Theme.Motion.standard` and a
  `.selection` haptic; dismisses on map tap or swipe down; tapping calls `router.open(.hangout(id))`.
- **Done when:** previews; Reduce Motion uses a fade; tapping the card pushes the Hangout detail route.

### SC-D3 — Filters sheet  `[M]`
- **Depends on:** common, DS-3, DS-5
- **Read:** IA 4 (D3) · OPEN-QUESTIONS 9 (filters list)
- **Build:** `Filters/`: a local sheet (flag in the Discover ViewModel, medium/large detents, grabber):
  budget range (₹0–1,000), time (up to 1 h / 2 h / 3 h+), categories, vibe tags, "Good for groups",
  **Reset** and **Apply (n results)**. Uses `HangoutFilters` from `Models` and reports back through the
  Discover ViewModel.
- **Done when:** tests: reset clears; apply count updates; filters applied survive closing the sheet.

## Hangout detail (folder `HangoutDetailFeature/`)

### SC-HD1 — Hangout detail  `[L]`
- **Depends on:** common, CP-1, CP-2, CP-3, CP-5, CP-10, F-10
- **Read:** IA 4 (HD1), 6 (flows 2, 4) · PRODUCT 2, 4 (Hangouts) · ARCHITECTURE 2.4 (the full example
  ViewModel is this screen) · MOTION 4 (moments 2 and 4)
- **Build:** `Detail/`: photo header (`PhotoGallery`), title, Picks badge, `InfoPill`s, `TagRow`, summary,
  the ordered `SpotRow`s (tap → `router.present(.spot(placeID))`), "Remixed from @x" credit line
  (→ `.remixTree`), `SafetyNote` for treks. Actions: **Start Hangout** (`PrimaryButton`; becomes "Resume
  Hangout" when a run is live), **Save** (toggle, haptic), **Share** (`ShareLink` with plain text: title +
  "Find it on Vybe"), **Remix** (`router.presentCover(.editor(.remix(id)))`), ••• menu (Report →
  `router.present(.report)`). Start: `liveStore.startOrResume` then `router.presentCover(.live(id))`. Zoom
  transition in from the card. Load by ID; **not found** shows "This Hangout is no longer available".
- **Done when:** ViewModel tests (the ones in ARCHITECTURE 2.4: load, idempotent load, start, save);
  states loading / not found / error / offline (Start disabled offline); this screen becomes the
  **golden example**: after merging, update `docs/templates/new-screen/README.md` to point at its files.

### SC-HD2 — Spot sheet  `[M]`
- **Depends on:** common, CP-1, CP-3, CP-5
- **Read:** IA 4 (HD2) · ARCHITECTURE 2.6 (router sheet) and 4 (Apple place details) · RISKS 1 (treks)
- **Build:** `SpotSheet/`: opened by `Sheet.spot(PlaceID)` from three features. Photo gallery with credits,
  name, category, address, **today's opening hours** ("Open until 10 pm", computed from `OpeningPeriod`s in Pune
  time), cost per person, trek `SafetyNote` and **"Closed by authorities"** status, "Hangouts with this Spot"
  (up to 3 `HangoutCard(.compact)`; tap → `router.dismissSheet()` then `.open(.hangout)`), and **Apple place
  details** via `mapItemDetailSheet` using `applePlaceID` (the one allowed sheet-on-sheet; hide the button
  when there is no ID). Report place → push `Route.report` inside the sheet. Medium/large detents.
- **Done when:** previews for open, closed, trek, no photos, no Apple ID; test for "open until" logic at
  midnight and for days with no hours.

### SC-HD3 — Remix tree  `[M]`
- **Depends on:** common, CP-1, CP-4
- **Read:** IA 4 (HD3) · PRODUCT 4 (Hangouts: Remix credit) · DATA-MODEL 3 (RemixCredit)
- **Build:** `RemixTree/`: "Remixed from" original card, then the list of Remixes (author avatar + username +
  mini card) and the counters "Done 40× · Remixed 12×" (posted runs only; each person counted once; ≥70%
  of Spots kept). Tap → `.hangout(id)`. Empty: "Nobody has remixed this yet. Be the first."
- **Done when:** states + test of the counter text; opens from the credit line on HD1.
