# Vybe task pool (generated: do not edit; run `python3 scripts/build_task_index.py`)

Take any task whose **Depends on** tasks are merged; details are in the file named under each heading. Claim a task by
assigning yourself on its GitHub issue. Start with `docs/START-HERE.md`. **Size** S, M, L is only a hint for the size of one PR.

**Gates (proof, not dates):** **G1** = F-0 merged (Core tasks may start) · **G2** = F-4, F-5, F-16, F-9 and DS-1/2/3 merged (the
app runs; screens may start) · **G3** = SC-HD1 merged (the golden screen exists; copy it with `scripts/new_screen.py`).
**common** (in screen tasks) = F-4, F-5, F-9 (which brings F-16), DS-1, DS-2, DS-3.

**Start now (no dependencies):** **F-0**, **F-1**, **DS-1**, **DS-6**, **X-C1**, **X-1**, **X-2**, **X-6**, **X-7**.
**Suggested order:** F-0 (Lohitaksh) · F-1 then F-2, F-3 (Models) · DS-1 then DS-6 · X-C1 · X-1, X-2, X-6 · after G1: F-4, F-6,
F-11, F-13, F-14, F-15, then F-5, F-16, F-7, F-8, F-10 · G2: F-9 and DS-2/3/4/5, then components CP-1…CP-11, X-13, X-14 ·
G3: SC-HD1 first, then any screen whose dependencies are merged · other X tasks any time.

## Foundation (do first)

Details: `docs/tasks/00-foundation.md`

| ID | Task | Size | Depends on |
|---|---|---|---|
| **F-0** | Link VybeKit, set the concurrency and language modes, prove the architecture *(Lohitaksh only: project settings)* | M | — |
| **F-1** | IDs, shared value types and the JSON coder | S | — |
| **F-2** | Content models | M | F-1 |
| **F-3** | Community, chat and safety models | M | F-1 |
| **F-4** | Navigation: grouped Routes, Sheet, Cover, Router | M | F-0, F-1 |
| **F-5** | Content repositories, stubs, stores, settings, AppDependencies | L | F-0, F-1, F-2, F-4 |
| **F-6** | Hangout rules | S | F-0, F-2 |
| **F-7** | Community, chat and safety repositories + sample social data | M | F-3, F-5 |
| **F-8** | LocalData: loader, sample content, persistence, content test | L | F-2, F-5 |
| **F-9** | App shell: dependencies, tabs, thin screen factory | L | F-0, F-4, F-5, F-16, DS-1 |
| **F-10** | Live run store (survives the app closing) | M | F-2, F-5 |
| **F-11** | LocationService (real + simulated walk) | M | F-0, F-1 |
| **F-12** | (moved) ImageLoader is task DS-6 | S | — |
| **F-13** | PhotoProcessor (resize, strip location) | M | F-0, F-1 |
| **F-14** | NetworkMonitor and offline state | S | F-5 |
| **F-15** | Voice notes: AudioRecorder and player | M | F-0, F-1 |
| **F-16** | Feature `Screens` scaffolds (all 13 features) | M | F-4, F-5 |

## Design system and components

Details: `docs/tasks/10-design-system-and-components.md`

| ID | Task | Size | Depends on |
|---|---|---|---|
| **DS-1** | Theme: colours, type, spacing, radii, motion tokens | M | — |
| **DS-2** | State views: LoadStateView, EmptyStateView, ErrorView, OfflineBanner | M | F-1, DS-1 |
| **DS-3** | Buttons, chips, rows, fields | M | DS-1 |
| **DS-4** | Motion and haptic helpers | S | DS-1 |
| **DS-5** | Layout helpers: FlowLayout and skeleton shapes | S | DS-1 |
| **DS-6** | ImageLoader | M | — |
| **CP-1** | HangoutCard | M | DS-1, DS-5, DS-6, CP-3 |
| **CP-2** | SpotRow | M | DS-1, CP-3 |
| **CP-3** | PlaceImage and PhotoGallery | M | DS-1, DS-6 |
| **CP-4** | Avatar and AvatarStack | S | DS-1, CP-3 |
| **CP-5** | Badges and notes | S | DS-1 |
| **CP-6** | PostCard (feed card) | M | DS-1, CP-3, CP-4, CP-5, DS-5 |
| **CP-7** | CommentRow | M | DS-1, CP-4 |
| **CP-8** | Message bubbles | L | DS-1, CP-1, CP-3, CP-4 |
| **CP-9** | ProfileHeader | M | DS-1, CP-3, CP-4 |
| **CP-10** | Info pills and tag rows | S | DS-1, DS-5 |
| **CP-11** | Map pins | M | DS-1, CP-3 |

