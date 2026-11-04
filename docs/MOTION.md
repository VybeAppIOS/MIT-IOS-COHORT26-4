# Vybe: Motion and Haptics

Status: proposal (3 Nov 2026) from Apple's Human Interface Guidelines (HIG), WWDC sessions and published motion systems (IBM Carbon,
Atlassian, Material). Animation **polish** is later work; the **rules and tokens** go in now so four people build consistent screens.

---

## 1. What Apple says (HIG Motion, Accessibility, Haptics, Materials)
- "Add motion purposefully… Don't add motion for the sake of adding motion." Generally avoid motion on interactions that occur
  frequently. "Make motion optional" (never the only way to show information) and "let people cancel motion" (never make people wait
  for an animation).
- System components (tab bar, sheets, navigation, search) already animate and adapt to accessibility settings: don't rebuild them.
- **Reduce Motion:** reduce zooming, scaling and peripheral motion; replace movement with fades; tighten springs; don't animate into or
  out of blurs. **Haptics:** system patterns for their documented meanings; don't overuse them.
- **Liquid Glass (iOS 26+):** for controls and navigation only, "sparingly"; never on content like photo cards.
- **Springs** (WWDC23 "Animate with springs"): two settings, duration and bounce. Bounce 0 for most things, about 0.15 brisk, about 0.3
  noticeable; careful above about 0.4.

## 2. Motion tokens (in `Theme`, owned by Lohitaksh)

| Token | SwiftUI value | Use |
|---|---|---|
| `quick` | `.snappy(duration: 0.25)` | taps, chips, toggles, small state changes |
| `standard` | `.smooth(duration: 0.35)` | default: cards, layout, list changes |
| `gentle` | `.smooth(duration: 0.6)` | big moves: map camera, live screen settling |
| `playful` | `.spring(duration: 0.45, bounce: 0.3)` | celebrations only (Mark visited, like) |
| `fade` | `.easeInOut(duration: 0.2)` | what every token becomes under Reduce Motion |

```swift
extension Theme {
    enum Motion {
        static let quick    = Animation.snappy(duration: 0.25)
        static let standard = Animation.smooth(duration: 0.35)
        static let gentle   = Animation.smooth(duration: 0.6)
        static let playful  = Animation.spring(duration: 0.45, bounce: 0.3)
        static let fade     = Animation.easeInOut(duration: 0.2)
        static func resolve(_ a: Animation, reduceMotion: Bool) -> Animation { reduceMotion ? fade : a }
    }
}
// Helpers every screen uses (in Design): .vybeAnimation(Theme.Motion.standard, value: x) and
// withVybeAnimation(Theme.Motion.playful) { ... }: both read Reduce Motion for you.
```

## 3. Rules
1. **System first.** No custom motion on the tab bar, sheets, navigation, search tab, pull-to-refresh, alerts or Liquid Glass bars.
2. **One hero moment per screen.** Everything else uses `quick` or `standard`.
3. **Bounce only on position and scale.** Opacity and colour never bounce.
4. **Nothing animates in on appear by default.** No looping or pulsing decorations.
5. **Reduce Motion:** tokens become `fade`, movement becomes fade, the map camera jumps, confetti is skipped. State must be readable
   without motion (checkmark + text).
6. **Haptics** (system `sensoryFeedback` only, real iPhone only): `.selection` filter chips and pin selection · `.start` / `.stop`
   Start and End Hangout · `.success` Mark visited · `.impact(weight: .light)` liking (not unliking) · none on plain navigation.
7. **Liquid Glass** only on floating map buttons (recentre, filters), inside one `GlassEffectContainer`. Photo cards and content never
   use glass.
8. **Enforced by SwiftLint (task X-1):** raw `.easeInOut`, `.spring(...)`, `.smooth` etc. outside `Theme`, and bare `withAnimation {`,
   are errors.

## 4. Signature moments

| # | Moment | How (min iOS) | Phase |
|---|---|---|---|
| 1 | Pin tap → pin preview card (D2) | system marker selection (17); card slides up with `standard`; `.selection` haptic | 1 |
| 2 | Card → Hangout detail (HD1) | **zoom transition**: `matchedTransitionSource` + `.navigationTransition(.zoom)` (18) | 1 |
| 3 | Filter chips | chip fill with `quick`; pins fade, never fly | 1 |
| 4 | Start Hangout → live (H1) | full-screen cover (zoom from the button); `.start` haptic; camera eases to the first Spot with `gentle`; distance digits roll with `.numericText` | 1 |
| 5 | **Mark visited** (the app's hero moment) | circle → checkmark with SF Symbol replace + bounce; `.success` haptic; the checkmark can use the draw-on symbol effect (iOS 26); confetti **once**, only when the last Spot is visited (Phase 2) | 1 (confetti 2) |
| 6 | Summary stats (H3) | numbers roll once to their final value with `.numericText` | 1 |
| 7 | Like | heart → filled heart, bounce with `playful`, count rolls, light haptic | 2 |
| 8 | Pull to refresh, Search tab | system only | 1 / 2 |

Later polish: stretchy photo header on HD1; the live mini-bar (H4).

## 5. How motion fits MVVM
- The **ViewModel** owns state (`visitedCount`, `isLiked`) and never calls `withAnimation`; its tests check state, not visuals.
- The **View** decides how changes look: a user tap `Button { withVybeAnimation(Theme.Motion.playful) { viewModel.markVisited(spot) } }`;
  a change coming from the ViewModel `.vybeAnimation(Theme.Motion.standard, value: viewModel.visitedCount)`; haptics and symbol
  effects use ViewModel state as the trigger `.sensoryFeedback(.success, trigger: viewModel.visitedCount)`.
- Screens with a hero moment get a Reduce Motion preview: `.environment(\.accessibilityReduceMotion, true)`.

## 6. What makes motion look cheap or AI-generated (avoid)
Everything fading in on appear; bounce everywhere; a different duration in every file; custom copies of system animations; pulsing or
shimmering loops; glass or blur on photo cards; a haptic on every tap; celebrations that replay or block input.

## 7. To check on a real device
Zoom transition under Reduce Motion (reported to fall back to a normal push; not in Apple's docs) · what the zoom back does if its
source card is gone · animating the map camera with `withAnimation` · whether 120 Hz needs the `CADisableMinimumFrameDurationOnPhone`
setting (a project change).

## Sources
Evidence links: `docs/SOURCES.md` (section "Motion and haptics").
