# Vybe task pool (generated: do not edit; run `python3 scripts/build_task_index.py`)

Take any task whose **Depends on** tasks are merged. Details are in the linked file. Claim a task by
assigning yourself on its GitHub issue. Start with `docs/START-HERE.md` and `docs/DAY-ONE.md`.
**Size** (S, M, L) is only a hint for how big one pull request will be.

**Gates (proof, not dates):** **G1** = F-0 merged (settings final; tasks that write code in `Core/` may start) ·
**G2** = F-4, F-5, F-16, F-9 and DS-1/2/3 merged (the app runs; screens may start) · **G3** = SC-HD1 merged
(the golden screen exists; copy it with `scripts/new_screen.py`). **common** (in screen tasks) = F-4, F-5, F-9 (which
brings F-16), DS-1, DS-2, DS-3.

## Start now (no dependencies)

**F-0** Link VybeKit, set the concurrency and language modes, prove the architecture, **F-1** IDs, shared value types and the JSON coder, **DS-1** Theme: colours, type, spacing, radii, motion tokens, **DS-6** ImageLoader, **X-C1** First sample data: 5 Places + 2 Hangouts (with photos), **X-1** SwiftLint custom rules, **X-2** GitHub Actions: lint on every PR, **X-6** Create GitHub issues from the task files, **X-7** App icon and launch screen placeholder

**Suggested order:** day one = F-0 (Lohitaksh) · F-1 then F-2, F-3 (Models) · DS-1 then DS-6 · X-C1 · X-1, X-2, X-6 ·
after G1 = F-4, F-6, F-11, F-13, F-14, F-15, then F-5, F-16, F-7, F-8, F-10 · G2 = F-9 and DS-2/3/4/5, then components
CP-1…CP-11, X-13, X-14 · G3 = SC-HD1 first, then any screen whose dependencies are merged · other X tasks any time.

## Foundation (do first)

| ID | Task | Size | Depends on | Details |
|---|---|---|---|---|
| **F-0** | Link VybeKit, set the concurrency and language modes, prove the architecture *(Lohitaksh only: project settings)* | M | — | `docs/tasks/00-foundation.md` |
| **F-1** | IDs, shared value types and the JSON coder | S | — | `docs/tasks/00-foundation.md` |
| **F-2** | Content models | M | F-1 | `docs/tasks/00-foundation.md` |
| **F-3** | Community, chat and safety models | M | F-1 | `docs/tasks/00-foundation.md` |
| **F-4** | Navigation: grouped Routes, Sheet, Cover, Router | M | F-0, F-1 | `docs/tasks/00-foundation.md` |
| **F-5** | Content repositories, stubs, stores, settings, AppDependencies | L | F-0, F-1, F-2, F-4 | `docs/tasks/00-foundation.md` |
| **F-6** | Hangout rules | S | F-0, F-2 | `docs/tasks/00-foundation.md` |
| **F-7** | Community, chat and safety repositories + sample social data | M | F-3, F-5 | `docs/tasks/00-foundation.md` |
| **F-8** | LocalData: loader, sample content, persistence, content test | L | F-2, F-5 | `docs/tasks/00-foundation.md` |
| **F-9** | App shell: dependencies, tabs, thin screen factory | L | F-0, F-4, F-5, F-16, DS-1 | `docs/tasks/00-foundation.md` |
| **F-10** | Live run store (survives the app closing) | M | F-2, F-5 | `docs/tasks/00-foundation.md` |
| **F-11** | LocationService (real + simulated walk) | M | F-0, F-1 | `docs/tasks/00-foundation.md` |
| **F-12** | (moved) ImageLoader is task DS-6 | S | — | `docs/tasks/00-foundation.md` |
| **F-13** | PhotoProcessor (resize, strip location) | M | F-0, F-1 | `docs/tasks/00-foundation.md` |
| **F-14** | NetworkMonitor and offline state | S | F-5 | `docs/tasks/00-foundation.md` |
| **F-15** | Voice notes: AudioRecorder and player | M | F-0, F-1 | `docs/tasks/00-foundation.md` |
| **F-16** | Feature `Screens` scaffolds (all 13 features) | M | F-4, F-5 | `docs/tasks/00-foundation.md` |

## Design system and components

