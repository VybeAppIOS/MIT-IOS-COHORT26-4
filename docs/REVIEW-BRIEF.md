# Review brief (for a cloud or AI reviewer)

This repo is a **plan plus a skeleton**, not a finished app. There are no screens yet. Review the
documents for mistakes, contradictions and risks. Do not review it as if it were a code base.

## What to read, in order
1. `AGENTS.md`, `docs/START-HERE.md`, `docs/PRODUCT.md`
2. `docs/IA.md` (61 screens and navigation) and `docs/ARCHITECTURE.md` (the MVVM structure, modules, router)
3. `docs/DATA-MODEL.md` (every entity, privacy rules, Firebase and Postgres mappings)
4. `docs/RISKS.md` (safety defaults, legal), `docs/BEFORE-BUILD.md`, `docs/OPEN-QUESTIONS.md`
5. `docs/TASKS.md` and `docs/tasks/*.md` (116 tasks), `VybeKit/Package.swift`

## What to look for
1. **Contradictions** between documents (a screen, rule or word that one file says differently from another).
2. **Architecture holes:** anything that will be expensive to change later (navigation, data flow, import rules,
   concurrency, the swap from local data to a backend).
3. **Backend design:** `docs/DATA-MODEL.md` against `docs/tasks/70-backend-later.md`. Check data rules (who can read
   or write what), the friends-first feed, blocks and private posts, chat, account deletion, and cost.
4. **Safety and legal:** `docs/RISKS.md` against Apple guidelines 1.2, 4.8 and 5.1.1(v), the India IT Rules and
   the DPDP Rules. List only claims that should be checked with a lawyer.
5. **Task pool:** a missing dependency, an oversized task, or a screen with no task.
6. **Swift and SwiftUI:** the sketches in `docs/ARCHITECTURE.md` (Router, ViewModel pattern) and `Package.swift`.

## Rules for the reviewer
- Do not change files. Report findings only: file, section, problem, suggested fix, and how sure you are.
- Mark anything you could not verify. Do not invent API names or legal rules.
- Keep the project vocabulary: Hangout, Spot, Remix, Picks (see `AGENTS.md` section 3).
