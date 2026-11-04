# Design system (`Design`) and shared components (`Components`)

Read first: `docs/START-HERE.md`, `docs/MOTION.md` 2 and 3, `AGENTS.md` sections 5 and 5a.
`Design` imports `Models` only. `Components` imports `Models` and `Design` only (so a component
takes **plain values**, has **no ViewModel**, and loads nothing itself). Every task here needs:
`#Preview`s for every variant and state (default, long text, large text `.accessibility3`,
Reduce Motion where relevant), accessibility labels, 44 pt tap targets, Theme tokens only, real
Kothrud wording in previews. No ViewModel test is needed, but add a snapshot-free logic test if
the component has logic (for example a text-formatting function).

### DS-1 — Theme: colours, type, spacing, radii, motion tokens  `[M]`
- **Depends on:** nothing (the group must agree the values; propose them in the PR)
- **Read:** MOTION 2 · AGENTS 5a · OPEN-QUESTIONS 9 (Design) · the Figma file only for mood
- **Build in `Design/Theme/` and `Design/Resources/Colors.xcassets`:**
  - Colour sets (light only, one appearance each), named semantically: `Surface, SurfaceRaised,
    TextPrimary, TextSecondary, Accent, OnAccent, Positive, Warning, Critical, Separator, Scrim`.
    Start from system-friendly values; the group picks the accent. Document values in `docs/TOKENS.md`.
  - `Theme.Color`, `Theme.Font` (text styles only: `.largeTitle … .caption`, optional `relativeTo:`
    custom face later; **never** `.system(size:)`), `Theme.Spacing` (4, 8, 12, 16, 24, 32),
    `Theme.Radius` (8, 12, 20), `Theme.Motion` exactly as MOTION 2 (`quick, standard, gentle,
    playful, fade`, `resolve(_:reduceMotion:)`).
  - A `ThemeGallery` `#Preview` showing every token.
- **Files:** `Design/Theme/Theme.swift, Colors.swift, Typography.swift, Spacing.swift, Motion.swift`,
  `Design/Resources/Colors.xcassets/*`, `docs/TOKENS.md`
- **Done when:** gallery preview renders; colours resolve through the package bundle (`bundle: .module`,
  verify in the preview); there is no hex or literal font size outside this folder.

### DS-2 — State views: LoadStateView, EmptyStateView, ErrorView, OfflineBanner  `[M]`
- **Depends on:** F-1, DS-1
- **Read:** ARCHITECTURE 2.5 · IA 4 (X1) · PRODUCT 4 (Offline)
- **Build in `Design/Views/`:** `LoadStateView(_ state: LoadState<C>, onRetry:, content:)` showing: a
  skeleton (`.redacted(reason: .placeholder)` over a caller-supplied placeholder), loaded content (adds the
  offline banner when `isStale`), `EmptyStateView` (`ContentUnavailableView`-style: icon, one friendly line
  in our tone, optional action button), `ErrorView` (`AppError.message`, **Retry**). `OfflineBanner`
  ("You're offline. Showing what you last saw.") and a `.offlineReadOnly(_:)` modifier that disables controls.
- **Files:** `Design/Views/LoadStateView.swift, EmptyStateView.swift, ErrorView.swift, OfflineBanner.swift`
- **Done when:** previews for loading, loaded, stale, empty (with and without action), error; VoiceOver
  reads the empty/error text and the retry button; works at `.accessibility3`.

### DS-3 — Buttons, chips, rows, fields  `[M]`
- **Depends on:** DS-1
- **Read:** MOTION 3 (haptics) · AGENTS 5a · IA 4 (D3 filters, ST pages)
- **Build in `Design/Views/`:** `PrimaryButton` (one per screen; large, full width; loading and disabled
  states), `SecondaryButton`, `IconButton` (44×44, `accessibilityLabel` required by the initializer),
  `FilterChip` (selected / unselected, `.selection` haptic), `NavRow`, `ToggleRow`, `InfoRow`,
  `SectionHeader`, `VybeTextFieldStyle` (with error text), `SearchFieldStyle`. Fixed labels are literals in
  the String Catalog.
- **Files:** `Design/Views/*.swift`
- **Done when:** previews in every state; the primary button text "Start Hangout" fits at the largest
  text size by wrapping; buttons expose traits `.isButton`; no hard-coded colours.

### DS-4 — Motion and haptic helpers  `[S]`
- **Depends on:** DS-1
- **Read:** MOTION 2, 3, 5
- **Build in `Design/Theme/`:** `.vybeAnimation(_:value:)` modifier and `withVybeAnimation(_:_:)` (both
  read Reduce Motion), `Theme.Motion.slideUp(reduceMotion:)` transition, and a `VybeHaptic` enum
  (`selection, start, stop, success, like`) with a `View.vybeHaptic(_:trigger:)` wrapper over
  `.sensoryFeedback`. Add the SwiftLint custom rules from MOTION 5 as task X-1 (not here).