| ID | Task | Size | Depends on | Details |
|---|---|---|---|---|
| **DS-1** | Theme: colours, type, spacing, radii, motion tokens | M | — | `docs/tasks/10-design-system-and-components.md` |
| **DS-2** | State views: LoadStateView, EmptyStateView, ErrorView, OfflineBanner | M | F-1, DS-1 | `docs/tasks/10-design-system-and-components.md` |
| **DS-3** | Buttons, chips, rows, fields | M | DS-1 | `docs/tasks/10-design-system-and-components.md` |
| **DS-4** | Motion and haptic helpers | S | DS-1 | `docs/tasks/10-design-system-and-components.md` |
| **DS-5** | Layout helpers: FlowLayout and skeleton shapes | S | DS-1 | `docs/tasks/10-design-system-and-components.md` |
| **DS-6** | ImageLoader | M | — | `docs/tasks/10-design-system-and-components.md` |
| **CP-1** | HangoutCard | M | DS-1, DS-5, DS-6, CP-3 | `docs/tasks/10-design-system-and-components.md` |
| **CP-2** | SpotRow | M | DS-1, CP-3 | `docs/tasks/10-design-system-and-components.md` |
| **CP-3** | PlaceImage and PhotoGallery | M | DS-1, DS-6 | `docs/tasks/10-design-system-and-components.md` |
| **CP-4** | Avatar and AvatarStack | S | DS-1, CP-3 | `docs/tasks/10-design-system-and-components.md` |
| **CP-5** | Badges and notes | S | DS-1 | `docs/tasks/10-design-system-and-components.md` |
| **CP-6** | PostCard (feed card) | M | DS-1, CP-3, CP-4, CP-5, DS-5 | `docs/tasks/10-design-system-and-components.md` |
| **CP-7** | CommentRow | M | DS-1, CP-4 | `docs/tasks/10-design-system-and-components.md` |
| **CP-8** | Message bubbles | L | DS-1, CP-1, CP-3, CP-4 | `docs/tasks/10-design-system-and-components.md` |
| **CP-9** | ProfileHeader | M | DS-1, CP-3, CP-4 | `docs/tasks/10-design-system-and-components.md` |
| **CP-10** | Info pills and tag rows | S | DS-1, DS-5 | `docs/tasks/10-design-system-and-components.md` |
| **CP-11** | Map pins | M | DS-1, CP-3 | `docs/tasks/10-design-system-and-components.md` |

## Screens: onboarding, sign-in, Discover, Hangout detail

| ID | Task | Size | Depends on | Details |
|---|---|---|---|---|
| **SC-O1** | Welcome | S | common | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-O2** | Name and photo | M | common, F-13 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-O3** | Interests | S | common, DS-5 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-O4** | Location | M | common, F-11 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-O5** | Find friends | M | common, F-7, CP-4 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-A1** | Sign in | M | common, F-7 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-A2** | Email sign-in | M | SC-A1 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-A3** | Account basics | M | SC-A1, F-6 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-D1** | Discover map | L | common, CP-1, CP-11, F-8 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-D2** | Pin preview card | M | common, CP-1, SC-D1 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-D3** | Filters sheet | M | common, DS-3, DS-5 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-HD1** | Hangout detail | L | common, CP-1, CP-2, CP-3, CP-5, CP-10, F-10 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-HD2** | Spot sheet | M | common, CP-1, CP-3, CP-5 | `docs/tasks/20-screens-start-discover-detail.md` |
| **SC-HD3** | Remix tree | M | common, CP-1, CP-4 | `docs/tasks/20-screens-start-discover-detail.md` |

## Screens: live Hangout, Search, Profile, Settings

| ID | Task | Size | Depends on | Details |
|---|---|---|---|---|
| **SC-H1** | Hangout live | L | common, F-10, F-11, CP-2, DS-4 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-H2** | Mark visited | M | common, F-13, F-10 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-H3** | Summary | M | common, F-6, F-10, CP-3 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-H4** | Live mini-bar | M | common, F-10, SC-H1 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-S1** | Search | L | common, CP-1, CP-4, F-8 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-S2** | See all | S | SC-S1 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-PR1** | My profile | L | common, CP-1, CP-9, CP-6 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-PR2** | Settings (root) | M | common, DS-3 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-PR4** | Saved | M | common, CP-1 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-PR5** | Drafts | M | common, CP-1, CP-5 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-PR6** | Edit profile | M | common, F-13, DS-3, DS-5 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-PR8** | Ready to post | M | common, F-6, CP-5 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-ST-A** | Account settings and delete account (ST1, ST8) | M | common, DS-3 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-ST-B** | Privacy, Blocked, Notifications (ST2, ST3, ST4) | M | common, DS-3, F-7 | `docs/tasks/30-screens-live-search-profile.md` |
| **SC-ST-C** | Help, Place suggestions, About (ST5, ST6, ST7) | S | common, DS-3 | `docs/tasks/30-screens-live-search-profile.md` |

## Screens: Community, Friends, Chat

| ID | Task | Size | Depends on | Details |
|---|---|---|---|---|
| **SC-CM1** | Feed | L | common, CP-1, CP-6, DS-4 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CM2** | Post detail | L | common, CP-1, CP-2, CP-3, CP-6, CP-7, CP-9 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CM3** | Comments | M | common, CP-7 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CM4** | Trending | S | common, CP-6 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CM5** | Activity | M | common, CP-4, F-7 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-FR1** | Friends hub | M | common, CP-4, F-7 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-PR3** | Other person's profile | M | common, CP-6, CP-9 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-PR7** | Mutual friends | S | common, CP-4 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CH1** | Chats list | M | common, CP-4, F-7 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CH2** | Conversation | L | common, CP-8, F-15, F-13, SC-CH6 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CH3** | New chat or group | M | common, CP-4 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CH4** | Group info | M | common, CP-4 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CH5** | Share to… | M | common, CP-1, CP-4 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CH6** | Poll composer | S | common, CP-8 | `docs/tasks/40-screens-community-friends-chat.md` |
| **SC-CH7** | Group invitation | S | common, CP-4 | `docs/tasks/40-screens-community-friends-chat.md` |