## Screens: onboarding, sign-in, Discover, Hangout detail

Details: `docs/tasks/20-screens-start-discover-detail.md`

| ID | Task | Size | Depends on |
|---|---|---|---|
| **SC-O1** | Welcome | S | common |
| **SC-O2** | Name and photo | M | common, F-13 |
| **SC-O3** | Interests | S | common, DS-5 |
| **SC-O4** | Location | M | common, F-11 |
| **SC-O5** | Find friends | M | common, F-7, CP-4 |
| **SC-A1** | Sign in | M | common, F-7 |
| **SC-A2** | Email sign-in | M | SC-A1 |
| **SC-A3** | Account basics | M | SC-A1, F-6 |
| **SC-D1** | Discover map | L | common, CP-1, CP-11, F-8 |
| **SC-D2** | Pin preview card | M | common, CP-1, SC-D1 |
| **SC-D3** | Filters sheet | M | common, DS-3, DS-5 |
| **SC-HD1** | Hangout detail | L | common, CP-1, CP-2, CP-3, CP-5, CP-10, F-10 |
| **SC-HD2** | Spot sheet | M | common, CP-1, CP-3, CP-5 |
| **SC-HD3** | Remix tree | M | common, CP-1, CP-4 |

## Screens: live Hangout, Search, Profile, Settings

Details: `docs/tasks/30-screens-live-search-profile.md`

| ID | Task | Size | Depends on |
|---|---|---|---|
| **SC-H1** | Hangout live | L | common, F-10, F-11, CP-2, DS-4 |
| **SC-H2** | Mark visited | M | common, F-13, F-10 |
| **SC-H3** | Summary | M | common, F-6, F-10, CP-3 |
| **SC-H4** | Live mini-bar | M | common, F-10, SC-H1 |
| **SC-S1** | Search | L | common, CP-1, CP-4, F-8 |
| **SC-S2** | See all | S | SC-S1 |
| **SC-PR1** | My profile | L | common, CP-1, CP-9, CP-6 |
| **SC-PR2** | Settings (root) | M | common, DS-3 |
| **SC-PR4** | Saved | M | common, CP-1 |
| **SC-PR5** | Drafts | M | common, CP-1, CP-5 |
| **SC-PR6** | Edit profile | M | common, F-13, DS-3, DS-5 |
| **SC-PR8** | Ready to post | M | common, F-6, CP-5 |
| **SC-ST-A** | Account settings and delete account (ST1, ST8) | M | common, DS-3 |
| **SC-ST-B** | Privacy, Blocked, Notifications (ST2, ST3, ST4) | M | common, DS-3, F-7 |
| **SC-ST-C** | Help, Place suggestions, About (ST5, ST6, ST7) | S | common, DS-3 |

## Screens: Community, Friends, Chat

Details: `docs/tasks/40-screens-community-friends-chat.md`

| ID | Task | Size | Depends on |
|---|---|---|---|
| **SC-CM1** | Feed | L | common, CP-1, CP-6, DS-4 |
| **SC-CM2** | Post detail | L | common, CP-1, CP-2, CP-3, CP-6, CP-7, CP-9 |
| **SC-CM3** | Comments | M | common, CP-7 |
| **SC-CM4** | Trending | S | common, CP-6 |
| **SC-CM5** | Activity | M | common, CP-4, F-7 |
| **SC-FR1** | Friends hub | M | common, CP-4, F-7 |
| **SC-PR3** | Other person's profile | M | common, CP-6, CP-9 |
| **SC-PR7** | Mutual friends | S | common, CP-4 |
| **SC-CH1** | Chats list | M | common, CP-4, F-7 |
| **SC-CH2** | Conversation | L | common, CP-8, F-15, F-13, SC-CH6 |
| **SC-CH3** | New chat or group | M | common, CP-4 |
| **SC-CH4** | Group info | M | common, CP-4 |
| **SC-CH5** | Share to… | M | common, CP-1, CP-4 |
| **SC-CH6** | Poll composer | S | common, CP-8 |
| **SC-CH7** | Group invitation | S | common, CP-4 |

