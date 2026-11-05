# Work order 3: Profile, Editor, Posting and Safety

**Your own space, making Hangouts, posting them, and keeping people safe.** Size: 23 screens or pages, about 37 points
(S=1, M=2, L=3).

**You own these feature folders (and nobody else edits them):**
`ProfileFeature/`, `EditorFeature/`, `PostingFeature/`, `ModerationFeature/`

Every screen below depends only on screens in this list, plus things that are already merged (router, stubs, sample data,
Hangout rules F-6, PhotoProcessor F-13, components, design system). You never wait for a teammate's screen.

## Before you start (once)
1. `git checkout main && git pull`, then read `AGENTS.md`, `docs/SCREENS-GUIDE.md`, and your task in `docs/tasks/`
   (`50-screens-editor-posting-safety-admin.md` and the Profile part of `30-screens-live-search-profile.md`).
2. Your AI tool plans first, you say OK, then it builds (AGENTS.md section 1).
3. **Safety defaults are never weakened without a human** (`docs/RISKS.md`). Nudity, self-harm and violence reports hide the
   content at once. That is in code already; the Report screen must use it, not replace it.
4. The posting rules are already in `Core/Rules/HangoutRules.swift` (2 to 10 Spots, at least 2 visited Spots to post, 2 photos
   per visited Spot, posts appear 30 minutes after the end, Remix credit needs 70% of the original's Places). Use them; do
   not re-write them in a ViewModel.
5. Camera and photo permission text is X-9, done by Lohitaksh. Build the photo parts against `PhotoProcessor` and stubs
   until then.

## Build order (each line only needs the line above it)
| # | Screen | Size | Folder | Needs from this list |
|---|---|---|---|---|
| 1 | **SC-PR2** Settings (root) | M | `ProfileFeature/Settings` | nothing |
| 2 | SC-ST-A Account settings, delete account | M | `.../SettingsPages`, `.../DeleteAccount` | nothing |
| 3 | SC-ST-B Privacy, Blocked, Notifications | M | `.../SettingsPages` | nothing |
| 4 | SC-ST-C Help, Place suggestions, About | S | `.../SettingsPages` | nothing |
| 5 | **SC-PR1** My profile | L | `.../Profile` | nothing |
| 6 | SC-PR4 Saved | M | `.../Saved` | nothing |
| 7 | SC-PR5 Drafts | M | `.../Drafts` | nothing |
| 8 | SC-PR6 Edit profile | M | `.../EditProfile` | nothing |
| 9 | SC-PR8 Ready to post | M | `.../ReadyToPost` | nothing |
| 10 | **SC-E2** Add Spot | M | `EditorFeature/AddSpot` | nothing. **Before E1.** |
| 11 | **SC-E1** Hangout editor | L | `.../Editor` | E2 |
| 12 | SC-E3 Suggest a Place | M | `.../SuggestPlace` | nothing |
| 13 | **SC-PO1** Post composer | L | `PostingFeature/Composer` | nothing |
| 14 | SC-PO2 Edit post | M | `.../EditPost` | nothing |
| 15 | **SC-R1** Report | M | `ModerationFeature/Report` | nothing. **Before R2.** |
| 16 | SC-R2 Block confirm | S | `.../BlockConfirm` | R1 |
| 17 | **SC-AD1** Admin: reports queue | M | `.../Admin` | nothing. **Before AD2 and AD3.** |
| 18 | SC-AD2 Admin: Place suggestions | S | `.../Admin` | AD1 |
| 19 | SC-AD3 Admin: users | S | `.../Admin` | AD1 |

(The three Settings pages SC-ST-A, B and C share the `SettingsPages` folder, so build them in the order above and in one
branch each, or the same person does them back to back.)

Easy chains to remember: E2 then E1. R1 then R2. AD1 then AD2 and AD3.

## Rules for every screen (from AGENTS.md)
- Replace only your screen's placeholder `case` in `<Name>Screens.swift`. Do not edit `Core/Navigation`, `Models`,
  `Package.swift`, the App target or another feature. If you need a change there, ask Lohitaksh.
- Other people's screens open Report and Block through the router (`.report(...)` sheet). That is your contract: keep the
  route and sheet names as they are.
- View + ViewModel + previews (loaded, empty, error, large text) + a ViewModel test + `./scripts/check.sh` + a PR with
  screenshot and "In my own words" written by you.
- Get a screenshot with `scripts/snap.sh <name> <route> all`, for example `scripts/snap.sh settings settings all`
  (short forms are listed in `Vybe/App/LaunchOptions.swift`).
- Branch: `<initial>/<task-id>-<short-name>`, PR title `SC-PR2: what it does`. Small PRs, squash-merge.

## Shared pieces added on 5 Nov (use these, do not rebuild them)
- **Block a person:** `router.present(.blockConfirm(userID))` opens SC-R2 (a small sheet). After it succeeds
  `session.isBlocked(id)` is true everywhere. Unblock: `safety.unblock(id)` then `session.unblock(id)`.
- **Report a whole Hangout:** `router.present(.report(.hangout(hangoutID)))`. Other targets: run, comment, user, message, place.
- **Offline:** `deps.network.isOffline` (a `NetworkMonitor`). Disable actions that need a connection while it is true.
- **Card-to-detail zoom:** put `.vybeZoomSource(id: hangout.id)` on the tapped card and
  `.vybeZoomDestination(sourceID: hangout.id)` on the screen that opens. Nothing else is needed.
- **Buttons:** `PrimaryButton` and `SecondaryButton` are now the standard large size (about 51 pt tall, 44 pt minimum).
  Never set a fixed height on a button.
- **Looking up another person:** `deps.profiles.profile(id:)` now knows the sample social people too.
