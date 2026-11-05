# WO-2 report: Community, Friends, Chat and Search

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

