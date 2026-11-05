# WO-2 report: Community, Friends and Chat

Branch: `a/wo2-screens`. Written by Claude Code (Sonnet 5.5) for Atharva Tawde. This file is updated with every screen.
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
2. **Activity rows about a comment** carry only a comment ID, not the post's ID, so they open the commenter's profile. Activity needs the post ID.
3. **ProfileHeader** always shows the Hangouts and Spots numbers, so a private profile shows "0" and "0". It needs a way to hide them.
4. **PostCard** (Components): the ••• menu only has Report. A `block` action on `PostCardActions` would let the Feed offer Block there; today it is in the long-press menu.
5. **Posts by one person**: there is no call for it, so a profile reads up to 3 feed pages and keeps that person's posts.
8. **Read receipts**: the repository does not say when others last read a chat, so only "Delivered" is shown (the "Seen" logic is in and tested).
9. **Group invitations**: no pending-member state is exposed, so Add members adds at once (the task says a non-friend must accept first) and the invitation screen assumes the group's admin added you.
10. **Photos in chat**: no call to store a processed photo, and the photo and microphone permission texts (X-9) are not in the project. Sending photos is not built; recording a voice note asks for the microphone and needs that text. Voice notes: how a `path` maps to a playable file is not defined (recordings go to `voice/<file>` in the temporary folder).
11. **App launch**: nothing calls `BadgeStore.refresh()` at launch, so the Community tab badge stays empty until the Feed or Chats list opens (they now refresh it).
12. **Sample data** still has EXAMPLE places and titles on screen; the sample-natural-hangouts branch (separate PR) addresses that.
13. `LaunchOptions.swift` was not changed: no new short form was needed.

## Decisions I need
- **Report from the Comments sheet** closes the sheet and opens the shared Report sheet (a local sheet cannot push another feature's screen), instead of pushing inside the sheet as the task says. OK?
- **Block in the Feed** is in the long-press menu for now. OK until item 4 above is done?
- **Voice notes** are tap to record, tap to send (not hold-to-record with slide-to-cancel).
- **Friend request limits**: the 30-a-day count is worked out from the sent requests' dates, since no counter exists.
- **Photos in chat** left out (item 10): build a placeholder now, or wait for photo storage?

## Risks I saw
- Tanvi's Feed, Post detail and PostCard commits are on this branch too. When her PRs merge, `CommunityScreens.swift`, the Community catalog and `AppShellTests.swift` will conflict: merge `main` into this branch and keep both sides.
- Flaky tests that are not from this work: audio timing tests, and in the Chat run the Auth tests (`EmailCodeViewModelTests`, `SignInViewModelTests`) failed once under load and passed alone. Xcode open makes builds lock or crawl: close it before running `check.sh`.
- For most screens I did not look at the largest text size or VoiceOver in the simulator; the previews and labels exist but were not exercised.
- Screenshots are in `build/` on my Mac and are not committed (the folder is 400 MB and not ignored). Never `git add .`.
- The Feed, Chats list and the Comments/New chat/Poll sheets have no debug route, so they were photographed with temporary changes that were reverted.

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
| 3 Primary and Secondary a little smaller | not started |
| 4-25 | not started |

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
