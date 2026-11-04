# Theme tokens (DS-1)

Code: `VybeKit/Sources/Design/Theme/`. Colour values: `VybeKit/Sources/Design/Resources/Colors.xcassets`.
Use only `Theme.Color`, `Theme.Font`, `Theme.Spacing`, `Theme.Radius` and `Theme.Motion` in views (AGENTS.md 5a).
Values below are **proposals** for the group to agree in the DS-1 PR (OPEN-QUESTIONS 9).
**Accent: teal is Atharva's proposal and is PENDING team approval.** Every other value is also a proposal.

## Colour (light only, sRGB)

| Token | Asset | Value | Use |
|---|---|---|---|
| `Theme.Color.surface` | Surface | 0.949 / 0.949 / 0.969 | screen background |
| `Theme.Color.surfaceRaised` | SurfaceRaised | 1.000 / 1.000 / 1.000 | cards, rows on the background |
| `Theme.Color.textPrimary` | TextPrimary | 0.067 / 0.067 / 0.082 | main text |
| `Theme.Color.textSecondary` | TextSecondary | 0.420 / 0.420 / 0.451 | captions, hints |
| `Theme.Color.accent` | Accent | 0.000 / 0.480 / 0.480 (teal, PENDING approval) | buttons, selected chips, links |
| `Theme.Color.onAccent` | OnAccent | 1.000 / 1.000 / 1.000 | text and icons on the accent |
| `Theme.Color.positive` | Positive | 0.118 / 0.500 / 0.243 | success, visited |
| `Theme.Color.warning` | Warning | 0.851 / 0.467 / 0.024 | cautions (trek, monsoon) |
| `Theme.Color.critical` | Critical | 0.827 / 0.184 / 0.184 | errors, destructive actions |
| `Theme.Color.separator` | Separator | 0.235 / 0.235 / 0.263, alpha 0.29 | dividers |
| `Theme.Color.scrim` | Scrim | black, alpha 0.40 | dimming behind sheets and photos |

Never use colour alone to show state: pair it with an icon or text (AGENTS.md 5a).
Contrast (WCAG ratio, computed from the values above; AA for text needs 4.5):

| Pair | Ratio |
|---|---|
| onAccent on accent | 5.1 |
| textPrimary on surface | 16.9 |
| textSecondary on surface / on surfaceRaised | 4.7 / 5.3 |
| accent on surface | 4.6 |
| positive on surfaceRaised | 5.0 |
| critical on surfaceRaised | 5.0 |
| warning on surfaceRaised | 3.2 |

`warning` is for icons and fills only (3:1 is enough for graphics). Put the words next to it in `textPrimary`.

## Type
System text styles only, so everything follows Dynamic Type: `largeTitle, title, title2, title3, headline,
subheadline, body, callout, footnote, caption, caption2`. Never `.system(size:)`.

## Spacing and radius (points)
`Theme.Spacing`: tiny 4, small 8, medium 12, large 16, extraLarge 24, huge 32. `Theme.Radius`: small 8, medium 12, large 20.
For spacing that should grow with text size, wrap the value in `@ScaledMetric`.

## Sizes
`Theme.Size.minTapTarget` = 44 (AGENTS.md 5a). `Theme.Size.readableContentMaxWidth` is `nil` on purpose:
**the maximum width for reading text is an open design decision.** Nobody has chosen a number, so none is invented.
Once chosen, change that one line.

## Motion
Exactly `docs/MOTION.md` section 2: quick, standard, gentle, playful, fade, plus
`Theme.Motion.resolve(_:reduceMotion:)`. The `.vybeAnimation` helpers come in DS-4.

## Checking it
Open `Design/Theme/Theme.swift` in Xcode and run the `ThemeGallery` previews (normal and `.accessibility3`).
Every colour must appear, which proves the asset catalog resolves through the package bundle (`bundle: .module`).
