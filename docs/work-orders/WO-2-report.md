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

