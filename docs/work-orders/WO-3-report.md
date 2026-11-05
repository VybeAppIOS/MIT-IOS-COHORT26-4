# WO-3 report: Profile, Editor, Posting and Safety (UNVERIFIED DRAFT)

**Read this first.** Every screen below was written **without Xcode or a Mac**. Nothing here has been compiled, run, tested
or looked at on a screen. Every line about a build, a test run, a screenshot, `check.sh` or a button height says
**not run (no Xcode)**. "Pass" in the checklist below means "passes by reading the code", never "seen working".

- Branch: `l/wo3-screens`, based on `origin/main`, pushed after every screen. No PR, no merge, nothing on `main`.
- Method: real signatures were grepped before use, and patterns were copied from `ModerationFeature/Report` and
  `BlockConfirm`. Swift 6 rules: view models are `@MainActor @Observable final class`; there is no `@unchecked Sendable`,
  no `nonisolated(unsafe)` and no hand-written `nonisolated`; data loads in `.task`.
- What did run (on Linux, no Swift compiler): `scripts/new_screen.py`, `scripts/check_architecture.sh`,
  `scripts/check_architecture_selftest.sh`, and text checks: line length, banned words, catalog keys and JSON, the frame grep,
  and preview/test files present. Their output is at the end.

## 1. Screens

| # | Task | Status | Folder | Tests written | Screenshots | Button heights |
|---|---|---|---|---|---|---|
| 1 | SC-PR2 Settings | done (draft) | `ProfileFeature/Settings` | 5 | not run (no Xcode) | not run (no Xcode) |
| 2 | SC-ST-A Account, Delete account | done (draft) | `ProfileFeature/SettingsPages`, `ProfileFeature/DeleteAccount` | 6 + 5 | not run (no Xcode) | not run (no Xcode) |
| 3 | SC-ST-C Help, My suggestions, About | done (draft) | `ProfileFeature/SettingsPages` | 2 + 4 + 4 | not run (no Xcode) | not run (no Xcode) |
| 4 | SC-PR1 My profile | done (draft) | `ProfileFeature/Profile` | 6 | not run (no Xcode) | not run (no Xcode) |
| 5 | SC-PR4 Saved | done (draft) | `ProfileFeature/Saved` | 7 | not run (no Xcode) | not run (no Xcode) |
| 6 | SC-PR5 Drafts | done (draft) | `ProfileFeature/Drafts` | 5 | not run (no Xcode) | not run (no Xcode) |
| 7 | SC-PR6 Edit profile | partly (photo picked but not stored) | `ProfileFeature/EditProfile` | 9 | not run (no Xcode) | not run (no Xcode) |
| 8 | SC-PR8 Ready to post | done (draft) | `ProfileFeature/ReadyToPost` | 5 | not run (no Xcode) | not run (no Xcode) |
| 9 | SC-E2 Add Spot | done (draft) | `EditorFeature/AddSpot` | 5 | not run (no Xcode) | not run (no Xcode) |
| 10 | SC-E1 Hangout editor | done (draft) | `EditorFeature/Editor` | 11 | not run (no Xcode) | not run (no Xcode) |
| 11 | SC-E3 Suggest a Place | partly (sending is a logged stub) | `EditorFeature/SuggestPlace` | 7 | not run (no Xcode) | not run (no Xcode) |
| 12 | SC-PO1 Post composer | done (draft) | `PostingFeature/Composer` | 8 | not run (no Xcode) | not run (no Xcode) |
| 13 | SC-PO2 Edit post | partly (library only, not the feed) | `PostingFeature/EditPost` | 5 | not run (no Xcode) | not run (no Xcode) |
| 14 | SC-AD1 Admin reports | partly (no hide/restore/warn call) | `ModerationFeature/Admin/Reports` | 7 | not run (no Xcode) | not run (no Xcode) |
| 15 | SC-AD2 Admin Place suggestions | done (draft) | `ModerationFeature/Admin/Suggestions` | 6 | not run (no Xcode) | not run (no Xcode) |
| 16 | SC-AD3 Admin users | partly (no ban state, no note) | `ModerationFeature/Admin/Users` | 6 | not run (no Xcode) | not run (no Xcode) |
| 17 | SC-ST-B Blocked | done (draft) | `ProfileFeature/SettingsPages` | 4 | not run (no Xcode) | not run (no Xcode) |
| 17 | SC-ST-B Notifications | built, **not wired** (no storage) | `ProfileFeature/SettingsPages` | 3 | not run (no Xcode) | not run (no Xcode) |
| 17 | SC-ST-B Privacy | **skipped on purpose** (options in section 5) | placeholder kept | 0 | none | none |