- **Files:** `Design/Theme/MotionModifiers.swift, Haptics.swift`
- **Done when:** a preview toggling a value animates normally and as a plain fade with
  `.environment(\.accessibilityReduceMotion, true)`.

### DS-5 — Layout helpers: FlowLayout and skeleton shapes  `[S]`
- **Depends on:** DS-1
- **Build in `Design/Views/`:** `FlowLayout` (a `Layout` that wraps children onto new lines, for tag
  chips), `SkeletonBlock`/`SkeletonLine` placeholders, `ReadableContent` (max width for text so it still
  works if the window is resized).
- **Files:** `Design/Views/FlowLayout.swift, Skeleton.swift`
- **Done when:** previews with 3 and 30 chips; layout works at a narrow width and at `.accessibility3`.

### DS-6 — ImageLoader  `[M]`
- **Depends on:** nothing
- **Read:** ARCHITECTURE 4 (Images in the feed row)
- **Build in `Design/ImageLoader.swift`** (Design, because Components may import Design but not Core):
  `actor ImageLoader` with a `shared` instance, `NSCache` for decoded images, ImageIO downsampling to the
  requested pixel size, de-duplication of in-flight requests, works for `file://` and `https://`
  URLs, and a static `configureURLCache()` (50 MB memory / 200 MB disk) the app calls at launch.
  (This replaces task F-12 from the foundation list.)
- **Files:** `Design/ImageLoader.swift` · `Tests/DesignTests/ImageLoaderTests.swift`
- **Done when:** same URL twice loads once; downsample is no larger than requested; a missing file is an
  error value, not a crash.

---

## Components (take plain values, no ViewModel)

### CP-1 — HangoutCard  `[M]`
- **Depends on:** DS-1, DS-5, DS-6, CP-3
- **Read:** IA 4 (D2, CM1) · PRODUCT 2 (vocabulary), 5 (photo-led) · DATA-MODEL 3 (Hangout)
- **Build in `Components/`:** `HangoutCardData` (id, title, coverURL, spotCount, budgetText, durationText,
  tags, isPick, isSaved, authorName?) and `HangoutCard` in three styles: `.regular` (list), `.compact`
  (map preview and chat message), `.featured` (Picks row). Photo-led, tappable, Picks badge when
  `isPick`, a Save indicator, "3 Spots · ₹150–400 · about 3 h". Whole card is one accessibility element
  ("Hangout: title, 3 Spots, ₹150 to 400, about 3 hours, Picks").
- **Also:** `HangoutCardData.init(_ hangout: Hangout, coverURL: URL?, isSaved: Bool)`, built with the `Models`
  formatting helpers, so Discover, Search, Profile, Community and Chat all make a card the same way (a feature never
  formats "₹150–400" itself).
- **Files:** `Components/HangoutCard.swift, HangoutCardData.swift`
- **Done when:** previews: each style, long title, no photo, Picks, saved, `.accessibility3`.

### CP-2 — SpotRow  `[M]`
- **Depends on:** DS-1, CP-3
- **Read:** IA 4 (HD1, H1, E1) · DATA-MODEL 3 (Spot) · RISKS 3 (trek safety)
- **Build:** `SpotRowData` (order, placeName, categoryText, minutesText?, note?, state: `.normal / .visited /
  .current / .closedByAuthorities`, `hasDuplicateWarning`) and `SpotRow` with numbered marker, thumbnail,
  visited checkmark (never colour alone), "Closed by authorities" label, "You've added this place twice"
  warning, reorder handle variant for the editor.
- **Also:** `SpotRowData.init(...)` from a `Spot`, its `Place` and a state, with the same rule (formatting lives here, not in
  each ViewModel).
- **Files:** `Components/SpotRow.swift, SpotRowData.swift`
- **Done when:** previews for every state; VoiceOver reads "Spot 2 of 4, Name, visited".

### CP-3 — PlaceImage and PhotoGallery  `[M]`
- **Depends on:** DS-1, DS-6
- **Build:** `PlaceImage(url:aspectRatio:contentMode:)` using `ImageLoader.shared` with placeholder, fade-in
  (Reduce Motion aware), failure state; `PhotoGallery(urls:credits:)` swipeable pager with page dots and
  the photo credit line. Decorative images are `accessibilityHidden`; meaningful ones have a label.
- **Files:** `Components/PlaceImage.swift, PhotoGallery.swift`
- **Done when:** previews with bundle photos, a missing file, a slow load; a credit caption shows.

### CP-4 — Avatar and AvatarStack  `[S]`
- **Depends on:** DS-1, CP-3
- **Build:** `Avatar(url:name:size:isVerifiedVybe:)` (initials fallback, 5 sizes, a small verified ring for
  the official Vybe account) and `AvatarStack` ("+3"). Label: "Alex's profile photo" only when it is
  tappable; otherwise hidden.
- **Files:** `Components/Avatar.swift`
- **Done when:** previews with photo, initials, verified, stack of 1 / 3 / 8.

