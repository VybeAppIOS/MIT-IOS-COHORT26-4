# Plan review (4 Nov 2026): what to improve, in priority order

Written after reading `AGENTS.md`, `PRODUCT.md`, `PLAN.md`, `BEFORE-BUILD.md`, `TASKS.md`, `ARCHITECTURE.md`
and `VybeKit/Package.swift`. Nothing here is built or run yet (the repo is a skeleton), so these are design
judgements, not test results. Items marked **Decision** need Lohitaksh because they touch `Package.swift`,
project settings or a team rule (`AGENTS.md` section 4).

## Done in this change
- Scope contradiction fixed: `AGENTS.md` section 9 now matches the 3 Nov decision (whole frontend on sample
  data first). "Phase 1/2" is defined as build order only.
- Branch and PR-title examples made identical in `AGENTS.md`, `START-HERE.md`, `PRODUCT.md` (`t/sc-d1-...`,
  `SC-D1: ...`). Stale "this week" wording removed. `ModelsTests` name corrected to `ContentTests`.
- `docs/PLAN.md` section 7 added: milestones, tiers, a cut line and weekly measuring (proposed).

## Still open
1. **Plan is 88% of available time (high).** Frontend 98 days vs 112 available, before backend (24 days) and
   fixes. Adopt `PLAN.md` section 7 and measure after 10 merged tasks. If speed is below estimate, cut Tier D,
   then Tier C pieces, never Tier A or the safety items.
2. **Decision: Core isolation is inverted (high).** Core defaults to MainActor, so every repository protocol,
   `Rules/` function, service and fake must be hand-marked `nonisolated` or `LocalData` fails to compile or
   silently loads JSON on the main thread. Beginners and AI tools will forget. Options: (a) make Core
   non-isolated by default and mark `Router` and the stores `@MainActor` explicitly (they already are in
   the sketches); (b) split Core into a non-isolated "contracts and rules" target and a main-actor "state and
   navigation" target. (a) is simpler. Decide before F-5.
3. **Decision: too many targets for four beginners (medium).** 13 feature targets plus 13 test targets from day
   one, all `public` APIs, one owner of `Package.swift`. Suggest one `SocialFeatures` target for Friends, Chat,
   Posting, Editor, Moderation, Auth until work on them starts, then split. Fewer test targets too.
4. **Preview spike is a hard gate (medium).** Do not start screens before F-0's preview test passes or the
   fallback (same-named folders in the app target) is chosen. Rewriting later is expensive.
5. **Route/Sheet/Cover enums are a merge-conflict hub (medium).** Let a feature owner add their own case
   and `ScreenFactory` stub in the same PR; CODEOWNERS covers the file, but review turnaround must be same day.
6. **Too much documentation to stay consistent (medium).** About 3,300 lines in `docs/`. Suggest:
   `AGENTS.md` plus a one-page architecture summary is the source of truth; other files are background.
   Extend `scripts/build_task_index.py` to check cross-file facts (branch pattern, target names, tab list).
7. **Swift 6 language mode (low).** Staying on Swift 5 mode is fine now; schedule the move before the `Remote`
   module, where concurrency bugs are most likely.
8. **Persistence safety (low, unverified).** Confirm `DATA-MODEL.md` has a schema version and atomic writes for
   `library.json`, since the live run must survive the app being killed.
9. **Legal and safety items stay with humans:** login method, account deletion, minors and DPDP, Places data
   source (`docs/OPEN-QUESTIONS.md`). Not decided here.