## Screens: Editor, Posting, Report/Block, Admin

Details: `docs/tasks/50-screens-editor-posting-safety-admin.md`

| ID | Task | Size | Depends on |
|---|---|---|---|
| **SC-E1** | Hangout editor | L | common, F-6, CP-2, CP-10, SC-E2 |
| **SC-E2** | Add Spot | M | common, CP-3 |
| **SC-E3** | Suggest a Place | M | common, F-13, F-7 |
| **SC-PO1** | Post composer | L | common, F-6, CP-6 |
| **SC-PO2** | Edit post | M | common, CP-6 |
| **SC-R1** | Report | M | common, F-3, F-7 |
| **SC-R2** | Block confirm | S | common, SC-R1 |
| **SC-AD1** | Admin: reports queue | M | common, F-7 |
| **SC-AD2** | Admin: Place suggestions | S | SC-AD1 |
| **SC-AD3** | Admin: users | S | SC-AD1 |

## Cross-cutting, content, project settings

Details: `docs/tasks/60-cross-cutting-and-content.md`

| ID | Task | Size | Depends on |
|---|---|---|---|
| **X-C1** | First sample data: 5 Places + 2 Hangouts (with photos) | M | — |
| **X-C2** | Content batch: +15 Places with photos *(repeatable)* | M | X-C1 |
| **X-C3** | Content batch: +10 Hangouts / Picks from real past visits *(repeatable)* | M | X-C1 |
| **X-C4** | Sheet → JSON script (K1) | M | X-C1 |
| **X-1** | SwiftLint custom rules | S | — |
| **X-2** | GitHub Actions: lint on every PR | S | — |
| **X-3** | String Catalogs per module | M | F-0 |
| **X-4** | Accessibility review (repeat per feature) | M | SC-HD1 |
| **X-5** | Golden example, template refresh and screen generator | M | SC-HD1 |
| **X-6** | Create GitHub issues from the task files | S | — |
| **X-7** | App icon and launch screen placeholder | S | — |
| **X-13** | Architecture check script | S | F-16 |
| **X-14** | Agent loop: debug launch options and screenshot script | M | F-9, F-4 |
| **X-9** | Permissions, capabilities, simulated walk, privacy manifest | S | F-0 |
| **X-10** | UI-test target + accessibility audit | M | SC-O1, SC-HD1 |
| **X-11** | Quality and performance pass on the lab iPhone | M | SC-D1, SC-HD1, SC-H1, SC-CM1, SC-CH2 |
| **X-12** | Demo build and walkthrough | S | SC-D1, SC-HD1, SC-H1, SC-CM1, SC-CH2 |

## Backend (later)

Details: `docs/tasks/70-backend-later.md`

| ID | Task | Size | Depends on |
|---|---|---|---|
| **BK-1** | One-day backend test (login + one table + one listener + People prefix search with blocks + WhatsApp preview page) | L | — |
| **BK-2** | `VybeRemote` package + SDK exception decision | L | — |
| **BK-3** | Auth: Apple, Google, email code; username uniqueness; 30-day username hold | L | — |
| **BK-4** | Data rules: deny-by-default database and storage rules + rule tests in CI | L | — |
| **BK-5** | Hangouts, Places, Saves, runs, feed (friends-first fan-out) | L | — |
| **BK-6** | Friends, requests (caps, "Other" folder), blocks | L | — |
| **BK-7** | Chat: conversations, messages, read receipts, polls, voice/photo upload, group invitations | L | — |
| **BK-8** | Server functions: counters, Remix credit, account deletion cascade, `audience` rewrite, scheduled posts | L | — |
| **BK-9** | Push notifications (needs the paid Apple account) | L | — |
| **BK-10** | WEB1 share pages with WhatsApp preview and "I'm in" without an account | L | — |
| **BK-11** | Admin tooling server side + report auto-hide + on-call alerts | L | — |
| **BK-12** | Offline cache strategy (SDK cache or our own JSON) | L | — |
| **BK-13** | Privacy policy, Terms, grievance contact, lawyer review | L | — |
| **BK-14** | TestFlight pipeline (Xcode Cloud or Actions), demo account for App Review | L | — |