That is 120 tests written in 21 files, none of them run. Every screen has a View, a ViewModel, a `+Preview.swift` file
(loaded, empty or error, and large text where it applies) and a test file. Every screen is wired only through its
feature's `Screens` file. The only file outside my folders is `VybeTests/AppShellTests.swift`, where 18 `"view:…"` rows were
added or replaced. `Vybe/App/LaunchOptions.swift` was not changed: no short form was missing.

**Files outside the screen folders:** the four `Localizable.xcstrings` catalogs (Profile 149 keys, Editor 60, Posting 40,
Moderation 94; all valid JSON), the four `*Screens.swift` files, and `VybeTests/AppShellTests.swift`.

## 2. Apple HIG checklist (section 6), per screen

Each cell is judged **by reading the code only**: P = pass, F = fail, ? = needs a real screen. Nothing was seen.
Every "works at `.accessibility3` / smallest iPhone" and contrast item is **? (not run, no Xcode)** for every screen, so it is
left out of the table.

| Screen | Layout | Hierarchy | System comps | Type | Colour | A11y | Motion | Forms | States | Privacy | Images | Text |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PR2 Settings | P | P | P | P | P | P | P | n/a | n/a | P | n/a | P |
| ST1 Account | P | P | P | P | P | P | P | n/a | P (offline off) | P | n/a | P |
| Delete account | P | P | P | P | P | P | P | P | P (offline off) | P | n/a | P |
| ST5 Help | P | P | P | P | P | P | P | n/a | n/a | P | n/a | ? (placeholder text "Added before launch") |
| ST6 My suggestions | P | P | P | P | ? (red "Not added") | P | P | n/a | P | P | n/a | P |
| ST7 About | P | P | P | P | P | P | P | n/a | P | P | P | P |
| PR1 Profile | P | P | P | P | P | P | P | n/a | P | P | P | P |
| PR4 Saved | P | P | P | P | P | P | P | n/a | P | P | P | P |
| PR5 Drafts | P | P | P | P | P | P | P | n/a | P | P | P | P |
| PR6 Edit profile | P | P | P | P | P | P | P | F (Return key not set on every field) | F (no offline handling for the username check) | P | ? (no thumbnail) | P |
| PR8 Ready to post | P | F (one Post button per card, so several prominent buttons) | P | P | P | P | P | n/a | P | P (times on my own screen only) | n/a | ? ("1 photos") |
| E2 Add Spot | P | P | P | P | P | P | P | n/a | P | P | P | P |
| E1 Editor | P | P | P | P | P | ? (Stepper and reorder order for VoiceOver) | P | F (no Return key or submitLabel) | P | P | n/a | P |
| E3 Suggest a Place | P | P | P | P | P | ? (map has a label, but the pin is hidden) | P | F (no Return key) | F (Send not disabled offline) | P (PhotoProcessor) | n/a | P |
| PO1 Composer | P | P | P | P | P | P | P | F (no Return key) | P | P (no visit times on the post) | P | P |
| PO2 Edit post | P | P | P | P | P | P | P | F (no Return key) | P | P | P | P |
| AD1 Reports | P | P | F (local detail sheet has no detents or drag indicator) | P | P (icon + words for urgency) | P | P | n/a | F (actions not disabled offline) | P | n/a | P |
| AD2 Suggestions | P | P | F (review sheet has no detents or drag indicator) | P | P | P | P | ? (number pads; no Return key) | F (actions not disabled offline) | P | n/a | P |
| AD3 Users | P | P | P | P | P | P | P | P (search submit) | F (Ban/Unban not disabled offline) | P | n/a | P |
| ST3 Blocked | P | P | P | P | P | P | P | n/a | P (offline off) | P | P (Avatar) | P |
| ST4 Notifications | P | P | P | P | P | P | P | n/a | P | P (no permission prompt here) | n/a | P |

