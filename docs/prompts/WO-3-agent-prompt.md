# Prompt for the screen-building agent: work order 3

Paste everything below the line into the agent. It is written for an agent that has the repo open and knows the project.

---

You are building the remaining screens of **work order 3** for the Vybe iOS app, in the repo you have open
(`~/Developer/MIT-IOS-COHORT26-4`). Lohitaksh (the lead) has approved this plan, so do **not** wait for a "plan OK" per
screen. Work through the whole list in order, then write a report. Quality matters more than speed: a screen is finished
only when it looks right in the simulator, not when it compiles.

## 0. Set up
1. `git fetch`. Base your work on the branch **`l/sc-r1-report`** (it holds SC-R1 Report, SC-R2 Block confirm, the
   shared pieces and the fixed button size; it is not in `main` yet). If it has merged into `origin/main` by now, base on
   `origin/main` instead. Create ONE branch `l/wo3-screens` and make **one commit per screen**. Never push, never merge,
   never touch `Vybe.xcodeproj` or `Package.swift`.
2. Read: `AGENTS.md`, `docs/SCREENS-GUIDE.md`, `docs/work-orders/WO-3-profile-editor-posting-safety.md`,
   `docs/IA.md`, `docs/MOTION.md`, `docs/RISKS.md`, `docs/PRODUCT.md`, and the task text for each screen in
   `docs/tasks/30-screens-live-search-profile.md` (Profile and Settings) and
   `docs/tasks/50-screens-editor-posting-safety-admin.md`.
3. **Study the two finished screens before writing anything:** `VybeKit/Sources/ModerationFeature/Report/` (SC-R1) and
   `.../BlockConfirm/` (SC-R2): view, view model, previews, tests, strings, and how each is wired in
   `ModerationScreens.swift`. Match their structure, naming and quality.

## 1. Your screens, in this order
You own only these folders: `ProfileFeature/`, `EditorFeature/`, `PostingFeature/`, `ModerationFeature/`
(plus their tests under `VybeKit/Tests/<Name>FeatureTests/`).

1. SC-PR2 Settings root
2. SC-ST-A Account settings and Delete account (ST1, ST8)
3. SC-ST-C Help, My Place suggestions, About (ST5, ST6, ST7)
4. SC-PR1 My profile
5. SC-PR4 Saved
6. SC-PR5 Drafts
7. SC-PR6 Edit profile
8. SC-PR8 Ready to post
9. SC-E2 Add Spot, then SC-E1 Hangout editor, then SC-E3 Suggest a Place
10. SC-PO1 Post composer, then SC-PO2 Edit post
11. SC-AD1 Admin reports queue, then SC-AD2, SC-AD3
12. **SC-ST-B Privacy, Blocked, Notifications (ST2, ST3, ST4): do the Blocked and Notifications pages. For Privacy, STOP
    and do not build it.** Write the list of privacy options you propose (each with its default, in plain words, from
    `docs/IA.md` and the `UserProfile` model) into the report, and leave the placeholder in place. Lohitaksh must approve the
    options first.

SC-R1 and SC-R2 are already done. Do not redo them.

## 2. Decisions already made (do not re-ask)
- **No Figma frames exist.** Build from `docs/IA.md`, the task text and the existing components.
- **Admin screens (AD1 to AD3)** are reachable only by `-debugRoute` in DEBUG builds. Do **not** add any entry in Settings.
- **Blocking:** `router.present(.blockConfirm(userID))`. Blocked list (ST3): rows with an Unblock button calling
  `safety.unblock(id)` then `session.unblock(id)`.
- **Report:** `router.present(.report(target))` where target is run, comment, user, message, place or hangout.
- **Offline:** `deps.network.isOffline`. Disable actions that need a connection while it is true.
- **Safety defaults** (nudity, self-harm, violence hide content at once) must never be weakened.
- Posting rules come from `Core/Rules/HangoutRules.swift` (2 to 10 Spots, 70% for Remix credit, at least 2 visited Spots, 2 photos
  per visited Spot, 30 minutes after the Hangout ends). Use them, never copy them into a view model.
- Exact visit times (`RunTimes`) are owner-only: never show them to other people, and never import them in Community or Friends.

## 3. Hard limits (stop and put it in the report instead of doing it)
Never edit `Models/`, `Core/`, `Design/`, `Components/`, `Package.swift`, the App target (`Vybe/`), the Xcode project or another
feature's folder. If a screen needs a change there, build the most useful version you can without it, and add a line to
the report under "Needs from Lohitaksh" with the exact change you want. The only allowed edit outside your folders is
adding rows to `VybeTests/AppShellTests.swift` for the screens you build (use the `"view:YourViewName"` pattern, see how
`ReportView` is listed).
No third-party libraries. No `print` (use `os.Logger`). No hex colours, no `.system(size:)` fonts, no hard-coded spacing numbers.
No invented data: places, coordinates, hours, prices and photos must be real or clearly labelled sample data.
Vocabulary: Hangout, Spot, Remix, Picks, "Start Hangout". Never Plan, Trace, outing, Stop, Fork, Featured, Curated.
`@unchecked Sendable`, `nonisolated(unsafe)` and hand-written `nonisolated` are forbidden.

## 4. For each screen: the routine
1. Generate the files: `python3 scripts/new_screen.py <Feature> <Screen>`, then replace only your screen's placeholder
   `case` in `<Name>Screens.swift`.
2. ViewModel first (state, one method per tap, view-ready values, injected `now`/`makeID`, load in `.task`, a failed refresh
   keeps the content, cancellation is not an error), then the View (layout only).
