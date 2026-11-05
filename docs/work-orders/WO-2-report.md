# WO-2 report: Community, Friends and Chat

Branch: `a/wo2-screens`. **This copy of the report is on `a/wo2-search-alt`**, the Search alternative: it is `a/wo2-screens` plus the SC-S1 and SC-S2 Search screens (reapplied) and the Search fixes (items 20 to 25). It must merge after PR #53, and Tanvi may build on it or replace it. Written by Claude Code (Sonnet 5.5) for Atharva Tawde. This file is updated with every screen.
It contains Tanvi's Feed (SC-CM1), Post detail (SC-CM2) and the PostCard redesign (CP-6) until her PRs merge.
Nothing here says a check passed unless the output was read; see "Checks" at the end.

## SC-CM3: done (sheet only)
- Files: CommunityFeature/Comments/* (3 files), CommentsViewModelTests, wiring in Feed, PostDetail, CommunityScreens, catalog
- Tests: 19 new (38 in CommunityFeatureTests)
- Screenshots: build/screenshots/cm3.png (opened with a temporary launch change, reverted)
- Button heights: Send and Done are system/IconButton 44 pt; heights not measured from the image
- Checklist (WO-3 prompt section 6): sheet detents + drag indicator pass; composer in safeAreaInset with .bar pass; large-text not looked at
- Notes: A local sheet has no route, so no snap.sh short form and no AppShellTests row. Deviation: Report (and a commenter's profile) close the sheet first and then open through the Router, because a local sheet cannot build another feature's screen. Replies are placed directly under their parent, oldest first.

## SC-CM4: done
- Files: CommunityFeature/Trending/* (3 files), Shared/PostCardMaker.swift (shared by Feed), TrendingViewModelTests, AppShellTests row, catalog, CommunityScreens
- Tests: 9 new (47 in CommunityFeatureTests)
- Screenshots: build/screenshots/cm4-loaded.png and cm4-empty.png opened; cm4-failing.png and cm4-loading.png taken but not opened
- Button heights: PostCard action buttons are 44 pt (shared component); not measured from the image
- Checklist (WO-3 prompt section 6): large title pass; pull to refresh pass; states pass for loaded and empty (looked at), error and loading not looked at
- Notes: The repository's trending() returns a whole list, so paging is done on the phone (10 at a time). Report/Remix/Share/Save are the same as the Feed.

## SC-CM5: done
- Files: CommunityFeature/Activity/* (3 files), ActivityViewModelTests, AppShellTests row, catalog, CommunityScreens
- Tests: 11 new (58 in CommunityFeatureTests)
- Screenshots: build/screenshots/cm5-loaded.png opened; the other three states taken but not opened
- Button heights: Accept and Ignore about 49 pt (measured from the image: 113 px / 3 x 1.31)
- Checklist (WO-3 prompt section 6): large title pass; grouped inset list pass; unread = dot + bold text + VoiceOver label (not colour alone) pass; large-text not looked at
- Notes: Needs from Lohitaksh: FriendsRepository has no ignoreRequest, so Ignore only hides the row on this phone (nobody is told). An Activity whose target is a comment has no post ID, so the row opens the commenter's profile instead of the post. The dots stay until the next load while the badge clears at once.

## Feed and Post detail gaps: done (Block in the Feed is a long-press menu)
- Files: Feed/FeedViewModel, FeedView; PostDetail/PostDetailViewModel, PostDetailView; tests; catalog; CommunityScreens (session passed to the Feed)
- Tests: 3 new (61 in CommunityFeatureTests)
- Screenshots: build/screenshots/feedbadge2-crop.png opened (Chats badge 4, bell dot)
- Button heights: not measured
- Checklist (WO-3 prompt section 6): badge never colour alone (symbol changes + number) pass
- Notes: Block uses router.present(.blockConfirm(userID)); offered on other people's posts only, never on Picks. In the Feed the card's own ••• menu is inside the shared PostCard (Components, not mine), so Block is in the long-press menu; needs a block action on PostCardActions from Lohitaksh. The Feed now refreshes BadgeStore when it loads, because nothing else refreshes it at launch (the tab bar badge needs a refresh at app launch from the App).

## SC-FR1: done
- Files: FriendsFeature/Hub/* (3 files), Shared/PersonRow, HubViewModelTests, FriendsTestSupport (FakeFriends), AppShellTests row, catalog, FriendsScreens
- Tests: 15
- Screenshots: build/screenshots/fr1-loaded.png opened (Requests with Accept/Ignore, other-requests row, Sent, You might know); other states taken, not opened
- Button heights: Accept/Ignore about 49 pt; Add and Cancel pills 44 pt+ (estimated from the image)
- Checklist (WO-3 prompt section 6): grouped inset list, section headers, swipe to remove, confirmation before removing, limits message pass; large text not looked at
- Notes: Needs from Lohitaksh: FriendsRepository has no ignoreRequest, so Ignore only hides the row (nobody is told). The 30-a-day count is worked out from the sent requests' dates, since no counter exists. 'Other requests' opens a local sheet. The sample 'You might know' list includes the Vybe account (sample data).

## SC-PR3: done
- Files: FriendsFeature/OtherProfile/* (3 files), OtherProfileViewModelTests, AppShellTests row, catalog, FriendsScreens
- Tests: 13
- Screenshots: build/screenshots/pr3.png (a friend) and pr3b.png (private profile) opened
- Button heights: Add friend about 50 pt (measured: 114 px x 1.31 / 3); Friends button is the shared SecondaryButton
- Checklist (WO-3 prompt section 6): inline title, toolbar Message and ••• menu, confirmation before removing pass; large text not looked at
- Notes: Needs from Lohitaksh: (1) ProfileHeader always shows the Hangouts/Spots stats, so a private profile shows 0 and 0 instead of nothing; the header needs a way to hide them. (2) There is no 'posts by person' call, so the grid reads up to 3 pages of the feed and keeps this person's posts. (3) spotsVisited here is the number of Spots in their visible posts. The Own relationship does nothing on this screen (Edit profile belongs to the Profile screens).

## SC-PR7: done
- Files: FriendsFeature/MutualFriends/* (3 files), MutualFriendsViewModelTests, AppShellTests row, catalog, FriendsScreens
- Tests: 5
- Screenshots: build/screenshots/pr7.png taken, not opened
- Button heights: rows are single-tap PersonRows, 44 pt minimum
- Checklist (WO-3 prompt section 6): grouped inset list pass; empty/error/loading previews exist; not looked at in the simulator
- Notes: Blocked people are filtered out of the list.

## SC-CH3: done (local sheet, no route)
- Files: ChatFeature/NewChat/* (3 files), NewChatViewModelTests, ChatTestSupport (ControlledChat), catalog
- Tests: 9
- Screenshots: none: a local sheet has no route; it opens from the Chats list's New chat button (not looked at in the simulator)
- Button heights: rows are 44 pt+ single-tap; Create is a system toolbar button
- Checklist (WO-3 prompt section 6): large sheet with drag indicator, grouped list, multi-select with checkmark + isSelected trait pass; not looked at
- Notes: One friend opens a direct message (an existing one is reused); two or more make a group that needs a name (at least 3 people counting you).

## SC-CH1: done
- Files: ChatFeature/List/* (3 files), Shared/ChatPeople, ListViewModelTests, ChatScreens, AppShellTests row, catalog
- Tests: 8
- Screenshots: build/screenshots/ch1-loaded.png opened (Messages-style rows, group avatar stack, unread badges, Yesterday); other states not opened
- Button heights: rows 44 pt+; New chat is a system toolbar button
- Checklist (WO-3 prompt section 6): large title, plain list, VoiceOver reads title, unread, preview and time pass; large text not looked at
- Notes: The repository words the last-message kind (Photo, Voice note, Hangout); the screen adds 'You:' or the sender's first name. Times show the clock today, Yesterday, or the day and month. Offline disables New chat. The list refreshes BadgeStore when it loads.

## SC-CH4: done
- Files: ChatFeature/GroupInfo/* (3 files), GroupInfoViewModelTests, ChatScreens, AppShellTests row, catalog
- Tests: 11
- Screenshots: build/screenshots/ch4.png opened (grouped inset list: name, members with Admin, Add members, Leave group)
- Button heights: rows 44 pt+; Leave group row about 44 pt+ (system List row)
- Checklist (WO-3 prompt section 6): inline title, grouped inset list, confirmation before remove and leave, swipe to remove pass; large text not looked at
- Notes: Admin handover on leave is done by the repository (the oldest member becomes admin). Below 3 members the screen shows a read-only note. Needs from Lohitaksh: the invitation rule 'a non-friend of the added person must accept first' needs a pending-member state that ChatRepository does not expose, so Add members adds at once.

## SC-CH5: done
- Files: ChatFeature/ShareSheet/* (3 files), ShareSheetViewModelTests, ChatScreens, AppShellTests row, catalog
- Tests: 9
- Screenshots: build/screenshots/ch5.png taken, not opened
- Button heights: rows 44 pt+; Send and Cancel are system toolbar buttons
- Checklist (WO-3 prompt section 6): sheet detents + drag indicator, ShareLink for More… pass; not looked at in the simulator
- Notes: A post is shared as the Hangout behind it. Needs from Lohitaksh: no deep links or share URL exist yet, so More… shares the Hangout's title and 'find it on Vybe' as text.

## SC-CH7: done
- Files: ChatFeature/Invitation/* (3 files), InvitationViewModelTests, ChatScreens, AppShellTests row, catalog
- Tests: 6
- Screenshots: build/screenshots/ch7.png opened (avatar stack, headline, Join, Leave and block)
- Button heights: Join about 48 pt (shared PrimaryButton, measured 110 px x 1.31 / 3); Leave and block a large bordered button with a 44 pt minimum
- Checklist (WO-3 prompt section 6): medium sheet with drag indicator, destructive role on Leave and block pass; large text not looked at
- Notes: Leave and block declines the invitation, then opens the shared Block question for the person who added you. Needs from Lohitaksh: the stub does not model a pending invitation, so the adder is taken to be the group's admin and a group you are already in is shown.

## SC-CH6: done (local sheet, no route)
- Files: ChatFeature/Poll/* (3 files), PollViewModelTests, catalog
- Tests: 7
- Screenshots: none: a local sheet opened from the Conversation's + menu; not looked at in the simulator
- Button heights: Send and Cancel are system toolbar buttons; answer rows 44 pt+
- Checklist (WO-3 prompt section 6): medium sheet with drag indicator, keyboard focus, scrollDismissesKeyboard pass; not looked at
- Notes: The two answers are exactly 'I'm in' and 'Not for me' (taken from the shared strings). The + menu offers Poll in group chats only. The question is limited to 140 characters.

## SC-CH2: done (photos not built)
- Files: ChatFeature/Conversation/* (6 files), ConversationTestSupport, ConversationViewModelTests, ConversationWritingTests, ConversationVoiceAndRulesTests, ChatScreens, AppShellTests row, catalog
- Tests: 28
- Screenshots: build/screenshots/ch2-group.png opened (bubbles, poll, voice note, photo placeholder, composer with + and mic); ch2-dm.png taken, not opened
- Button heights: composer buttons are the shared 44 pt IconButton; the + and mic are 44 pt minimum
- Checklist (WO-3 prompt section 6): inline title, info button, composer in safeAreaInset(.bar), scrollDismissesKeyboard, long-press menu (Copy, Edit, Delete, Report), confirmation before delete pass; large text not looked at
- Notes: NOT built: sending photos (PhotosPicker, max 2). There is no call to store a processed photo and the photo permission text is X-9, so photos are listed under Needs from Lohitaksh. Voice: tap the mic to record and tap again to send (not hold-to-record and slide-to-cancel); recording needs the microphone text (X-9); playback of old notes fails with a message because their files do not exist. Read receipts: only 'Delivered' is shown, because the repository does not report when others last read (the Seen logic is in and tested). Unread counts on the Community tab are refreshed. Report pushes the shared Report screen on the tab. The stream stops when the screen goes away. Hold-to-record, link opening uses UIApplication.shared.open.

## Search (SC-S1, SC-S2)
Not part of this branch. Tanvi is taking the last two screens, so the Search tab was taken out of `a/wo2-screens` (two revert commits) and lives on the separate branch `a/wo2-search-alt` (the earlier Search work and its report sections are there).

## Needs from Lohitaksh
1. **Ignore a friend request**: `FriendsRepository` has no `ignoreRequest`, so Ignore (Activity, Friends hub) only hides the row on this phone.
2. **ProfileHeader** always shows the Hangouts and Spots numbers, so a private profile shows "0" and "0". It needs a way to hide them.
3. **PostCard** (Components): the ••• menu only has Report. A `block` action on `PostCardActions` would let the Feed offer Block there; today it is in the long-press menu.
4. **Posts by one person**: there is no call for it, so a profile reads up to 3 feed pages and keeps that person's posts.
5. **App launch**: nothing calls `BadgeStore.refresh()` at launch, so the Community tab badge stays empty until the Feed or Chats list opens (they now refresh it).
6. **Sample data** still has EXAMPLE places and titles on screen; the sample-natural-hangouts branch (separate PR) addresses that.
7. **`NSMicrophoneUsageDescription` is missing** (checked: no usage-description key anywhere in `Vybe.xcodeproj` or `Config/`). It is a project setting, so I did not add it. Without it the first real voice recording crashes when iOS asks for the microphone. Suggested text: "Vybe uses the microphone to record voice notes you send in chats."
8. **Photo permission text (X-9)** is still not in the project. The chat photo picker is the system `PhotosPicker`, which runs outside the app, so chat photos do not need it; X-9 still has to decide what the camera and other photo screens need.
9. **Tab bar change (issue #60, faculty)** is not built: it is a separate decision and stays out of this PR.
10. **Backend (Phase 2)** for the approved fixes: endpoints for `memberships`, mute and `pendingInvitations` (with `addedByID` on a pending membership); `lastReadAt` on each member and updated by `markRead` (the app has no push for read times, so "Seen" moves when the next batch of messages arrives); `runID` on comment and reply Activity rows; a photo upload that replaces `LocalPhotoStore.save` and also strips location; and a list of group photos (the messages endpoint is enough, the phone filters). Details are in `docs/DATA-MODEL.md` 3 and 6a.
11. **Voice notes**: how a voice `path` maps to a playable file is still not defined (recordings go to `voice/<file>` in the temporary folder), so old sample notes show a message when played.
12. **Not driven by hand** (needs a person on a device): the hold, slide and release of the microphone, the system photo picker, the ••• menus and confirmation dialogs, tapping an invitation, and VoiceOver on all of them. See each item below.
13. `LaunchOptions.swift` got one short form (`group-photos/<id>`, item 12); nothing else needed one.

## Decisions I need
- **Report from the Comments sheet** closes the sheet and opens the shared Report sheet (a local sheet cannot push another feature's screen), instead of pushing inside the sheet as the task says. OK?
- **Block in the Feed** is in the long-press menu for now. OK until item 3 above is done?
- **Friend request limits**: the 30-a-day count is worked out from the sent requests' dates, since no counter exists.
- **Other large buttons** (`EmptyStateView`, `ErrorView`, `BlockConfirmView`, Report) are still about 51 pt while Primary and Secondary are 48 pt (item 3 of the fixes): switch them to `PrimaryButton` too?
- **Add Spot (E2) and share (CH5) pickers** have no on-device filter; `docs/IA.md` 8 question 3 leaves them open.
- **Group Photos row and Photos in chat** use the sample photos that have no image files, so the placeholder shows until real pictures exist.

## Risks I saw
- Tanvi's Feed, Post detail and PostCard commits are on this branch too. When her PRs merge, `CommunityScreens.swift`, the Community catalog and `AppShellTests.swift` will conflict: merge `main` into this branch and keep both sides.
- Flaky tests that are not from this work: audio timing tests, and in the Chat run the Auth tests (`EmailCodeViewModelTests`, `SignInViewModelTests`) failed once under load and passed alone. Xcode open makes builds lock or crawl: close it before running `check.sh`.
- For most screens I did not look at the largest text size or VoiceOver in the simulator; the previews and labels exist but were not exercised.
- Screenshots are in `build/` on my Mac and are not committed (the folder is 400 MB and not ignored). Never `git add .`.
- The Feed, Chats list and the Comments/New chat/Poll sheets have no debug route, so they were photographed with temporary changes that were reverted.
- Found by the final review and not fixed (left for a human to decide): Activity still lists people you have blocked (the stub does not filter them; it was like this before this job). The stub's `mutedIn:` initialiser can mute the admin, which the real rules forbid (test setup only). "Muted" is hidden only in the UI: `memberships(in:)` returns every member's `mutedAt` to any member, so a real backend must redact it. Photos picked for a message are saved one by one, so a failed send leaves the saved files on the phone with no message. Leaving the Conversation while the very first microphone permission prompt is showing does not discard that recording. Picking and reading photos (`PhotoPicker`) is loaded in the View, not in the ViewModel.
- Fixed after the review: the 2 minute voice cap no longer cancels its own sending task, and the microphone is now really disabled (VoiceOver says so) while you cannot write.

## Checks
Final `./scripts/check.sh` (the run before the Search tab was moved to its own branch):
```
==> SwiftLint
Done linting! Found 0 violations, 0 serious in 396 files.
==> Architecture rules
==> Architecture rules passed
==> Architecture check self-test
==> Architecture check self-test passed
==> Tests on: iPhone 18 Pro
==> VybeKit package tests on: iPhone 18 Pro
(app target: 123 test cases passed, 0 failed; package tests ran with -quiet)
==> All checks passed
```

## git log (commits on this branch beyond main, before this report commit)
```
e8bf8f5 Merge remote-tracking branch 'origin/main' into a/wo2-screens
2bdccf3 SC-S2: See all
f1ad743 SC-S1: Search
5450004 SC-CH2: Name the main Conversation test file after the ViewModel
120df5d Merge remote-tracking branch 'origin/main' into a/wo2-screens
ba7727d SC-CH2: Conversation
94ddcf2 SC-CH6: Poll composer sheet
1b8cb08 SC-CH7: Group invitation
47272f7 SC-CH5: Share to... sheet
eb0c517 SC-CH4: Group info
1e7f0a8 SC-CH1: Chats list
e5b2aaf SC-CH3: New chat or group sheet
372d1f6 Merge remote-tracking branch 'origin/main' into a/wo2-screens
5b0aa83 SC-PR7: Mutual friends
0404cc3 SC-PR3: Other person's profile
4af7f74 SC-FR1: Friends hub
7038cdc SC-CM1/CM2: Add Block and the unread chat count
2ed61d7 SC-CM5: Activity list
9e76c85 SC-CM4: Trending list of posts
b62661b SC-CM3: Put replies under their parent and open a commenter's profile
cb0ea0a SC-CM3: Comments sheet, opened from the Feed and Post detail
9148b9a Merge origin/t/sc-cm2-post-detail into a/wo2-screens (catalog keys from both sides)
7caf8d5 Merge remote-tracking branch 'origin/t/sc-cm1-feed' into a/wo2-screens
c16f706 Merge origin/main into t/sc-cm1-feed
45876c3 Merge origin/main into t/sc-cm2-post-detail
aacb70e SC-CM2: Expect the real Post detail screen in the app-shell route test
e000f71 Merge origin/main into t/sc-cm2-post-detail
5604013 SC-CM2: Community Post detail screen
1d6ac12 SC-CM1: Community Feed screen
ff8d793 CP-6: One action bar and a clearer text stack on PostCard
```

## WO-2 fixes
Approved by Atharva and Lohitaksh (second round of work on PR #53). Updated after every item so the work can resume.
Branch: `a/wo2-screens`, started from the merge of `origin/main` (no conflicts).

| Item | State |
|---|---|
| 1 Who "you" are | done (committed; full check passed at the end of Group 1) |
| 2 Pill buttons | done (committed; checked at the end of Group 2) |
| 3 Primary and Secondary a little smaller | done (own commit, easy to revert; checked at the end of Group 2) |
| 4 No Report or Block on your own things | done (committed; checked at the end of Group 3) |
| 5 Activity opens the post | done (committed together with item 4; checked at the end of Group 3) |
| 6 New chat search | done (committed; checked at the end of Group 4) |
| 7 Friends hub search | done (committed with the docs answer; checked at the end of Group 4) |
| 8 Group data: memberships, mute, invitations | done (own commit) |
| 9 Group info: ••• menu, Mute, Add members for all | done (own commit) |
| 10 Chats list shows invitations (CH7) | done (own commit; checked at the end of Group 5) |
| 11 Photos in chat | done (own commit) |
| 12 Group photos (CH8) | done (own commit) |
| 13 Read receipts | done (own commit) |
| 14 Voice notes: hold to record | done (own commit; microphone purpose string still missing, see below) |
| 15 Docs for the approved fixes | done (docs only; no check run, as agreed) |
| 16 Full check and push | done (check passed at commit 74374d2, then pushed) |
| 17-18 Preview build on the simulator | see the summary (local only, not pushed) |
| 20 Recent searches are kept | done (own commit) |
| 21 See all shows the matches | done (own commit) |
| 22 You are not in your own People results | not started |
| 23 People on a normal launch | not started |
| 24 SC-S1 "Done when" on a real run | not started |
| 25 Report and check | not started |

### Item 1: Who "you" are
Problem: a normal launch uses `LocalProfileRepository` (ID `user-local`) while the social stubs use `SampleSocialData.currentUser` (ID `user-sample-me`), so chat, comments and Group info could not tell which things were yours.

Reproduced first (launch without `-stubMode`, `-skipOnboarding`, route to the group chat and Group info): in Group info my own row showed "?" and "@" (profile not found) and the Admin label sat on that empty row, and nothing in the chat was treated as mine (the poll I voted on showed on the left).

What changed (DEBUG only, `Vybe/App`):
- New `SampleIdentityProfileRepository` wraps the local profile repository. `currentProfile()` keeps the saved name, username, photo and bio but returns the sample ID. `profile(id:)` answers for the sample ID (as the saved profile) and for everyone in `SampleSocialData.people`; unknown IDs fall through to the local repository (not found). `update()` maps the sample ID back to the ID stored in `profile.json`, saves there, and answers with the sample ID, so the file keeps its own ID and works with an existing `profile.json`.
- `AppDependencies+Local.swift`: a small `profileRepository(now:)` helper picks the wrapper in DEBUG and the plain local repository otherwise (Release builds stop at the `fatalError` in `socialRepositories()` anyway).

Files: `Vybe/App/SampleIdentityProfileRepository.swift`, `Vybe/App/AppDependencies+Local.swift`, `VybeTests/SampleIdentityProfileRepositoryTests.swift`, this report.
Tests: 5 app-target tests (saved name and photo kept with the sample ID, fresh install, own ID lookup, sample people found and a stranger not found, update saves under the stored ID and reads back). They use a temporary file, never the real `profile.json`.
Looked at (screenshots opened): normal launch with a saved `profile.json` ("Saved Name", ID `user-local`) written into the simulator container: Group info shows the saved name with the Admin label, the three sample members' names, Add members and Leave group; the group chat shows the poll I voted on on the right with my choice checked, and other people's names above their messages.
Not driven by hand: sending a message and deleting my own comment (no way to tap in this environment). They use the same ID checks (`senderID == session.currentUser?.id`, comment author, admin) that the screenshots above show now match, but I did not exercise those two actions.
Needs from Lohitaksh: none. Phase 2 note: the wrapper goes away once there is one ID per person.

Group 1 full check: first run failed 6 package tests (MarkVisitedViewModelTests, LiveViewModelTests, ListViewModelTests, all in code not touched by Item 1; the log did not show the failure message). The Live and Chat test targets passed when run alone, and the second full `./scripts/check.sh` ended with `==> All checks passed`.

### Item 2: PillButton
Problem: Accept, Ignore, Add, Cancel, Save and Retry used system buttons with `.controlSize(.large)` and a 44 pt frame inside the label, so they drew as tall ovals or circles.

What changed: new shared `PillButton` in `Design/Views` (capsule, `.controlSize(.regular)`, prominent or bordered, optional destructive role, optional full width). A `@ScaledMetric` vertical padding sits on the label; the 44 pt floor is on the button, never in the label. It wraps at large text. Used for Accept and Ignore (Activity, Friends hub, Other requests sheet), Add and Cancel request (Friends hub), Save name (Group info) and Retry and Remove on a failed comment (Comments). Toolbar buttons (Cancel, Create, Send, Done) and list rows such as Add members are system controls and were left alone.
Files: `Design/Views/PillButton.swift` (+ previews: states and large text), `CommunityFeature/Activity/ActivityView.swift`, `CommunityFeature/Comments/CommentsView.swift`, `FriendsFeature/Hub/HubView.swift`, `ChatFeature/GroupInfo/GroupInfoView.swift`, this report.
Tests: no new ViewModel logic, so no new tests; the existing ones still apply. `swiftlint --strict`: 0 violations.
Measured (screenshot pixels / 3, iPhone 18 Pro): first try with 8 pt extra padding gave 48 pt; with the final padding Accept, Ignore, Add and Cancel measure 44 pt.
Looked at (screenshots opened): Activity, Friends hub (also at accessibility-extra-large text), Group info (Save disabled) and Invitation. The pills are capsules, not circles or tall ovals, and they grow with large text. Not photographed: New chat (its Cancel and Create are system toolbar buttons) and the Comments retry row (no debug route to a failed comment). Not driven by hand: tapping any of the buttons.
Needs from Lohitaksh: none.

### Item 3: PrimaryButton and SecondaryButton a little smaller (separate commit)
What changed: both use `.controlSize(.regular)` plus a `@ScaledMetric` vertical padding on the label instead of `.controlSize(.large)`. They keep the rounded rectangle, the 44 pt floor on the button and the wrapping at large text. `SecondaryButton` got an optional `role:` so the Invitation screen's "Leave and block" (a hand-made large bordered button) now uses it and matches Join. `docs/prompts/WO-3-agent-prompt.md` section 5 now says 48 pt instead of 51 pt. To revert this item, revert its one commit.
Files: `Design/Views/PrimaryButton.swift`, `Design/Views/SecondaryButton.swift`, `ChatFeature/Invitation/InvitationView.swift`, `docs/prompts/WO-3-agent-prompt.md`, this report.
Measured on the Invitation sheet (iPhone 18 Pro, 3x, screenshot pixels / 3): before, large size about 51 pt (153 px). First try with a 7 pt padding gave 46 pt for both. Final, with the 8 pt padding token: Join (PrimaryButton) 145 px = 48 pt, Leave and block (SecondaryButton) 145 px = 48 pt.
Not changed: `EmptyStateView`, `ErrorView`, `BlockConfirmView` and the Report screen still use `.controlSize(.large)` buttons of their own (about 51 pt); they were not on the list.
Not looked at: these two buttons at the largest text size on a screen (only the previews exist); not tapped by hand.
Needs from Lohitaksh: if you want the other large buttons above to match, say so and I will switch them to `PrimaryButton`.

Group 2 full check: one `./scripts/check.sh` run after items 2 and 3 ended with `==> All checks passed` (exit 0).

### Item 4: No Report or Block on your own things
What changed: `CommentRowData` has `canReport` (default true). `CommentRow` hides Report when it is false, and hides the ••• menu entirely when there is nothing in it (own comment on someone else's post). `CommentsViewModel` and `PostDetailViewModel` set it to false for your own comments. The Feed and Trending have `canReport(post)`: for your own post the card gets `report: nil` (no ••• menu) and the Feed's long-press menu drops Report. Block was already hidden on your own posts and Picks (`canBlock`, tested). `TrendingViewModel` now takes `session:` (to know who you are); `CommunityScreens` and the preview pass `deps.session`.
Files: `Components/CommentRow.swift`, `CommunityFeature/Comments/CommentsViewModel.swift`, `CommunityFeature/PostDetail/PostDetailViewModel.swift`, `CommunityFeature/Feed/FeedView.swift`, `FeedViewModel.swift`, `CommunityFeature/Trending/TrendingView.swift`, `TrendingViewModel.swift`, `Trending+Preview.swift`, `CommunityScreens.swift`, tests below, this report.
Tests: own comment not reportable and someone else's is (Comments), `canReport` default (Components), `canReport` on Feed (own post false, others true, plus the existing `canBlock` checks) and Trending.
Not looked at in the simulator: the Comments sheet and the Feed/Trending cards with your own post (the sample feed has no post by the signed-in person that I opened, and there is no debug route to the Comments sheet). Not driven by hand.
Needs from Lohitaksh: none.

### Item 5: Activity opens the post
What changed: `Activity` has an optional `runID: RunID?` (init parameter defaults to nil; older JSON without it still decodes, tested). A comment or reply row opens `.post(runID)`; only when `runID` is nil does it open the commenter's profile. Sample data: `activity-sample-3` is now a reply (it is a reply to my comment) with `runID`, and a new read comment row `activity-sample-6` has `runID`; unread count is still 3 (of 6). The stub and the contract checks do not construct `Activity`, so they needed no change.
Files (shared, approved): `Models/Safety/Activity.swift`, `Models/Samples/SampleSocialData.swift`. Feature: `CommunityFeature/Activity/ActivityViewModel.swift`. Tests: `ActivityViewModelTests` (reply and comment open the post, no `runID` falls back to the profile, sample rows carry a post), `CommunityModelsTests` (round trip with `runID`, old JSON decodes).
Looked at (screenshot opened): Activity list with the new "replied to your comment" and "commented on your post" rows. Not driven by hand: tapping a row (covered by the ViewModel tests).
Needs from Lohitaksh: the server must send `runID` on comment and reply rows (see item 2 above).

Group 3 full check: one `./scripts/check.sh` run after items 4 and 5 ended with `==> All checks passed` (exit 0).

### Item 6: Search field on New chat
What changed: `NewChatViewModel` has `searchText`, `isSearching`, `searchPrompt` and `visibleFriends(in:)`. It keeps the friends whose name or username contain the text, using `localizedStandardContains` (ignores case and accents), on the phone with no repository call. `selected` is never touched by the filter, so people who are picked stay picked while hidden, and the Create button and group name still count them. `NewChatView` has `.searchable` (always shown, no auto-capitalisation or autocorrect) and shows `ContentUnavailableView.search` when nothing matches. New string `chat.new.searchPrompt`.
Files: `ChatFeature/NewChat/NewChatView.swift`, `NewChatViewModel.swift`, `ChatFeature/Resources/Localizable.xcstrings`, `ChatFeatureTests/NewChatViewModelTests.swift`, this report.
Tests: no search shows everyone; case; accents; username with spaces around it; no match; picks stay picked while filtering and after clearing (and the group still counts them); clearing restores everyone. They assert IDs and counts, not names.
Looked at (screenshots opened, with a temporary search text and sheet-open flag that I reverted): the sheet with the search field, a match for "ÍSHA" (accent and case), and the "No Results" state.
Not driven by hand: typing in the field or picking while filtered (the ViewModel tests cover the logic). Not looked at: the sheet at the largest text size.
Needs from Lohitaksh: none.

### Item 7: Search field on the Friends hub
What changed: `HubViewModel` has `searchText`, `isSearching`, `searchPrompt` and `matchingFriends(in:)` (same matching as item 6; only My friends are searched, not requests or suggestions). `HubView` has `.searchable`; while searching it shows only the matching friends (or `ContentUnavailableView.search`) and the other sections (limit note, Requests, Other requests, Sent, You might know) are hidden. Clearing the field brings them back; the loaded content is never changed. New string `friends.hub.searchPrompt`. `docs/tasks/40-screens-community-friends-chat.md`: the SC-FR1 "No search field here" line now describes this (and the SC-CH3 text describes item 6). `docs/IA.md` section 8 question 3 is answered for pickers: a small on-device filter is allowed in New chat and the Friends hub; Add Spot and share are not decided.
Files: `FriendsFeature/Hub/HubView.swift`, `HubViewModel.swift`, `FriendsFeature/Resources/Localizable.xcstrings`, `FriendsFeatureTests/HubViewModelTests.swift`, `docs/tasks/40-screens-community-friends-chat.md`, `docs/IA.md`, this report.
Tests: all friends without search; case and accents; username; requests and suggestions are not searched; content unchanged and no repository call while searching; clearing (including only spaces) restores everything.
Looked at (screenshots opened): the hub with the empty search field, and with "ÁARAV" typed (only Sample Aarav under My friends, all other sections hidden). The search text was a temporary change that I reverted. Not driven by hand: typing and clearing. Not looked at: the "No Results" state on the hub (same code as New chat) and the hub at the largest text size with the search field.
Needs from Lohitaksh: none. Decision for later: Add Spot and share pickers still have no filter.

Group 4 full check: one `./scripts/check.sh` run after items 6 and 7 ended with `==> All checks passed` (exit 0).

### Item 8: Shared data for group management
What changed: `ChatRepository` has `memberships(in:)`, `setMuted(_:member:in:)` and `pendingInvitations()`. `Membership` has optional `mutedAt` and `addedByID` (init defaults nil; JSON saved before them still decodes, tested). Stub rules (`SocialStubStore`): only the admin can mute; the admin cannot be muted (`AppError.invalid`); a muted person's `send` throws `AppError.invalid`; a pending group is not in `conversations()`, `unreadCounts()`, `messages(in:)` or `send` until Join; Join clears the pending flag, Leave removes me; an invitation from a blocked person is hidden; removing a member clears their mute, and the new admin after a Leave is un-muted. `memberships(in:)` also works for a group I am only invited to, so the invitation can name who added me. The store keeps who-added-whom, join times and mutes beside `conversations` (memberships are worked out from `memberIDs`, so existing sample IDs and JSON do not change). New init parameter `SocialStubStore(mutedIn:)` starts the signed-in person muted in those groups (tests and screenshots only).
Sample data: one invitation, `conversation-sample-invitation` ("EXAMPLE Sunday Walkers", added by `Sample Vihaan`, who is not a friend), plus `pendingInvitationIDs` and `addedBy` (the crew's members were added by me). No existing ID changed. Sample group count is now 2 and conversations 4 (the sample test says so).
Invitation screen (needed so this commit stays working): `InvitationViewModel` finds the group in `pendingInvitations()` and names the person from my own membership's `addedByID` (not from the admin), takes `session:`; if no adder is known the headline reads "You were added to ...".
Files (shared, approved): `Models/Chat/Conversation.swift`, `Models/Samples/SampleSocialData.swift`, `Core/Repositories/ChatRepository.swift`, `Core/Fakes/SocialStubStore.swift`, `SocialStubStore+Chat.swift`, `StubSocialRepositories.swift`, `Contracts/SocialContracts.swift` (contract now checks: pending is not a conversation, memberships match members, the admin cannot be muted, muting sets and clears `mutedAt`, unknown chats are not found). Feature: `ChatFeature/Invitation/InvitationViewModel.swift`, `Invitation+Preview.swift`, `ChatScreens.swift`, `Resources/Localizable.xcstrings`.
Tests: `CoreTests/ChatMembersStubTests` (10: memberships and who added them, pending stays out until accepted, adder is a non-friend, Leave, blocked adder hides the invite, mute and unmute, admin cannot be muted and only the admin mutes, muted send throws, removal clears mute, empty and failing modes), `CommunityModelsTests` (Membership round trip and old JSON), `InvitationViewModelTests` rewritten for the new rules, sample-data test updated. Test support `ControlledChat` forwards the three new methods.
Not driven by hand: nothing here has its own screen; the screens that use it are items 9 and 10.
Needs from Lohitaksh: the backend needs `memberships`, `mute` and `pendingInvitations` endpoints with the same rules, and `addedByID` on a pending membership.

### Item 9: Group info with a ••• menu and Mute
What changed: every other member row has a visible ••• `Menu` (Mute or Unmute, and Remove) for the admin; swipe to remove stays. Remove still asks first (`confirmationDialog`). Mute keeps the person in the group: they can read but not send. "Muted" is a text label (not colour) and shows only to the admin and to the muted person; nobody else sees it. The admin cannot be muted (no Mute on their row). In a chat, a muted person's composer, + menu, mic and polls are off with a short note ("The admin muted you in this group. You can read, but not send."). Add members is now shown to every member (docs/PRODUCT.md: any member can add their own friends); rename, remove and mute stay admin-only. Offline: the ••• menus, swipe, Save name, Add members and the Remove confirmation are all disabled or ignored (`canAdminister`, `canAdd`).
Files: `ChatFeature/GroupInfo/GroupInfoView.swift`, `GroupInfoViewModel.swift`, `ChatFeature/Conversation/ConversationViewModel.swift`, `ConversationViewModel+Words.swift`, `ConversationView.swift`, `Resources/Localizable.xcstrings` (5 new strings), tests below.
Tests: `GroupInfoViewModelTests` (+9: menu on everyone but me, mute keeps the member and the admin sees the label, Unmute and the label word changes, the admin cannot mute themselves, a muted person sees the label only on themselves, a non-admin does not see who else is muted, every member can add but not offline, offline remove/mute/rename do nothing, a failed mute shows a message and keeps the list); `ConversationVoiceAndRulesTests` (+2: muted can read but cannot write, poll or send; an unmuted member and a direct message can write). Poll start now also needs `canWrite`.
Looked at (screenshots opened, from the Debug build with sample data): Group info as admin (••• on Friend, Aarav, Isha; none on me; Admin label; Add members; Leave group). Group info and the chat as a muted member, with a temporary change that I reverted (muted in the sample group, and the group's admin set to Sample Friend): "Muted" on my row, "Admin" on Friend, no ••• anywhere, Add members still shown, and the chat shows the muted note with the composer field and + greyed out.
Not driven by hand: opening the ••• menu, tapping Mute or Remove, and the confirmation dialog (no way to tap in this environment; the ViewModel tests cover the actions). Not looked at: an admin's view with someone muted (label on the muted row), the largest text size, and VoiceOver on the menu.
Needs from Lohitaksh: nothing new. Check: a ••• Menu inside a list row next to a row Button; on a device the two taps must stay separate.

### Item 10: Group invitation (CH7) from the Chats list
What changed: the Chats list shows pending invitations in an "Invitations" section at the top (group name, member avatars, "Invitation to join", an envelope icon with a text subtitle); the chats follow under a "Chats" header. Tapping one calls `router.present(.groupInvitation(id))`. The invitation sheet names the real person from my membership's `addedByID` (item 8), Join adds me and opens the group, Leave and block leaves and opens the shared Block question for that person. The list reloads when a router sheet closes (`isRouterSheetOpen`), so an answered invitation moves into the chats or disappears. The list is only empty when there are no chats and no invitations. Invitations from a blocked person are not listed (the repository hides them).
Files: `ChatFeature/List/ListViewModel.swift`, `ListView.swift`, `Resources/Localizable.xcstrings` (3 new strings), `ListViewModelTests.swift`. The invitation screen itself changed in item 8.
Tests: `ListViewModelTests` (+4: invitations are separate rows above the chats, tapping opens `.groupInvitation`, answering Join moves it into the chats on reload, Leave removes it without making a chat); `InvitationViewModelTests` (item 8) cover Join, Leave and block, a failed answer, offline and an answered invitation.
Looked at (screenshots opened, Debug build with sample data): the Chats list with the "EXAMPLE Sunday Walkers" invitation above three chats; the invitation sheet ("Sample Vihaan added you to EXAMPLE Sunday Walkers", three avatars, Join and Leave and block).
Not driven by hand: tapping the invitation row, Join, Leave and block, and the reload when the sheet closes (the `onChange` on `isRouterSheetOpen` is not covered by a test; the ViewModel parts are). Not looked at: the list or the sheet at the largest text size, VoiceOver.
Needs from Lohitaksh: none.

Group 5 full check: one `./scripts/check.sh` run after items 8 to 10 ended with `==> All checks passed` (exit 0). The log also has one line, "error: the following command failed with exit code 0 but produced no further output", from the app-target test step; the run still passed. A pre-existing compiler warning (`var people` never mutated in `InvitationViewModel`) is still there.

### Item 11: Photos in chat
What changed: `PhotoStore` has `save(_ photo: ProcessedPhoto) async throws -> Photo`. `LocalPhotoStore` writes the large picture to `Application Support/Vybe/Photos` and `url(for:)` looks in the bundled folder and then the saved folder (a path with `..` is never found). `StubPhotoStore` (now a class, numbers its photos, keeps no file) conforms. Onboarding and Live were not touched (they only call `url(for:)`). `ProcessedPhoto.pixelSize` reads the width and height. The "+" menu has Photos (system `PhotosPicker`, max 2 per message, images only). Every picked picture goes through `PhotoProcessor` first (resized, location and all other details removed: docs/RISKS.md 3), is saved, and then all are sent as ONE message. If any step fails a short message shows and nothing is sent. Photos is off offline, while muted or read-only, while recording and while one is sending. The conversation now shows the real pictures through `PhotoStore` instead of nil. Tapping a photo opens the shared full-screen viewer (`ChatFeature/Shared/PhotoViewer.swift`, wired through the `openPhoto` closure): system page `TabView` to swipe between photos, a Close button with a VoiceOver label, a "Photo 2 of 3" label for each picture, no glass on the photos. The sample group message now has 2 photos so the viewer can be swiped.
Files (shared, approved): `Core/Repositories/PhotoStore.swift`, `Core/Services/PhotoProcessor.swift`, `Core/Fakes/StubRepositories.swift`, `LocalData/LocalPhotoStore.swift`, `Models/Samples/SampleSocialData.swift`. Feature: `ChatFeature/ChatScreens.swift`, `Conversation/ConversationView.swift`, `ConversationViewModel.swift`, `ConversationViewModel+Photos.swift`, `Conversation+Preview.swift`, `Shared/PhotoPicker.swift`, `Shared/PhotoViewer.swift`, `Resources/Localizable.xcstrings` (5 strings).
Tests: `ConversationPhotosTests` (picked photos are processed, location gone from what was saved, one message; max 2; not a picture sends nothing; one bad picture among two sends nothing; failed save; failed send; picker could not read; offline, muted and recording turn it off; real pictures from the store; tapping opens the viewer on that photo and ignores bad taps), `LocalPhotoStoreTests` (save and find again, separate files, bundled and saved both found, `..` path, no size for non-pictures), `PhotoProcessorTests` (size, stub store). No test file asserts sample text.
Looked at (screenshot opened, with a temporary line that opened the viewer, since reverted): the viewer on the second of two photos, with the Close button top left and two page dots. The sample photos have no image files, so the placeholder shows.
Not driven by hand: the "+" menu, the system photo picker and picking a real picture (cannot be automated here; the ViewModel is tested with fakes and real JPEG bytes that carry a GPS position), swiping in the viewer, VoiceOver, the viewer on a real image, the saved file on disk from the app.
Needs from Lohitaksh: the backend upload (Phase 2) replaces `LocalPhotoStore.save`; the upload must also strip location (already done on the phone before `save`).

### Item 12: Group photos (CH8)
What changed: new screen `GroupPhotosView` + `GroupPhotosViewModel` (made with `scripts/new_screen.py`, then rewritten). It listens to the group's messages stream and shows every photo as a `LazyVGrid` with adaptive columns (the column width is a `@ScaledMetric`, so large text gives fewer, bigger columns), newest message first; the pictures of one message keep their order. Deleted messages and messages from blocked people are left out. Tapping a picture opens the shared full-screen viewer (item 11) on it, with all the group's photos to swipe between. States: loading (nine placeholder tiles), empty ("No photos yet..."), failed (Retry), and a broken stream after photos keeps them and marks them stale. Group info has a new Photos row (own section, chevron, 44 pt) that calls `router.open(.groupPhotos(id))`. New route `ChatRoute.groupPhotos(ConversationID)` with the `Route.groupPhotos` helper, launch short form `group-photos/<id>`, `docs/IA.md` row CH8.
Files (shared, approved): `Core/Navigation/Routes/ChatRoute.swift`, `Vybe/App/LaunchOptions.swift`, `docs/IA.md`, `VybeTests/AppShellTests.swift` (row `view:GroupPhotosView`), `VybeTests/LaunchOptionsTests.swift`, `CoreTests/RouteCodingTests.swift` and `IACoverageTests.swift` (CH8 row, 61 screens). Feature: `ChatFeature/GroupPhotos/*` (4 files), `ChatScreens.swift`, `GroupInfo/GroupInfoView.swift`, `GroupInfoViewModel.swift`, `Resources/Localizable.xcstrings` (Photos row, new empty text), tests below.
Tests: `GroupPhotosViewModelTests` (newest first with ids, deleted left out, blocked hidden, no photos is empty, only blocked photos is empty, failed first load, sample group has photos and the empty mode is empty, tapping opens the viewer on the tapped photo with all of them and ignores unknown ids, a broken stream keeps the photos and marks them stale), `GroupInfoViewModelTests` (Photos row opens the route), `ChatScreensTests` (entry point builds). `ControlledChat` got `failStreamAfterFirstBatch` for the stale test. They assert IDs, counts and states, not sample text.
Looked at (screenshots opened): the grid (two sample photos as placeholder tiles, since the sample photos have no image files), the empty state, and Group info with the new Photos row. Not driven by hand: tapping the Photos row or a tile (covered by ViewModel tests; the route is covered by AppShell and launch tests), swiping in the viewer, the failed and loading states and the largest text size on the device (previews exist), VoiceOver, a grid with many real pictures.
Needs from Lohitaksh: none. The backend list of group photos can reuse the messages endpoint (this screen filters on the phone).


Group 6a full check: one `./scripts/check.sh` run after items 11 and 12 ended with `==> All checks passed` (exit 0).

### Item 13: Read receipts ("Seen")
What changed: the Conversation now loads `memberships(in:)` once before the stream starts and again after every batch of messages, so the read times move whenever the messages do. "Seen" under my last message uses the newest `lastReadAt` among the other members who are active and not blocked (my own read time never counts), fed into the existing `ConversationViewModel.receipt(for:othersLastReadAt:)`. A failed membership lookup keeps what was known before. The same lookup still decides whether I am muted. Sample data: `SampleSocialData.othersLastRead` (who read which chat and when, only people who are in that chat; no existing ID changed); the stub shows it as `lastReadAt` on their `Membership` and clears it when they are removed. The contract checks now also require `markRead` to set my own `lastReadAt`.
Files (shared, approved): `Models/Samples/SampleSocialData.swift`, `Core/Fakes/SocialStubStore.swift`, `SocialStubStore+Chat.swift`, `Contracts/SocialContracts.swift`. Feature: `ChatFeature/Conversation/ConversationViewModel.swift`. Tests: `ChatFeatureTests/ConversationReceiptsTests.swift` (new), `ChatTestSupport.swift` (`ControlledChat` can return fixed memberships and counts the calls).
Tests (8): the sample DM shows Seen; no read time is Delivered; reading before my message is Delivered and after is Seen; my own read time never counts; in a group the newest read of anyone counts; a blocked reader and a pending member do not count; the read times are reloaded when the messages change (a new message is Delivered, then Seen after the other person's read time moves); the stub reports other people's read times on their membership. They assert receipts and counts, not sample text.
Looked at: see the screenshot note at the end of Group 6b. Not driven by hand: nothing here needs a tap.
Needs from Lohitaksh: the backend must return each member's `lastReadAt` on `memberships` (and update it when `markRead` is called), and the app has no push for read times: "Seen" updates when the next message batch arrives.

### Item 14: Voice notes, hold to record (SC-CH2)
What changed: the microphone is now a hold control. Finger down starts recording, letting go sends, sliding left 80 points and letting go throws it away (the bar shows "Slide to cancel", and "Let go to cancel" with a trash icon once letting go would cancel: words and icon, not only colour; the bar follows the finger directly, with no animation). The 2 minute cap is enforced by the screen too: a cap task (the wait is injected as `sleep:`, default `Task.sleep`) stops the recording at `AudioRecorder.maximumDuration`, sends what was recorded and shows the "up to 2 minutes" notice, even while the finger is still down; letting go later does nothing. A tap that records under 1 second is thrown away (the file is deleted) and a notice says to hold the microphone. If the recorder cannot start (no permission) nothing is held and the existing message shows. Leaving the screen discards an unfinished recording (`onDisappear`). VoiceOver: the microphone is one accessibility element with a label ("Record a voice note", "Send voice note" while recording), a spoken hint that explains the hold gesture and the VoiceOver way, a default accessibility action that starts on the first activation and sends on the next (`micTapped()`), and a "Discard voice note" custom action while recording. A finger can take over a recording VoiceOver started. The trash button in the bar stays when nobody is holding. The mic control is 44 pt minimum and dimmed when writing is off. The read-receipt code moved to `ConversationViewModel+Receipts.swift` (same code as item 13) because the class hit the lint length limit.
Files: `ChatFeature/Conversation/ConversationView.swift`, `MicControl.swift` (new: the microphone and the recording bar), `ConversationViewModel.swift`, `ConversationViewModel+Voice.swift`, `+Words.swift`, `+Receipts.swift` (new), `Resources/Localizable.xcstrings` (4 strings), tests below, this report.
Tests (`ConversationHoldToRecordTests`, 15, all with `FakeRecorder`, no microphone): hold starts and letting go sends; letting go before the start finished still sends once; a second press does not start again; sliding far enough cancels and sends nothing; a short slide still sends and sliding back undoes the cancel; sliding right is ignored; the hint words change; a tap under 1 second is not sent and the file is deleted; no permission; offline and muted cannot hold; the cap stops and sends at 2 minutes (the wait asked for exactly 120 s) and a later release does nothing; finishing early stops the cap clock; VoiceOver start then send; VoiceOver discard; a finger takes over a VoiceOver recording; leaving the screen discards. The old voice tests in `ConversationVoiceAndRulesTests` still pass.
Looked at: the Conversation screenshot (microphone in the composer, nothing recording). Not driven by hand: holding, sliding and letting go, the 2 minute wait, VoiceOver itself, and the system microphone prompt. I did not tap the microphone and did not record anything live. The gesture view code (`DragGesture(minimumDistance: 0)` plus `@GestureState`, `onChange` to call the ViewModel) is covered only through the ViewModel methods it calls; whether a real touch in a scroll view's bottom bar delivers press and release as expected needs a try on a device.
Needs from Lohitaksh: `NSMicrophoneUsageDescription` (the microphone purpose string) is not in the project, and it is a project setting that I must not edit. Without it, the first real recording on a device or the simulator will crash when iOS asks for the microphone. Please add it (for example "Vybe uses the microphone to record voice notes you send in chats.") before anyone tries a real recording.

Looked at for items 13 and 14 (screenshots opened, Debug build with sample data, iPhone 18 Pro): the sample chat with Sample Aarav shows "Seen" under my last message ("EXAMPLE thanks"), and the composer shows the "+" button, the Message field and the microphone (the new `MicControl`, same size and place as before; nothing recording). Not seen on screen: the recording bar with "Slide to cancel", because that needs a held touch, which I cannot do here.

Group 6b full check: one `./scripts/check.sh` run after items 13 and 14 ended with `==> All checks passed` (exit 0).

### Item 15: Docs for the approved fixes
What changed (docs only, approved by Atharva and Lohitaksh): `docs/PRODUCT.md` (Chat: mute, group photos, hold-to-record voice notes with the 2 minute cap, read receipts from each member's `lastReadAt`; Search: the on-device filter in New chat and the Friends hub is not the Search tab, which stays the place to find new things), `docs/IA.md` (CH1 invitations section, CH2 and CH4 rows, CH8 route; the picker answer was already in section 8), `docs/DATA-MODEL.md` (`Membership.mutedAt` and `addedByID`, `Activity.runID`, `PhotoStore.save` and where chat photos live, read receipts through `memberships(in:)`, the three new `ChatRepository` calls and their rules), `docs/tasks/40-screens-community-friends-chat.md` (SC-CH2, SC-CH4, SC-CH7 text, new SC-CH8 section). "Needs from Lohitaksh" and "Decisions I need" above were rewritten: finished items removed (Activity post ID, read receipts, photos, group invitations, voice hold-to-record; Ignore stays) and new ones added (microphone text, photo text, tab bar issue #60, backend list).
Not touched: anything about the Search tab (SC-S1, SC-S2): it is not part of this branch.
Not run: `check.sh` (docs only). I read the edited files back by diff; I did not build.
Needs from Lohitaksh: please read the new "approved by Lohitaksh" lines in the four documents and say if any is wrong.

### Item 20: Recent searches survive closing the app (Search alternative branch)
What changed: `AppSettings.recentSearches` (a string list in `UserDefaults`, cleared by `clear()`), `SessionStore.recentSearches` (reads and writes it), and `SearchViewModel` now reads and writes it through the session instead of an in-memory list. The limit (5, newest first, no duplicates) is unchanged; Clear writes an empty list, so it really clears.
Files: `Core/Services/AppSettings.swift`, `Core/Stores/SessionStore.swift` (both approved for this group), `SearchFeature/Search/SearchViewModel.swift`, `SearchViewModelTests`, `CoreTests/StoreTests`, this report.
Tests: `recentSearchesComeBackAfterTheAppRestarts` (a new SessionStore and a new view model on the same settings suite show the same recents; Clear empties the session, the settings and a third view model) and `recentSearchesAreKeptInSettingsAndForgottenOnReset` (Core). SearchFeatureTests: 21 passed.
Not looked at: nothing visual changed in this item.

### Item 21: See all shows the matches, not the whole group
What changed: `SessionStore.lastSearchQuery` (in memory, like `onboardingDraft`; `Route.searchSeeAll(kind)` is unchanged). `SearchViewModel.seeAllTapped` stores the typed words (trimmed) before opening See all. `SeeAllViewModel` got a `search: SearchRepository` and, when `lastSearchQuery` is not empty, runs `search(text:scope:)` for that one group (scope is just the tapped group) and pages the result 20 at a time as before. With an empty query (for example a restored route) it lists the whole group exactly as before. Blocked people stay out in both cases. A "Matches only" preview was added.
Files: `Core/Stores/SessionStore.swift`, `SearchFeature/SeeAll/SeeAllViewModel.swift`, `SeeAll+Preview.swift`, `SearchFeature/SearchScreens.swift`, `SearchFeature/Search/SearchViewModel.swift`, `SeeAllViewModelTests`, `SearchViewModelTests`, this report.
Tests (SearchFeatureTests: 26 passed): only matches in that group and the repository is asked with only that group and the trimmed words; blank query never searches and lists the whole group; matches keep blocked people out; matches are paged; no matches is the empty state; the Search ViewModel stores the trimmed words when See all is tapped.
Not looked at yet: the screen (item 24 looks at every state).

### Shared files touched in this job
From `git diff --name-only 27fee49..HEAD` (the commits of the fixes, not the merge from `main`), restricted to the approved shared folders. The list for the whole PR (which also has Tanvi's Feed and PostCard commits and the first WO-2 round, for example `Components/PostCard.swift`) is `git diff --name-only origin/main...HEAD`.
- Models: `Models/Chat/Conversation.swift`, `Models/Safety/Activity.swift`, `Models/Samples/SampleSocialData.swift`
- Core: `Core/Repositories/ChatRepository.swift`, `Core/Repositories/PhotoStore.swift`, `Core/Services/PhotoProcessor.swift`, `Core/Fakes/StubRepositories.swift`, `Core/Fakes/StubSocialRepositories.swift`, `Core/Fakes/SocialStubStore.swift`, `Core/Fakes/SocialStubStore+Chat.swift`, `Core/Fakes/Contracts/SocialContracts.swift`, `Core/Navigation/Routes/ChatRoute.swift`
- LocalData: `LocalData/LocalPhotoStore.swift`
- Design/Views: `Design/Views/PillButton.swift` (new), `Design/Views/PrimaryButton.swift`, `Design/Views/SecondaryButton.swift`
- Components: `Components/CommentRow.swift`
- App: `Vybe/App/AppDependencies+Local.swift`, `Vybe/App/LaunchOptions.swift`, `Vybe/App/SampleIdentityProfileRepository.swift` (new)
- App tests: `VybeTests/AppShellTests.swift`, `VybeTests/LaunchOptionsTests.swift`, `VybeTests/SampleIdentityProfileRepositoryTests.swift` (new)
- Docs: `docs/IA.md`, `docs/PRODUCT.md`, `docs/DATA-MODEL.md`, `docs/tasks/40-screens-community-friends-chat.md`, `docs/prompts/WO-3-agent-prompt.md`, this report
- Package tests beside these: `CoreTests/ChatMembersStubTests`, `RouteCodingTests`, `IACoverageTests`, `PhotoProcessorTests`, `BadgeStoreAndSampleTests`, `LocalDataTests/LocalPhotoStoreTests`, `ContentTests/CommunityModelsTests`, `ComponentsTests/ComponentDataTests`
- Never touched: `Package.swift`, signing, project settings, `Vybe.xcodeproj`, `Local.xcconfig`, and nothing under the Search feature or the search settings in `AppSettings` and `SessionStore`.