"States" means loading, empty and error, through `LoadStateView`. The stale/offline banner is Phase 2, and I did not check
how `LoadStateView` draws `isStale`. The loading skeletons are mostly a redacted list with one line. That is weak, and
each one needs a look.

## 3. Least sure it compiles (API, file and line)

Line numbers are from the pushed branch. These are the first places to look when Xcode opens.

1. **Imports that leak.** `ComponentStrings` lives in **Design**, and there is no `@_exported`. I added `import Design` to
   `EditorFeature/AddSpot/AddSpotViewModel.swift:3`, `SuggestPlace/SuggestPlaceViewModel.swift:3` and
   `PostingFeature/Composer/ComposerViewModel.swift:3`, plus `import Components` to `EditProfileView.swift:1`. Other files may
   still use a type from a module they do not import. A scan by type name found nothing else, but it is only a text scan.
2. `SuggestPlaceView.swift:86`: `.onMapCameraChange(frequency: .onEnd) { context in context.region.center }`, and
   `Map(position:)` with an `MKCoordinateRegion` camera (`:17`).
3. `AdminReportsViewModel.swift` `timeLeftText`, and `AdminSuggestionsViewModel.swift` `row(_:)`:
   `Duration.seconds(Int).formatted(.units(allowed:width:maximumUnitCount:))`.
4. `AdminReportsViewModel.swift` `reasonText`: `String(describing: ReportReason.selfHarm)` must give `"selfHarm"` to reach
   the Report screen's keys. If it gives the raw value instead, the reasons show as keys.
5. `ComposerView.swift:94`, `EditPostView.swift:68` and `EditorView`: `.onMove` on a `ForEach` inside a Section, outside edit mode.
6. `AdminSuggestionsView.swift:73`: `TextField(String, value: $viewModel.draft.costLower, format: .number)` through an
   `@Observable` class's struct property, and `Picker` with `$viewModel.draft.category`.
7. `ComposerView.swift:24`, `EditPostView.swift:34` and `:41`, `AdminUsersView.swift:23`:
   `.confirmationDialog(String, isPresented:titleVisibility:actions:message:)`, two of them on one view in PO2, and a
   `role:` given a ternary of `ButtonRole?` in AD3.
8. `NotificationsView.swift:18`: `ToggleRow(..., isOn: Binding(get:set:))`, where `set` starts a `Task`.
9. Closures typed `@MainActor (…) async throws -> …` and stored on view models: `submit` (E3), `loadChoices`/`saveChoices`
   (ST4), `act(_:)` (AD2). The features build with `defaultIsolation(MainActor)` and `NonisolatedNonsendingByDefault`, so
   this should be fine, but it is the likeliest Swift 6 error.
10. `EditPostViewModel.swift` `spotNames`: `try? await places.place(id:).name` (how `try?` and `await` group), and
    `String(format:)` with `%lld. %@` and a Swift `String`.
11. Earlier screens, from my notes: `ReadyToPostView`, a generic `section<Actions>` with an `@escaping @ViewBuilder` closure;
    `ProfileView`, `.sheet(item: $viewModel.editing, onDismiss:)` with `UserProfile` as the item; `EditProfileView`,
    `PhotosPicker` + `loadTransferable(type: Data.self)`; `AboutViewModel`, a main-actor static used as a default argument;
    `DraftsViewModel`, a computed get/set `isConfirmingDelete` used as a binding.
12. Tests: `catch AppError.notFound` patterns (Saved, AD3); `state == .failed(.notFound)` (this needs `LoadState: Equatable`
    where `Content: Equatable`; the Editor tests already rely on it).

## 4. Look at this on a real screen (three per screen)

- **PR2 Settings:** NavRow inside a grouped List (double padding?); the red Reset onboarding row; the footer's length.
- **ST1 Account / Delete:** the Delete button in the bottom bar reads as destructive but is not the default; the "Type sample.me
  to confirm" label; the sign-out spinner's alignment.
- **ST5/6/7:** Help is mostly "Added before launch" (it must not look broken); a long credit in About; the red "Not added" in My
  suggestions may feel harsh.
