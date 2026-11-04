# Day one: what to start today

Written 4 Nov 2026 after the replan. It lists only order and ownership, no dates. When G2 is passed (see below) this file
has done its job: delete it and work from `docs/TASKS.md`.

## 0. Everyone, before touching code
1. Read `AGENTS.md`, `docs/START-HERE.md` section 1 (rows 1 to 4) and `docs/adr/` **001, 002, 003** (about 10 minutes).
2. **Lohitaksh (gate G0):** read all of `docs/adr/` (001 to 007). Say "OK" in the group, or change an ADR first. A decision
   that is changed after teammates have written code is the expensive kind, so this comes first. The three that need your
   hands (project settings) are done inside task F-0.
3. Claim your task on its GitHub issue (X-6 creates them); until X-6 is run, say it in the group.

## 1. Who starts what (defaults; there are no fixed roles, swap freely)
All of these are independent: none of them edits a file another one needs today, and none waits for F-0.

| Person | Start with | Then (in order) | Edits only |
|---|---|---|---|
| **Lohitaksh** | **F-0** (link the package, set the modes, run the proofs) | F-4 → F-5 | `Package.swift`, project, `docs/adr/*`, then `Core/` |
| **Tanvi** | **F-1** (IDs, value types, JSON coder) → **F-2** (content models) | F-3 → F-6 and F-13 (after F-0 is merged) | `Models/`, `Tests/ContentTests` |
| **Atharva** | **DS-1** (Theme tokens) → **DS-6** (ImageLoader) | DS-4, DS-5 → DS-2, DS-3 → CP-5, CP-10 | `Design/`, `Components/` |
| **Shreya** | **X-C1** (5 real Places + 2 real Hangouts with photos) | X-1 (lint rules) → X-2 (CI) → X-6 (issues) → X-7 | `LocalData/Resources/Content/`, `.swiftlint.yml`, `.github/`, `scripts/` |

Why this split is safe today: Models, Design and content do not depend on the concurrency settings (Models is
non-isolated already; Design keeps main-actor by default). Anything that writes code in `Core/` waits for F-0 (gate G1).
Screens wait for gate G2. A second agent can run in parallel on the same person's list when two tasks are independent
(for example X-2 and X-6, or F-3 after F-1).

## 2. Do not start yet
- Any task in `Core/` (F-4 to F-7, F-10, F-11, F-13 to F-15) until F-0 is merged.
- Any screen (`SC-*`) until G2: F-4, F-5, F-16, F-9, DS-1/2/3 merged.
- The golden screen (SC-HD1) is built first; everything else copies it with `scripts/new_screen.py` (X-5).
- Backend tasks (BK-*), Package.swift or project changes by anyone but Lohitaksh.

## 3. The prompt for your AI tool (copy it, fill in the ID)
```
Read AGENTS.md, docs/START-HERE.md, the ADRs that task <ID> names in docs/adr/, and task <ID> in docs/tasks/.
Plan only. List every file you will create or change (it must match the task's "Files" line), the tests you will
write, and anything in the task that is unclear. Do not invent data. Wait for my OK before writing code.
```
After you say OK: *"Build it. Run ./scripts/check.sh and show me the full output. Then explain every line in plain words."*
Then, in a **fresh** session: *"Review my diff against task <ID> and docs/adr/. Skip style. Report only real problems."*

## 4. Watch-outs for the four starting tasks (paste the one for your task into the prompt)
- **F-0 (Lohitaksh):** each proof gets at most 60 minutes. If one fails, change the ADR first and tell the group before
  anyone writes code that depends on it. Do not commit signing files.
- **F-1 / F-2 (Models):** every type `public` with an explicit `public init`, `Sendable`, no SwiftUI. `ID` must be
  `CodingKeyRepresentable` and tested (a `[SpotID: Date]` must encode as a JSON object). Use `JSONCoding` for dates. Tests
  use the EXAMPLE JSON in `docs/DATA-MODEL.md` section 4, labelled `EXAMPLE`; never invent a real-looking venue.
- **DS-1 / DS-6 (Design):** propose the colour and type values in the PR; light only; no hex outside `Design/Theme`; colours
  must resolve through the package bundle in a preview. The ImageLoader is an `actor`; nothing here imports Core.
- **X-C1 (content):** real places you have visited and checked on a map, photos you took with a written OK and a credit,
  EXIF location stripped. The AI only formats JSON from your notes. Never copy data from Apple Maps or Google Maps. Never
  let the AI guess hours, prices or coordinates.
- **X-1 (lint):** every rule needs a deliberate-violation example that the rule catches. Do not weaken an existing rule.

## 5. Running four agents at once without collisions
1. One task per branch and per agent: `<initial>/<task-id>-<short-name>`, e.g. `t/f-1-ids-and-coder`.
2. The agent lists the files it will touch **before** writing; they must match the task's **Files** line. A Model, a Route,
   Theme, `Core/Navigation`, the App target or `Package.swift` outside your task means stop and ask.
3. Rebase on `main` before the PR; keep the PR small (about 300 lines).
4. Never silence a compiler warning, lint rule or test. Show the failing output instead.
5. If an agent suggests `@unchecked Sendable`, `nonisolated(unsafe)`, a new library, or a change to a setting: say no and ask.
6. If stuck for more than 30 minutes, ask a teammate or Lohitaksh.

## 6. What "done" looks like today
F-0 merged with the proofs recorded (G1). Models F-1, F-2 merged. Theme (DS-1) merged. The first real content and the lint
rules merged. Then Core (F-4, F-5, F-16) and the app shell (F-9) open the screens (G2).
