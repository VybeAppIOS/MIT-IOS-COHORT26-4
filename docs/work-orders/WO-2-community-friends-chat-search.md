# Work order 2: Community, Friends, Chat and Search

**Everything social, plus finding things.** Size: 17 screens, about 33 points (S=1, M=2, L=3).

**You own these feature folders (and nobody else edits them):**
`CommunityFeature/`, `FriendsFeature/`, `ChatFeature/`, `SearchFeature/`

Every screen below depends only on screens in this list, plus things that are already merged (router, social stubs, sample
social data, components, design system). You never wait for a teammate's screen.

## Before you start (once)
1. `git checkout main && git pull`, then read `AGENTS.md`, `docs/SCREENS-GUIDE.md`, and your task in `docs/tasks/`
   (`40-screens-community-friends-chat.md` and the Search part of `30-screens-live-search-profile.md`).
2. Your AI tool plans first, you say OK, then it builds (AGENTS.md section 1).
3. Your data comes from the F-7 social stubs: 12 sample people, 8 posts (2 Picks), comment threads and 3 chats, all sharing one
   state (a like or a message shows up everywhere). Chat fakes an incoming message after 2 seconds.
4. Voice notes in the conversation (CH2) use F-15 (`AudioRecorder`, `AudioPlayer`); the microphone permission text is X-9,
   done by Lohitaksh. Build against the fake backend until then.

## Build order (each line only needs the line above it)
| # | Screen | Size | Folder | Needs from this list |
|---|---|---|---|---|
| 1 | **SC-CM1** Feed | L | `CommunityFeature/Feed` | nothing |
| 2 | SC-CM2 Post detail | L | `.../PostDetail` | nothing |
| 3 | SC-CM3 Comments | M | `.../Comments` | nothing |
| 4 | SC-CM4 Trending | S | `.../Trending` | nothing |
| 5 | SC-CM5 Activity | M | `.../Activity` | nothing |
| 6 | SC-FR1 Friends hub | M | `FriendsFeature/Hub` | nothing |
| 7 | SC-PR3 Other person's profile | M | `.../OtherProfile` | nothing |
| 8 | SC-PR7 Mutual friends | S | `.../MutualFriends` | nothing |
| 9 | SC-CH1 Chats list | M | `ChatFeature/List` | nothing |
| 10 | SC-CH3 New chat or group | M | `.../NewChat` | nothing |
| 11 | SC-CH4 Group info | M | `.../GroupInfo` | nothing |
| 12 | SC-CH5 Share to… | M | `.../ShareSheet` | nothing |
| 13 | SC-CH7 Group invitation | S | `.../Invitation` | nothing |
| 14 | **SC-CH6** Poll composer | S | `.../Poll` | nothing. **Before CH2.** |
| 15 | **SC-CH2** Conversation | L | `.../Conversation` | CH6 |
| 16 | **SC-S1** Search | L | `SearchFeature/Search` | nothing |
| 17 | SC-S2 See all | S | `.../SeeAll` | S1 |

Easy chains to remember: CH6 then CH2. S1 then S2.

## Rules for every screen (from AGENTS.md)
- Replace only your screen's placeholder `case` in `<Name>Screens.swift`. Do not edit `Core/Navigation`, `Models`,
  `Package.swift`, the App target or another feature. If you need a change there, ask Lohitaksh.
- Safety: a report goes through the Report screen (owned by work order 3) by route only (`router.present(.report(...))`).
  Never open another screen directly.
- View + ViewModel + previews (loaded, empty, error, large text) + a ViewModel test + `./scripts/check.sh` + a PR with
  screenshot and "In my own words" written by you.
- Get a screenshot with `scripts/snap.sh <name> <route> all`, for example `scripts/snap.sh feed community/feed all`
  (short forms are listed in `Vybe/App/LaunchOptions.swift`).
- Branch: `<initial>/<task-id>-<short-name>`, PR title `SC-CM1: what it does`. Small PRs, squash-merge.

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