- **PR1 Profile:** the empty banner band; spacing of the library rows; the height of the empty "My Hangouts" area.
- **PR4 Saved:** card insets inside List rows; the Undo bar sits above the tab bar; how an unavailable row looks.
- **PR5 Drafts:** StatusBadge spacing; the "+" toolbar target (44 pt); the swipe-delete confirmation.
- **PR6 Edit profile:** the picker rows (a "Ready" tick only, no thumbnail); the bio counter and error at large text; 12
  interest chips wrapping.
- **PR8 Ready to post:** several prominent Post buttons when there are several runs (maybe make them SecondaryButton);
  "1 photos"; whether the disabled Post and its reason are readable.
- **E2 Add Spot:** the chip row scrolling inside a list row; the "Can't find it?" bar; a tap closing the sheet with no feedback.
- **E1 Editor:** tall Spot rows (SpotRow + Stepper + note); EditButton in the section header; the disabled Done.
- **E3 Suggest a Place:** the pin's tip sits about half a pin below the true centre; the map height at large text; the category
  row is at least 44 pt.
- **PO1 Composer:** the preview card inside a List row; the Post bar with its reason line; set-aside photos at the limit.
- **PO2 Edit post:** the Spots read as read-only; Delete post stands alone in red; the disabled Save.
- **AD1 Reports:** urgent rows (triangle + clock + words); the detail sheet's three buttons (two red); how Duration's
  "1 hr, 20 min left" reads.
- **AD2 Suggestions:** the order of fields and the number pads; the reject buttons clearly apart from Approve; long notes in
  the list.
- **AD3 Users:** the search bar under the title on push; Ban and Unban side by side; the result note.
- **ST3 Blocked:** the Unblock button against two-line names; the offline note; the empty state.
- **ST4 Notifications:** (once wired) the switches at large text; the footer's wording; the error note.

## 5. Decisions I need

**Privacy (ST2): not built.** Here are the options I propose. They come from `docs/IA.md`, `docs/RISKS.md` 3 and the existing
`UserSettings` model. The defaults already match the model, and none is weaker than RISKS 3.

| Option (plain words) | Choices | Proposed default | Where it is stored |
|---|---|---|---|
| Private profile: "All your posts become friends-only, and only friends see your profile" | on / off | **off** | `UserProfile.isPrivate` |
| Who sees my new posts at first | Friends / Everyone (Everyone shows a one-line warning) | **Friends** | `UserSettings.defaultAudience` |
| Who can comment on my posts | Everyone / Friends / Nobody | **Friends** | `UserSettings.whoCanComment` |
| Who can send me friend requests | Everyone (no mutual friends go to "Other") / Friends of friends | **Everyone** | `UserSettings.whoCanSendRequests` |
| Who can add me to group chats | Friends / Ask me / Everyone | **Ask me** | `UserSettings.whoCanAddMeToGroups` |
| Show me in search and "You might know" | on / off | **on** | `UserSettings.showMeInSearch` |

Open points for Privacy: there is no `ProfileRepository` call to save `settings` yet (check before building), and should
turning on a private profile also flip existing public posts' `audience` to friends?

**Other decisions:**
1. **Report urgency (AD1).** How each reason maps to a deadline, proposed in `Admin/Reports/ReportUrgency.swift`:
   - **2 h:** nudity, photo of me without consent, possibly under 18.
   - **36 h:** self-harm, violence, hate, harassment, illegal goods, private address, impersonation, copyright.
   - **7 days:** spam, scam, unsafe Place, something else.
   - The 3 h tier for government and court orders has no `ReportReason`.
   - Should the team see the reporter's ID? It is not shown now.
2. **Notification defaults (ST4):** all five on (friend requests, messages, likes, comments, reminders)?
3. **Username rules (PR6):** 3 to 30 characters, a-z 0-9 . _, no dot at the start or end, no "..". Is that right?
4. **Interests (PR6):** the list of 12. Does it match Onboarding O3?
5. **Tags (E1, PO1, PO2):** good for groups, budget friendly, rainy day, date idea, fine alone. **Best times (E1):** morning,
   afternoon, evening, night.