## Screens: Editor, Posting, Report/Block, Admin

| ID | Task | Size | Depends on | Details |
|---|---|---|---|---|
| **SC-E1** | Hangout editor | L | common, F-6, CP-2, CP-10, SC-E2 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-E2** | Add Spot | M | common, CP-3 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-E3** | Suggest a Place | M | common, F-13, F-7 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-PO1** | Post composer | L | common, F-6, CP-6 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-PO2** | Edit post | M | common, CP-6 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-R1** | Report | M | common, F-3, F-7 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-R2** | Block confirm | S | common, SC-R1 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-AD1** | Admin: reports queue | M | common, F-7 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-AD2** | Admin: Place suggestions | S | SC-AD1 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |
| **SC-AD3** | Admin: users | S | SC-AD1 | `docs/tasks/50-screens-editor-posting-safety-admin.md` |

## Cross-cutting, content, project settings

| ID | Task | Size | Depends on | Details |
|---|---|---|---|---|
| **X-C1** | First sample data: 5 Places + 2 Hangouts (with photos) | M | — | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-C2** | Content batch: +15 Places with photos *(repeatable)* | M | X-C1 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-C3** | Content batch: +10 Hangouts / Picks from real past visits *(repeatable)* | M | X-C1 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-C4** | Sheet → JSON script (K1) | M | X-C1 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-1** | SwiftLint custom rules | S | — | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-2** | GitHub Actions: lint on every PR | S | — | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-3** | String Catalogs per module | M | F-0 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-4** | Accessibility review (repeat per feature) | M | SC-HD1 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-5** | Golden example, template refresh and screen generator | M | SC-HD1 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-6** | Create GitHub issues from the task files | S | — | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-7** | App icon and launch screen placeholder | S | — | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-13** | Architecture check script | S | F-16 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-14** | Agent loop: debug launch options and screenshot script | M | F-9, F-4 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-9** | Permissions, capabilities, simulated walk, privacy manifest | S | F-0 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-10** | UI-test target + accessibility audit | M | SC-O1, SC-HD1 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-11** | Quality and performance pass on the lab iPhone | M | SC-D1, SC-HD1, SC-H1, SC-CM1, SC-CH2 | `docs/tasks/60-cross-cutting-and-content.md` |
| **X-12** | Demo build and walkthrough | S | SC-D1, SC-HD1, SC-H1, SC-CM1, SC-CH2 | `docs/tasks/60-cross-cutting-and-content.md` |

## Backend (later)

| ID | Task | Size | Depends on | Details |
|---|---|---|---|---|
| **BK-1** | One-day backend test (login + one table + one listener + People prefix search with blocks + WhatsApp preview page) | L | — | `docs/tasks/70-backend-later.md` |
| **BK-2** | `VybeRemote` package + SDK exception decision | L | — | `docs/tasks/70-backend-later.md` |
| **BK-3** | Auth: Apple, Google, email code; username uniqueness; 30-day username hold | L | — | `docs/tasks/70-backend-later.md` |
| **BK-4** | Data rules: deny-by-default database and storage rules + rule tests in CI | L | — | `docs/tasks/70-backend-later.md` |
| **BK-5** | Hangouts, Places, Saves, runs, feed (friends-first fan-out) | L | — | `docs/tasks/70-backend-later.md` |
| **BK-6** | Friends, requests (caps, "Other" folder), blocks | L | — | `docs/tasks/70-backend-later.md` |
| **BK-7** | Chat: conversations, messages, read receipts, polls, voice/photo upload, group invitations | L | — | `docs/tasks/70-backend-later.md` |
| **BK-8** | Server functions: counters, Remix credit, account deletion cascade, `audience` rewrite, scheduled posts | L | — | `docs/tasks/70-backend-later.md` |
| **BK-9** | Push notifications (needs the paid Apple account) | L | — | `docs/tasks/70-backend-later.md` |
| **BK-10** | WEB1 share pages with WhatsApp preview and "I'm in" without an account | L | — | `docs/tasks/70-backend-later.md` |
| **BK-11** | Admin tooling server side + report auto-hide + on-call alerts | L | — | `docs/tasks/70-backend-later.md` |
| **BK-12** | Offline cache strategy (SDK cache or our own JSON) | L | — | `docs/tasks/70-backend-later.md` |
| **BK-13** | Privacy policy, Terms, grievance contact, lawyer review | L | — | `docs/tasks/70-backend-later.md` |
| **BK-14** | TestFlight pipeline (Xcode Cloud or Actions), demo account for App Review | L | — | `docs/tasks/70-backend-later.md` |
