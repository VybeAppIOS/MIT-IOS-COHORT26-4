# Vybe: Team Plan

## 1. Team and deadlines
- 4 people: Lohitaksh (lead), Tanvi, Atharva, Shreya.
  All new to shipping code, heavily AI-assisted.
- **Phase 1 feature freeze: Thu 5 Nov 2026, 18:00.** Bug fixes only on Fri 6 Nov until 18:00.
- **Vacation 7 to 15 Nov:** no one can build or run the app. Light work only:
  pitching practice and research from `docs/OPEN-QUESTIONS.md`.
- **Phase 2: 16 Nov to 18 Dec.** Backend, accounts, Community, chat, verification, TestFlight.
- Lohitaksh builds the backend; everyone can learn.
- Rule: never merge code a teammate cannot explain.

## 2. Team rules
- Branches: `initial/screen-id-short-name`, e.g. `t/d1-discover-map`. Live under 1 day.
- Nothing is pushed to main. Everything goes through a pull request. Squash-merge.
- PR: about 300 lines max. Title "ID: what it does".
  Description: how to test, screenshot, which AI used, and "In my own words" (3 to 5 sentences).
- Lohitaksh reviews every PR this week and asks two "why" questions.
- Done = builds, runs on the simulator, loading/empty/error states, uses Theme tokens,
  has a #Preview, and the author can explain every line.
- Stand-up 9:30 daily. Merge windows 13:00 and 19:00. Push unfinished work by 21:00.
- Never paste passwords, keys or personal data into any AI.
- Start each AI task with: "Read AGENTS.md and docs/PRODUCT.md. Plan only, no code yet."

## 3. Phase 1 work packages
| ID | Package | Needs | Notes |
|---|---|---|---|
| F0 | Foundation | decisions | project, VybeCore, models, JSON loading, store, Theme, tabs, router, docs |
| C1 | Components A | Figma | HangoutCard, PlaceImage, Avatar (each with #Preview) |
| C2 | Components B | Figma | SpotRow, FilterChip, PrimaryButton, SecondaryButton, EmptyStateView |
| K1 | Content pipeline | sheet | sheet to JSON script, photo resize |
| W1 | Onboarding | F0, C2 | O1-O4, remember completion (@AppStorage) |
| W2 | Discover | F0, C1, C2 | D1-D3 (hardest screen) |
| W3 | Hangout detail | F0, C1, C2 | HD1-HD2, Save, Share |
| W4 | Search | F0, C1 | S1, rank by previous tab |
| W5 | Profile | F0, C1, W3 | PR1-PR2 |
| W6 | Hangout live | W3 | H1-H3 |
| I1 | Join it up | all | onboarding to tabs, pin to Hangout detail to live to summary |
| Q1 | Bug hunt | I1 | test on the lab iPhone; log bugs as GitHub issues |

C1 and C2 are work packages (components), not screens. CM1 is the Community screen.

## 4. Schedule
- **Mon 2:** F0 docs and project (done), C1, C2, K1.
- **Tue 3:** F0 code, then W3, W2, W1, W4.
- **Wed 4:** reviews, W2, W5, W6.
- **Thu 5:** I1, fixes, freeze at 18:00.
- **Fri 6:** Q1.

If Hangout live slips, cut the H3 photos first, then the route line. Never cut Mark visited.

## 5. F0 foundation steps (Lohitaksh)
1. Branch `l/f0-foundation`. Xcode project moved into the repo (iOS 18, iPhone, portrait, light).
2. `docs/PRODUCT.md`, `docs/PLAN.md`, `docs/OPEN-QUESTIONS.md`, `AGENTS.md`, `CLAUDE.md`.
3. PR 1 "F0: Project and docs". Merge. Tell the team to pull main.
4. VybeCore package: models as Codable structs, JSON loader, a test that loads every file.
5. Sample JSON (real Kothrud names). Shared store in the Environment.
6. Theme tokens. Tab shell (Discover, Community placeholder, Search, Profile), one
   NavigationStack per tab, Route enum with IDs only.
7. Run on the simulator and on the lab iPhone (signing only on his Mac, uncommitted).

## 6. Phase 2 cut order (if 18 Dec is at risk)
1. Voice notes. 2. Chat polls. 3. Threaded replies (flat first). 4. Remix credit on the map.

## 7. Vacation tasks (7 to 15 Nov, no building)
- Research items in `docs/OPEN-QUESTIONS.md` (backend, legal, Places source).
- Ask mentors the questions marked for them.
- Pitching practice. Plan the first TestFlight round.
