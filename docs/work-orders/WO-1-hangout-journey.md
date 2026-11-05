# Work order 1: The Hangout journey

**From first launch to finishing a Hangout.** Size: 18 screens, about 37 points (S=1, M=2, L=3).

**You own these feature folders (and nobody else edits them):**
`OnboardingFeature/`, `AuthFeature/`, `DiscoverFeature/`, `HangoutDetailFeature/`, `LiveFeature/`

Every screen below depends only on screens in this list, plus things that are already merged (router, stubs, sample data,
components, design system). You never wait for a teammate's screen.

## Before you start (once)
1. `git checkout main && git pull`, then read `AGENTS.md`, `docs/SCREENS-GUIDE.md`, and your task in `docs/tasks/`.
2. Your AI tool plans first, you say OK, then it builds (AGENTS.md section 1).
3. **X-9 (Xcode project settings) is needed in this lane.** Screens O2, O4, H1 and H2 use photos and location. Lohitaksh does
   X-9 before those four; until then build them against the stubs and `SimulatedLocationService`.
4. Real Places and Hangouts arrive with X-C1. Until then the screens run on sample data from the stubs.

## Build order (each line only needs the line above it)
| # | Screen | Size | Folder | Needs from this list |
|---|---|---|---|---|
| 1 | **SC-HD1** Hangout detail | L | `HangoutDetailFeature/Detail` | nothing. **Do this first**: the golden example (X-5) and X-4 wait on it. |
| 2 | SC-HD2 Spot sheet | M | `.../SpotSheet` | nothing |
| 3 | SC-HD3 Remix tree | M | `.../RemixTree` | nothing |
| 4 | **SC-D1** Discover map | L | `DiscoverFeature/Map` | nothing |
| 5 | SC-D2 Pin preview card | M | `.../PinPreview` | D1 |
| 6 | SC-D3 Filters sheet | M | `.../Filters` | nothing |
| 7 | SC-O1 Welcome | S | `OnboardingFeature/Welcome` | nothing |
| 8 | SC-O2 Name and photo | M | `.../NameAndPhoto` | nothing |
| 9 | SC-O3 Interests | S | `.../Interests` | nothing |
| 10 | SC-O4 Location | M | `.../Location` | nothing |
| 11 | SC-O5 Find friends | M | `.../FindFriends` | nothing |
| 12 | SC-A1 Sign in | M | `AuthFeature/SignIn` | nothing |
| 13 | SC-A2 Email sign-in | M | `.../EmailCode` | A1 |
| 14 | SC-A3 Account basics | M | `.../AccountBasics` | A1 |
| 15 | **SC-H1** Hangout live | L | `LiveFeature/Live` | nothing |
| 16 | SC-H2 Mark visited | M | `.../MarkVisited` | nothing |
| 17 | SC-H3 Summary | M | `.../Summary` | nothing |
| 18 | SC-H4 Live mini-bar | M | `.../MiniBar` | H1 |

Easy chains to remember: D1 then D2. A1 then A2 and A3. H1 then H4.

## Rules for every screen (from AGENTS.md)
- Replace only your screen's placeholder `case` in `<Name>Screens.swift`. Do not edit `Core/Navigation`, `Models`,
  `Package.swift`, the App target or another feature. If you need a change there, ask Lohitaksh.
- View + ViewModel + previews (loaded, empty, error, large text) + a ViewModel test + `./scripts/check.sh` + a PR with
  screenshot and "In my own words" written by you.
- Get a screenshot with `scripts/snap.sh <name> <route> all`, for example
  `scripts/snap.sh hd1 hangout/hangout-example-evening-c3d4 all`.
- Branch: `<initial>/<task-id>-<short-name>`, PR title `SC-HD1: what it does`. Small PRs, squash-merge.
