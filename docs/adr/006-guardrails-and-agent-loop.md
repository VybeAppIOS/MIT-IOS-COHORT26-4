# 006: Machine-checked rules, debug launch options, screenshot script, screen generator, review tiers
Status: accepted as the working default (4 Nov 2026). Date: 4 Nov 2026

## Context
Four people and four AI agents will write most of the code in parallel. Prose rules in `AGENTS.md` get forgotten;
a rule a machine checks does not. Agents also work much better when they can run the thing and look at it, and when
they copy a finished example instead of following a description.

## Decision
1. **Anything a machine can check is checked by a machine**, in `./scripts/check.sh` and in CI (lint on every PR).
   SwiftLint custom rules (path-scoped, tasks X-1) plus a small script `scripts/check_architecture.sh` (task X-13):
   - no `import SwiftUI`, `UIKit`, `MapKit` in `*ViewModel.swift`, `Models/`, `Core/`, `LocalData/`;
   - in `*Feature/`, `public` appears only in `*Screens.swift`;
   - `AppDependencies` is mentioned only in `*Screens.swift`, `Core/` and `Vybe/`;
   - `@MainActor` in `Core/` only on `Router`, stores, `NetworkMonitor` and `AppDependencies.preview`;
   - `RunTimes` appears only in Models, Core, LocalData, Remote, LiveFeature, PostingFeature, ProfileFeature
     (own runs); never in Community, Friends, Chat, Search, Moderation, Discover, HangoutDetail, Onboarding, Auth;
   - every feature has `<Name>Screens.swift`; every `FooViewModel.swift` has a `FooViewModelTests.swift`;
   - the existing bans (hex colours, `.system(size:`, raw animation curves, `print(`, `canOpenURL`, banned words in
     strings, deprecated APIs, `@unsafe`/`@unchecked Sendable`/`nonisolated(unsafe)` without a `// allowed:` reason).
   Disabling or weakening a rule needs a human (`AGENTS.md` 6).
2. **Debug launch options (task X-14)**, compiled only in DEBUG: `-stubMode loaded|empty|failing|loading`,
   `-debugRoute <JSON Route or short form>`, `-skipOnboarding`, `-resetState`, `-simulateWalk`. They let an agent or a
   UI test open exactly one screen in exactly one state.
3. **`scripts/snap.sh <name> <route> <mode>` (X-14)** boots a simulator, launches the app with those options and writes a
   PNG to `build/screenshots/`. Every screen PR attaches loaded, empty and error screenshots made this way, and an
   agent can look at its own result before asking for review.
4. **`scripts/new_screen.py <Feature> <Screen>` (X-5)** copies the golden screen (SC-HD1) into a new folder
   (View, ViewModel, Preview, test, `Screens` case, route case). Nobody starts a screen from a blank file.
5. **Review tiers: a proposal for Lohitaksh to accept or reject at G0; until he says OK he reviews every PR as before.**
   Proposed split (to match `.github/CODEOWNERS`): hotspots (`Package.swift`, project settings, `Models/`,
   `Core/Navigation/`, `Design/Theme/`, `AGENTS.md`, `.github/`, `docs/adr/`) are reviewed by Lohitaksh. Everything
   else is reviewed by one teammate who did not write it plus a fresh-session AI review against the task; Lohitaksh
   spot-checks and asks the two "why" questions on a sample. One reviewer for every PR is a single point of failure.
6. **Parallel-agent hygiene:** one task per branch and per agent; the agent first lists the files it will touch and
   they must match the task's **Files** line; anything outside it (a Model, a Route, Theme, Core, Package) means stop
   and ask; rebase on `main` before opening the PR.

## Consequences
Easier: consistent shape across 60 screens; reviews focus on logic, not style; agents self-verify. Harder: a one-time
cost to write the rules; false positives need tuning (a lint exception is a change to the rule, reviewed by the lead).
Undo: per rule.