3. Strings in the feature's `Localizable.xcstrings` (keys like `profile.settings.title`); every `Text` and
   `String(localized:)` has `bundle: #bundle` (never `#bundle` in tests).
4. Previews: loaded, empty, error, loading, one at `.dynamicTypeSize(.accessibility3)`, using real Kothrud names.
5. ViewModel tests (Swift Testing): every action, every state, every rule in the task's "Done when".
6. Build, then **look at it in the simulator**: `scripts/snap.sh <name> <route> all` (short forms are in
   `Vybe/App/LaunchOptions.swift`; add a short form there only if one is missing and tell me in the report). Open the
   screenshots and judge them with the checklists in sections 5 and 6. Fix, rebuild and look again until they are right.
7. `./scripts/check.sh` must pass (SwiftLint, architecture rules, tests). Never silence, skip or weaken a check. If it still
   fails after three honest attempts on one screen, commit nothing for it, record the failure and go to the next screen.
8. Commit: `SC-xx: what it does`, with the files listed in the body.

## 5. Button and tap-target protocol (do this for every screen, the lead has been burned by bad button sizes)
**Rules**
- Full-width actions use the shared `PrimaryButton` or `SecondaryButton`. They render the standard large size, about
  **51 pt** tall with a **44 pt** floor. Do not wrap them in frames, add vertical padding to make them bigger, or re-style them.
- Any custom button uses a system style with `.controlSize(.large)` plus `.frame(minHeight: Theme.Size.minTapTarget)`
  on the **button**, never inside its label. A fixed `.frame(height:)` or `.frame(width:)` on anything tappable is a bug,
  unless the value is a `@ScaledMetric`.
- Every tappable thing is at least **44 x 44 pt**, including icon-only buttons (use `IconButton`, with an
  `accessibilityLabel`), toolbar items, list rows (single line rows at least 44 pt, the existing Report rows are 52 pt) and
  chips.
- One primary action per screen or bar. At most two stacked buttons (primary above secondary, 8 pt apart). Side margin 16 pt.
  A bottom action bar uses `.safeAreaInset(edge: .bottom)` with `.background(.bar)`.
- Destructive actions (delete, block, sign out) use `role: .destructive` with the critical colour and are confirmed with a
  `confirmationDialog` or alert. Never make a destructive button the prominent default of a form.
- A disabled button must still be readable. A loading button shows a `ProgressView` and is disabled. Button text wraps at large
  text sizes; it is never truncated and never shrinks.
**Check (write the results into the report)**
- Run this on your files and justify every hit: `grep -nE "\.frame\((width|height):" <your Sources folders>`.
- In each screenshot (iPhone 18 Pro: 402 x 874 pt at 3x, so a 1206 x 2622 px image; points = pixels / 3), estimate the height
  of every button from the image. Primary and secondary buttons must come out between 48 and 56 pt. List the numbers.

## 6. Apple HIG and standard checklist (state pass or fail per screen in the report)
- Layout: safe areas respected; nothing under the home indicator or notch; no fixed screen widths; works on the smallest
  iPhone and at `.accessibility3`; reading margins of 16 pt; consistent 8 pt rhythm from `Theme.Spacing`.
- Hierarchy: one clear title (large or inline as HIG suggests for the context), one hero element, headings marked with
  `.accessibilityAddTraits(.isHeader)`. Lists and settings use the grouped inset style with `NavRow`, `ToggleRow`, `InfoRow`.
- System components for the tab bar, navigation bars, sheets, alerts, pickers, `PhotosPicker`. Standard back button and swipe-back.
  Sheets get a drag indicator and sensible detents. Do not restyle system chrome.
- Typography: `Theme.Font` styles only, Dynamic Type supported, spacing that should grow uses `@ScaledMetric`.
- Colour: `Theme.Color` only. Light mode only. Never colour alone for meaning (add an icon or word). Contrast at least 4.5:1 for text.
- Accessibility: every icon-only control, photo and map pin has a label; VoiceOver reads in a sensible order; state is spoken
  (selected, disabled, loading); Reduce Motion respected by using `vybeAnimation`; no information shown only by motion.
- Motion and haptics: `Theme.Motion` tokens only; one hero moment per screen; haptics only with their Apple meaning (`vybeHaptic`).
- Forms: labels visible (not placeholder-only), inline error text near the field, the right keyboard type, `scrollDismissesKeyboard`,
  Return key behaviour, the Send/Save button stays reachable above the keyboard, no data lost on a failed save.
- States: every data screen has loading (skeleton), empty (`EmptyStateView` with a next step), error (`ErrorView` with retry) and a
  stale/offline state. Pull to refresh where it is a list.
- Privacy and safety: no personal data in logs; location only through `LocationService`; photos only through `PhotoProcessor`;
  nothing that shows exact visit times to others.
- Images: real aspect ratios through `PlaceImage`/`PhotoGallery` with `ImageLoader`; never stretched.
- Text: our tone (short, warm, plain); no lorem ipsum; money, distance and time through `.formatted(...)` (₹, km).

## 7. The report (your last step)
Write `docs/work-orders/WO-3-report.md` and commit it. For each screen: status (done, partly, skipped), files touched, number of
tests, the three screenshot paths (`build/screenshots/...`), the measured button heights, the pass/fail checklist from section 6,
anything that looks off to you, and what you would change. Then three lists: **Needs from Lohitaksh** (shared changes you could
not make), **Decisions I need** (for example the privacy options), and **Risks I saw**. End with the output of `git log --oneline`
and the final `./scripts/check.sh` result pasted as text. Do not claim anything you did not run.
Reply to me with a short summary and the path of the report.
