# Rules for every AI tool in this repo

Applies to every tool and every teammate. Product details are in `docs/PRODUCT.md`.
Schedule and work packages are in `docs/PLAN.md`. Unanswered questions are in
`docs/OPEN-QUESTIONS.md`: if your task touches one, stop and ask a human.

## 1. Start of every task
Read `AGENTS.md` and `docs/PRODUCT.md`. Then **plan only, no code yet**.
Wait for the human to say OK before writing or changing files.

## 2. Who you are helping
Four college students who are new to shipping code and rely heavily on AI.
- Explain in plain language. Explain any jargon once.
- Keep tasks small: one screen or one concern per change, about 300 lines.
- After writing code, explain it line by line in plain words.
- Never produce code the author could not explain. Never merge what a teammate cannot explain.
- If stuck for over 30 minutes, tell the human to ask a teammate or Lohitaksh.

## 3. Vocabulary (code, comments and UI text)
| Use | Never use |
|---|---|
| Hangout | Plan, Trace, outing |
| Spot | Stop, Node |
| Remix | Fork, Make it yours |
| Picks (official Vybe Hangouts) | Featured, Curated |
| Start Hangout (the main button) | Go, Begin |

- A **Hangout** is a multi-spot day out. The same word is used whether it is saved,
  being done live, or posted.
- A **Spot** is one place inside a Hangout. A **Place** is the real venue on the map
  (code-level word; a Spot points to a Place).
- No "Organiser" and no voting in Phase 1. Polls ("I'm in" / "Not for me") come later,
  inside group chats only, never inside a Hangout.

## 4. Ask first (never do these without a human saying yes)
- Change signing, project settings, targets, or the iOS minimum.
- Add a library. No third-party libraries at all.
- Edit files outside your task or outside your own package folder.
- Push to main, force-push, or commit. Only commit when asked.
- Invent data. Places, coordinates, hours, prices and photos must be real.
- Copy data out of Apple Maps (MapKit) or Google Maps into our files. Their terms forbid
  storing it. Storing Apple's Place ID is allowed.

## 5. Architecture
- SwiftUI with `@Observable`. iOS 18 minimum. iPhone, portrait, light only.
- Xcode folders are synchronized: a new file inside `Vybe/` or `VybeTests/` is picked
  up automatically. Do not edit `Vybe.xcodeproj` or `project.pbxproj` by hand.
- Never touch signing settings or `Local.xcconfig` (per-machine, git-ignored).
- Models are plain `Codable` structs with stable string IDs. IDs never change once set.
- Screens never open other screens directly. They ask the router for a `Route`
  (for example `.hangout(id)`), and routes carry IDs only.
- One `NavigationStack` per tab.
- Screens get data only from the shared store, injected through the SwiftUI Environment.
  Screens never read files or talk to a server themselves.
- Import rules: Features never import each other. Shared views go in `Components`.
  Only `App` sees everything.
- All visual values (colour, font, spacing) come from `Theme` tokens.
  Do not hard-code them in views.

## 6. Definition of done
- `./scripts/check.sh` passes (SwiftLint, then tests on an iPhone simulator).
  If it fails, say so and show the output. Never silence, skip or weaken a check.
- It builds and runs on the simulator.
- Every data screen has loading, empty and error states.
- It uses Theme tokens.
- It has a `#Preview` that uses real Kothrud names, never lorem ipsum.
- The author can explain every line.

## 7. Git
- Branch: `initial/screen-id-short-name`, for example `t/d1-discover-map`. Short-lived.
- Everything goes through a pull request. Squash-merge. Small PRs.
- PR title: `ID: what it does` (IDs are in `docs/PRODUCT.md`).
- PR description: how to test, a screenshot, which AI was used,
  and "In my own words" (3 to 5 sentences written by the author).

## 8. Safety
Never paste passwords, keys or personal data into any AI.

## 9. Out of scope in Phase 1 (this week)
Real login or backend, posting, friends, chat, Community content (placeholder tab only),
creating Hangouts from scratch, Remix, Report, Dynamic Island, turn-by-turn navigation,
dark mode, iPad, landscape.