6. **PO1 photos left out:** they are dropped from the run when posting, because `HangoutRun` has only `photos`. Should they be
   kept privately instead?
7. **PO1 audience word:** "Everyone" for `Visibility.public`. Should the composer start from `settings.defaultAudience`
   instead of the run's `visibility`? Both are Friends today.
8. **PO2:** tags that are not one of the five are dropped on save. Is that OK?
9. **AD2:** the approved Place's ID is `"place-" + suggestion ID`; the city is fixed to "Pune"; and the wording of the
   residential reject note is sent to the person.

## 6. Needs from Lohitaksh (shared places I must not edit)

1. **Notification storage:** add keys in `Core/Services/AppSettings.swift` (or `UserSettings`), then wire
   `ProfileScreens.settingsPage(.notifications)` with `NotificationsViewModel(loadChoices:saveChoices:)`. It is one line; the
   screen and its tests are done.
2. **`FeedRepository.updatePost(_:)` and `deletePost(_:)`.** PO2 edits and deletes my own run in `LibraryStore` only. The task's
   "removes the post from the feed stub" cannot be met, and comments are not deleted, even though the confirmation says they go
   with the post.
3. **`AdminRepository`** needs `hide(_ target:)`, `restore`, `warn(_ user:)`, an `isBanned`/ban-state read, and a `note:` on
   `ban`/`unban`. AD1 "Hide content" only marks the report actioned. AD3 cannot show whether someone is banned.
4. **A debug launch flag for `isTeamAccount`.** `-debugRoute` opens AD1 to AD3 with the preview session, which is not a team
   account, so they show "team only". The change goes in Core's session setup or `Vybe/App/LaunchOptions.swift`.
5. **`AdminPage.users(prefill: String?)`, or a route with a username,** so "Ban the owner…" in AD1 opens AD3 already searched.
6. **`PlaceRepository.suggest(_ suggestion: PlaceSuggestion)`.** E3 only logs "sent (stub)" through `Log.app`, with no
   personal data.
7. **`PhotoStore.save(_ processed: ProcessedPhoto) async throws -> Photo`.** PR6 (photo and banner) and E3 (the suggestion
   photo) process the picture but cannot store it.
8. **`FeedRepository.posts(by:)`.** PR1 pages the whole feed and filters it by me, up to 20 pages.
9. **`ProfileRepository.deleteCurrent()` or `LibraryStore.clearAll()`.** Delete account cannot remove `profile.json` or run
   photos from a feature.
10. **`SessionStore.setArea(_:)`, and a chosen area for Add Spot.** E2 reads `places(in: "Kothrud")`, hard-coded.
11. **A user-facing `mySuggestions()`.** ST6 reads `AdminRepository.placeSuggestions()` filtered by submitter. That will break
    once the server limits admin calls to the team.
12. **Shared words in Design `SharedStrings`:** the five tag words are copied in Editor and Posting, and the interests list
    should be shared with Onboarding.
13. **Toast API:** PO1's "Scheduled for 8:30 pm" appears only as the Ready to post row text.
14. **Help (ST5) content:** the support email, grievance officer, and Terms and Privacy links (BK-13, lawyer).

## 7. Risks I saw

- **Nothing is compiled.** Expect a first round of errors, most likely missing imports (section 3, item 1) and closure
  isolation (item 9). Fix those before judging the screens.
- **Tests are unrun.** Some depend on stub details I read but could not execute:
  - the sample report times (4 h and 9 h ago);
  - pending suggestions coming oldest first;
  - `liveStore.end()` setting `endedAt` from the stub clock.
- **Offline is not handled** on E3, AD1, AD2, AD3 and PR6 (section 2), although the decision says actions are disabled offline.
- **PO1 and PO2 write straight to `LibraryStore`.** When the backend arrives, posting must go through a repository, or
  scheduled posts will never reach the server.
- **E2 into E3:** "Can't find it?" dismisses a local sheet and presents the router sheet in the same moment. On a device this
  may need a short delay.
- **PR8** shows several prominent buttons at once, which breaks "one primary action".
- **Previews** for PO1, PO2 and ST3 build their data in `.task`, so they show a spinner first; a canvas snapshot may catch only
  that.
