# START HERE (read this first, then take a task)

Vybe is an iPhone app for college students in Pune. People find real places, plan a
multi-stop outing called a **Hangout** (made of **Spots**), do it live on a map, and post
it for their friends. This file tells you what to read, how to work, and where everything is.

---

## 1. Read these before you take your first task (about 90 minutes, in this order)

| # | Read | Time | You learn |
|---|---|---|---|
| 1 | `docs/PRODUCT.md` sections 1, 2, 3, 4 | 10 min | what the app is, the exact words we use (Hangout, Spot, Remix, Picks), every feature |
| 2 | `docs/IA.md` sections 1, 2, 4, 6 | 15 min | every screen (with its ID like `D1`, `HD1`), where it sits, how you get there |
| 3 | `docs/ARCHITECTURE.md` sections 0, 1, 2.1-2.7, 3.2 | 30 min | MVVM, the router, the folder map, what may import what |
| 3a | `docs/adr/` 001, 002, 003 | 10 min | the three decisions that shape every file you write (concurrency, who owns a screen's wiring, navigation) |
| 4 | `AGENTS.md` (whole file, it is short) | 10 min | the rules every person and every AI tool follows |
| 5 | `docs/DATA-MODEL.md` sections 2, 3, 5 | 10 min | the data structs, IDs, privacy rules |
| 6 | `docs/MOTION.md` sections 2, 3 | 5 min | the five animation timings and the haptic rules |
| 7 | `docs/templates/new-screen/README.md` | 5 min | the shape of every screen (View + ViewModel + Preview + test) |
| 8 | the task you picked in `docs/tasks/` | 5 min | exactly what to build |

Read **only when your task needs it:** `docs/RISKS.md` section 3 (safety defaults: read it
before building anything that shows times, locations, posts or chat), `docs/PROCESS.md`
(PR checklist), `docs/BEFORE-BUILD.md` (setup), `docs/LATER.md` (not your problem yet),
`docs/OPEN-QUESTIONS.md` (if your task touches an open question, stop and ask).

The Figma file "05 · Full Prototype 3" is only a **loose reference** for mood and a few
ideas. It is not the spec. The spec is `docs/IA.md` and `docs/PRODUCT.md`.

## 2. How we work: a pool of tasks

There are no fixed roles. The task list (`docs/TASKS.md`, details in `docs/tasks/`) is a pool:

1. **Pick** a task whose "Depends on" tasks are merged (see the board). Put your name on the
   GitHub issue for it (one issue per task) so two people don't take the same one.
2. **Plan first** (also with AI): read "Read first", then write down what you will create.
3. **Branch**: `<your-initial>/<task-id>-<short-name>`, for example `t/sc-d1-discover-map` (same pattern as `AGENTS.md` section 7).
4. **Build** exactly what the task says. Use the template in `docs/templates/new-screen/`.
5. **Check**: `./scripts/check.sh` must pass. Add the three previews and a ViewModel test.
6. **Pull request** (about 300 lines or fewer): fill in the template, paste the check output
   and a simulator screenshot, write "In my own words" (3 to 5 sentences). You must be able
   to explain every line.
7. **Merge** (squash) in a merge window (13:00 or 19:00) after Lohitaksh reviews. Then take
   the **next task**. Never sit idle: if everything is blocked, review someone's PR.

**Files only Lohitaksh edits** (they are shared by everyone): `VybeKit/Package.swift`,
`Vybe.xcodeproj`, signing. Lohitaksh also reviews every change to `Models/`, `Core/Navigation/`,
`Design/Theme/`, the App target, `AGENTS.md`, `docs/adr/` and `.github/`. Everything else is fair game inside your
task's folder (your feature's screen folder, your `case` in `<Name>Screens.swift`, your tests). If you think a shared
file needs a change, ask in the group; do not edit it.

## 3. The map of the repository

```
MIT-IOS-COHORT26-4/
├── AGENTS.md  CLAUDE.md          rules for AI tools (CLAUDE.md just says @AGENTS.md)
├── docs/                         all the documents (this file, DAY-ONE, the tasks, IA, architecture, adr/...)
├── Vybe/                         THE APP TARGET: only wiring (tabs, router hookup, dependencies)
├── Vybe.xcodeproj  VybeTests/    Xcode project (Lohitaksh only) and app-level tests
├── VybeKit/                      THE LOCAL PACKAGE: nearly all the code lives here
│   ├── Package.swift             lists targets and what each may import (Lohitaksh only)
│   ├── Sources/
│   │   ├── Models/               data structs (Place, Hangout...), LoadState, AppError
│   │   ├── Core/                 router, repository protocols, stores, services, rules, fakes
│   │   ├── Design/               Theme (colours, fonts, spacing, motion) + basic views
│   │   ├── Components/           shared views (HangoutCard, SpotRow...)
│   │   ├── LocalData/            sample JSON + photos + library.json (version-1 data source)
│   │   └── <Name>Feature/ × 13   one folder per area; one sub-folder per screen
│   └── Tests/                    one test target per module
├── Config/  backend/  scripts/   signing template, server (later), check.sh
└── .github/                      PR template, issue templates, code owners
```

Every folder under `VybeKit/Sources/` has a `README.md` saying what goes there and what it
may import. The full map is in `docs/ARCHITECTURE.md` section 3.2.

## 4. The five rules to remember

1. **A screen = a View (layout only) + a ViewModel (all logic, no SwiftUI import).** Both are `internal`; a feature's
   only `public` type is its `<Name>Screens`, and you wire your screen by replacing your placeholder `case` there.
2. **Screens never open other screens.** They call `router.open(...)`. Features never import
   each other, `LocalData` or `Remote`.
3. **Only Theme tokens** for colours, fonts, spacing and animation. No hex, no raw `.easeInOut`.
4. **Every screen handles loading, empty and error**, uses real Kothrud names in previews,
   has accessibility labels, works at the largest text size, and has a ViewModel test.
5. **Use our words** (Hangout, Spot, Remix, Picks). Never Plan, Trace, Stop, outing.

## 5. Working with AI tools

Start every AI session with: **"Read AGENTS.md and the task <ID> in docs/tasks/. Plan
only; wait for my OK before writing code."** Paste the task's "Build" and "Done when"
into the prompt. Afterwards ask the AI to explain the code line by line. Then, in a **fresh**
AI session, ask it to review your diff against the task ("skip style"). Never paste
passwords, keys or personal data into an AI.

## 6. How to explain the structure in two minutes (for mentors and teammates)

> "Vybe is one iOS app made of a thin **app target** and a **local Swift package** called
> VybeKit. Inside the package each box is its own module, and each module declares what it
> may import, so the compiler stops one feature from reaching into another.
> **Models** are plain data. **Core** holds the rules of the app: the router, the data
> contracts (protocols) and the shared stores. **Design** holds our colours, fonts and
> animation timings. **Components** are reusable views. **LocalData** is today's data
> source: JSON files in the app. Later a separate **VybeRemote** package plugs into the same contracts, so
> no screen changes when we add a server. Each of the 13 **features** is a folder of
> screens with one public `Screens` type that builds them, and every screen is a View plus a ViewModel (MVVM). The **router** is the only way
> to go from one screen to another, and only the app target knows which screen a route
> opens. That is how four people can build different features at the same time without
> stepping on each other."