### CP-5 — Badges and notes  `[S]`
- **Depends on:** DS-1
- **Read:** PRODUCT 2 (Picks) · RISKS 3 · IA 4 (HD2)
- **Build:** `PickBadge`, `StatusBadge` (`saved, draft, scheduled, live, done`), `ClosedBadge`,
  `SafetyNote` banner (trek safety text; the **monsoon banner** June to September; a parameter chooses
  `.info / .warning`). Always icon + text, never colour only.
- **Files:** `Components/Badges.swift, SafetyNote.swift`
- **Done when:** previews for each; monsoon banner copy is short and calm.

### CP-6 — PostCard (feed card)  `[M]`
- **Depends on:** DS-1, CP-3, CP-4, CP-5, DS-5
- **Read:** PRODUCT 4 (Post card, Community) · IA 4 (CM1, CM2) · RISKS 3 (no exact times)
- **Build:** `PostCardData` (id, coverURL or route mini-map points, title, authorName, username, avatarURL,
  visitedSummary "3 of 5 Spots", budgetText, durationText ("about 3 h"), dayText, likeCount, commentCount,
  remixCount, isPick, isLiked, isSaved) and `PostCard` with Like / Comment / Remix / Share buttons as
  callbacks. A Picks post looks a little different (badge, verified avatar ring) but has the same actions.
  **Never** shows a clock time. Route mini-map = straight lines between Place pins (Canvas, no GPS).
- **Also:** `PostCardData.init(...)` built only from the public post fields (never `RunTimes`), using the `Models` formatting helpers.
- **Files:** `Components/PostCard.swift, PostCardData.swift, RouteMiniMap.swift`
- **Done when:** previews: photo post, no-photo (mini-map) post, Picks, liked, long caption; counts format
  with `.formatted(.number.notation(.compactName))`.

### CP-7 — CommentRow  `[M]`
- **Depends on:** DS-1, CP-4
- **Build:** `CommentRowData` (id, authorName, username, avatarURL, text, relativeTime text, likeCount,
  isLiked, depth, isDeleted, canDelete) and `CommentRow`: indent by depth (max 2 visible, then "View more
  replies"), like button, Reply, overflow menu callback (Report / Delete), "[deleted]" state.
- **Files:** `Components/CommentRow.swift`
- **Done when:** previews for depth 0/1/2, deleted, long text, liked.

### CP-8 — Message bubbles  `[L]`
- **Depends on:** DS-1, CP-1, CP-3, CP-4
- **Read:** PRODUCT 4 (Chat) · IA 4 (CH2, CH6) · DATA-MODEL 3 (Message)
- **Build:** `MessageRowData` and `MessageBubble` variants: text, photo (1 or 2), Hangout card (uses
  `HangoutCard(.compact)`), link, **voice note** (play/pause, progress, duration, waveform from levels),
  **poll** ("I'm in" / "Not for me" with counts and your vote), deleted ("This message was deleted"),
  edited tag, system line ("Alex added Priya"), read receipt (sent / delivered / seen), grouping of
  consecutive messages, mine vs theirs alignment.
- **Files:** `Components/MessageBubble.swift, VoiceNoteBubble.swift, PollBubble.swift`
- **Done when:** previews for every variant incl. long text and `.accessibility3`; VoiceOver reads
  sender + content + "seen".

### CP-9 — ProfileHeader  `[M]`
- **Depends on:** DS-1, CP-3, CP-4
- **Read:** IA 4 (PR1, PR3) · PRODUCT 4 (Accounts, Friends)
- **Build:** `ProfileHeaderData` (name, username, bio?, bannerURL?, avatarURL, stats: Hangouts done, Spots
  visited, friends count (own profile only), mutualFriendsText?) and `ProfileHeader` with a **relationship
  button** variant: `.own(edit)`, `.addFriend`, `.requested`, `.respond`, `.friends`, `.blocked`,
  `.privateGate`.
- **Files:** `Components/ProfileHeader.swift`
- **Done when:** previews for every relationship state, no banner, long bio.

### CP-10 — Info pills and tag rows  `[S]`
- **Depends on:** DS-1, DS-5
- **Build:** `InfoPill(icon:text:)` (budget, time, spot count), `TagRow(tags:)` using `FlowLayout`,
  `BestTimeLabel`. Used by cards and Hangout detail.
- **Files:** `Components/InfoPill.swift, TagRow.swift`
- **Done when:** previews with 2 and 12 tags wrap correctly; large text wraps.

### CP-11 — Map pins  `[M]`
- **Depends on:** DS-1, CP-3
- **Read:** ARCHITECTURE 4 (Pin clustering) · IA 4 (D1)
- **Build:** `HangoutPin` (small photo thumbnail or category icon, selected state with scale animation),
  `ClusterPin` (count), both with accessibility labels ("3 Hangouts here, double tap to zoom"). Pure views
  used as `Annotation` content by SC-D1.
- **Files:** `Components/HangoutPin.swift, ClusterPin.swift`
- **Done when:** previews normal/selected/cluster of 2 and 25; touch target ≥ 44 pt.