- **Safety defaults are unchanged.** Auto-hide stays in `ReportReason.hidesContentImmediately` and AD1 only reads it. Posts
  default to Friends, Everyone asks first, and the post delay comes from `HangoutRules`. Exact visit times never leave
  `RunTimes`: the composer's preview card has no day or time.

## 8. Checks run (pasted output)

`scripts/new_screen.py` made the skeleton of every screen. The generator's `.title`/`.empty` keys were removed or reused.
Then, on the 90 Swift files this branch changes:

```
== architecture
==> Architecture rules passed
==> Architecture check self-test passed
== long lines
== banned words
== keys
missing keys: 0
== frame width/height
VybeKit/Sources/EditorFeature/AddSpot/AddSpotView.swift:73:                    .frame(width: thumbnailSize)
VybeKit/Sources/EditorFeature/SuggestPlace/SuggestPlaceView.swift:77:                .frame(height: mapHeight)
VybeKit/Sources/PostingFeature/Composer/ComposerView.swift:118:                .frame(width: thumbWidth)
VybeKit/Sources/PostingFeature/EditPost/EditPostView.swift:114:                .frame(width: thumbWidth)
== forbidden
done
== catalogs JSON
ProfileFeature 149 keys, valid JSON
EditorFeature 60 keys, valid JSON
PostingFeature 40 keys, valid JSON
ModerationFeature 94 keys, valid JSON
Text()/dynamic-prefix keys missing: 0
```

Every frame hit is justified. All four are `@ScaledMetric` sizes on **images**, not buttons: the Add Spot thumbnail, the Suggest a
Place map, and the photo thumbnails in PO1 and PO2. No button has a fixed frame. Custom buttons use
`.frame(minHeight: Theme.Size.minTapTarget)`.

The preview and test check found a View, a `+Preview.swift` and a `…ViewModelTests.swift` for all 21 view models.

`./scripts/check.sh` (SwiftLint + tests on a simulator): **not run (no Xcode)**.
Build: **not run (no Xcode)**. Simulator screenshots (`scripts/snap.sh`): **not run (no Xcode)**.
Button heights: **not run (no Xcode)**.

## 9. git log --oneline (origin/main..l/wo3-screens)

```
6ba2a2d SC-ST-B: Blocked and Notifications pages (draft, not compiled)
61e9547 SC-AD3: Admin users (draft, not compiled)
584bca5 SC-AD2: Admin Place suggestions (draft, not compiled)
7164907 SC-AD1: Admin reports queue (draft, not compiled)
0d227e9 SC-PO2: Edit post (draft, not compiled)
e9fb94b SC-PO1: Post composer (draft, not compiled)
3b92253 SC-E3: Suggest a Place (draft, not compiled)
b512e13 SC-E1: Hangout editor (new, Draft, Remix) with autosave, validation, reorder and Remix credit
6126a3c SC-E2: Add Spot sheet with category chips; adding a Place makes a Spot with a stable ID
2866fe8 SC-PR8: Ready to post with Post (off below 2 visited, with the reason), Delete and Cancel schedule
20b4ce2 SC-PR6: Edit profile sheet with username rules, 30-day hold note, bio limit and interests
d35a5d9 SC-PR5: Drafts with confirmed delete, edit in the editor cover, and New Hangout
43d8f11 SC-PR4: Saved Hangouts with swipe to unsave, Undo and a no-longer-available row
3cde147 SC-PR1: My profile with header, live library counts and my posted Hangouts
2ce8d03 SC-ST-C: Help and contact, My Place suggestions, About and credits
2aa7081 SC-ST-A: Account settings (sign out) and Delete account (typed username, clears the phone)
97c5a13 SC-PR2: Settings root with every settings page and a confirmed Reset onboarding
```

The commits before SC-E3 do not say "(draft, not compiled)" in their titles, but they are just as unverified as the rest.

## 10. Next steps on a Mac

1. Open the project and build. Fix the compile errors, starting with section 3.
2. Run `./scripts/check.sh` and paste its output here.
3. Run `scripts/snap.sh <name> <route> all` for each screen. Measure the buttons and fill in section 1.
4. Go through section 4 on the screenshots. Change P/F/? in section 2 into what was really seen.
5. Only then open PRs, one per task, and have each author explain every line.
