# Building screens (start here on screen day)

Everything a screen needs exists: models, repositories with sample data, stores, the Router, the app shell, the design
system, every shared component, debug launch options, a screenshot script and a screen generator. A screen task is now
**one folder in one feature plus one line in its `Screens` file**. Background for each piece: `docs/REVIEW-4-NOV.md`.

## 1. Start a screen (5 minutes)
```bash
git fetch origin && git checkout -b t/sc-pr4-saved origin/main          # one task, one branch, base main
python3 scripts/new_screen.py Profile Saved                             # View, ViewModel, previews, test, strings
```
Then replace the placeholder `case` in `ProfileScreens.swift` with the line the script prints. The app now shows your
screen; the previews show loaded, empty, error, loading and large text.

## 2. The six things every screen uses
| You need | Use | From |
|---|---|---|
| the screen's state | `private(set) var state: LoadState<YourContent>` in the ViewModel, drawn by `LoadStateView` | F-1, DS-2 |
| data | the repository in the ViewModel's `init` (`hangouts`, `places`, `feed`, `chat` …), called in `fetch()` | F-5, F-7, F-8 |
| going somewhere | `router.open(.hangout(id))`, `router.present(.spot(id))`, `router.presentCover(.live(id))` | F-4 |
| shared state | `libraryStore` (Saved, Drafts), `liveStore` (the live Hangout), `session` (who, blocked), `badges` | F-5, F-10, F-7 |
| looks | `Theme.Color/Font/Spacing/Radius/Motion`, never numbers or hex | DS-1 |
| words | `String(localized: "feature.screen.key", bundle: #bundle)` in the ViewModel; every feature has a catalog | X-3 |

## 3. The components (plain values in, no ViewModel)
| Component | Build its data with | Used on |
|---|---|---|
| `HangoutCard(data, style: .regular/.compact/.featured) { tap }` | `HangoutCardData(hangout, coverURL:, isSaved:)` | Discover, Search, Saved, Drafts, Profile, Chat |
| `SpotRow(data, showsReorderHandle:)` | `SpotRowData(spot:place:order:total:state:)` | Hangout detail, Live, Editor |
| `PhotoGallery(photos:)`, `PlaceImage(url:aspectRatio:)` | `GalleryPhoto(id:url:credit:)`; URLs from `deps.photos.url(for:)` | Hangout detail, Spot sheet, cards |
| `PostCard(data, actions:)`, `RouteMiniMap(points:)` | `PostCardData(post, coverURL:, avatarURL:, routePoints:, …)` (never `RunTimes`) | Feed, Post detail, Profile |
| `CommentRow(data, actions:)`, `MoreRepliesButton` | `CommentRowData(…)` | Comments |
| `MessageBubble(data, actions:)`, `VoiceNoteBubble`, `PollBubble` | `MessageRowData(id:senderName:isMine:content:)` | Conversation |
| `ProfileHeader(data, relationship:) { tap }` | `ProfileHeaderData(…)`, `ProfileRelationship` | My profile, other profile |
| `Avatar`, `AvatarStack` | name and photo URL | everywhere people appear |
| `HangoutPin`, `ClusterPin` | title, category, `isSelected` | Discover map (inside a MapKit `Annotation`) |
| `PrimaryButton`, `SecondaryButton`, `IconButton`, `FilterChip`, `NavRow`, `ToggleRow`, `InfoRow`, `SectionHeader`, `SearchField`, `VybeTextField` | text and an action | forms, settings, filters |
| `InfoPill`, `TagRow`, `BestTimeLabel`, `PickBadge`, `StatusBadge`, `ClosedBadge`, `SafetyNote` | display text | cards, details |
| `LoadStateView`, `EmptyStateView`, `ErrorView`, `OfflineBanner`, skeletons, `FlowLayout` | the ViewModel's `state` | every data screen |

## 4. The routine for every screen (45 to 90 minutes)
1. Read your task in `docs/tasks/` and the screen's row in `docs/IA.md`. Write a 3-line plan in your own words.
2. Generate the screen (section 1), then ask the AI to fill **the ViewModel first** (what to load, what each tap does), then
   the View (layout only).
3. Look at it: the previews, then the simulator. `scripts/snap.sh <name> <route> all` takes loaded, empty, error and loading
   screenshots (`docs/PROCESS.md` 4.6). This is your review.
4. Ask the AI three "why" questions, then change one thing yourself and predict the result.
5. `./scripts/check.sh` (lint, architecture rules, tests). Open the PR with **base `main`**, the screenshots, the `check.sh`
   output and 3 to 5 sentences "In my own words".

## 5. Traps
- Text without `bundle: #bundle` shows the key on screen. Never `#bundle` in a test file.
- Load in `.task`, never in `init`; `catch is CancellationError { return }`.
- No `import SwiftUI` or `MapKit` in a ViewModel. Formatting (₹, km, "about 3 h") lives in the `*Data` builders and
  `DisplayFormat`, not in the View.
- The app's bundled content is empty until real Places are added (`docs/ADD-A-PLACE.md`); use the previews and
  `-stubMode loaded` (X-14) to see sample data in the simulator.
- A Release build stops at launch until the backend exists (`docs/OPEN-QUESTIONS.md` 8d); always run Debug.
