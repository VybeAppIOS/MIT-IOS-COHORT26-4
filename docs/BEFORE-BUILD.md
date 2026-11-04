# Vybe: Before and while building (checklist)

Written 3 Nov 2026; updated after the team decided to **build all the frontend properly on sample data** (no cut list) and to work
from a **pool of tasks** with no fixed roles. Everything that does not block building is in `docs/LATER.md`. Sources at the end.

---

## 1. Decisions already made (3 Nov)
Scope: **all** frontend screens, properly, on sample data (no cut list); backend later · Roles: none, tasks come from the pool
(`docs/TASKS.md`) · Figma: a loose reference only; the spec is `docs/IA.md` and `docs/PRODUCT.md` · Picks: made from the team's
**real past visits** · Account deletion: **all of the person's photos are deleted**; posts stay as "[deleted]" · Minimum iOS: 26 ·
Claude Code settings file: not wanted, nothing added.

## 2. Setup checklist (before your first task)
**Everyone**
- [ ] Xcode 27.1 installed; **iOS 26 simulator runtime** installed (Xcode › Settings › Components): iOS 26 is our floor and only iOS 27
  comes preinstalled.
- [ ] `brew install swiftlint`; `git pull`; run `./scripts/check.sh` once (it builds the app and the package).
- [ ] Read `docs/START-HERE.md` section 1.

**Lohitaksh (project settings and shared files)**
- [x] PR 1 merged and **F-0** done (4 Nov; results in ADRs 001 to 004).
- [ ] **X-9** (permission texts, Background Modes, simulated walk, privacy manifest, signing file). [ ] Start Apple Developer enrollment
  now (section 6).

**Anyone**
- [ ] **X-6**: run the issue creator so every task is a GitHub issue to claim.

## 3. Risk spikes (1 hour each; stop at the limit and use the fallback)

| # | Spike | Stop rule / fallback |
|---|---|---|
| 0 | **Architecture proofs** (F-0 step 3, a to g): isolation, Swift 6 mode, `Screens` factory, strings in a package, tab shell, path binding. Results and fallbacks: F-0 and `docs/adr/` 001 to 004 (done 4 Nov; canvas preview, search typing and the back swipe are still to be checked at SC-HD1 / F-9). | each item 60 min → record the fallback in the ADR |
| 1 | **Previews inside the package.** Broken in Xcode 26.4 and still reported broken on 26.6 (checked); 27.1 untested. Try: target name equals library name, build the package scheme once, accept trust prompts. | 60 min → same-named **folders in the app target** instead of package targets |
| 2 | **Tab shell** with `Tab(role: .search)` last (F-9); keep `.searchable` inside `SearchView`, not on the TabView root (forum reports of glitches). | 60 min → ship Search without the morph |
| 3 | **Map with pins and selection** (SC-D1). | 60 min → a list view for Discover |
| 4 | **On the lab iPhone (Lohitaksh):** background location with a free account (the `UIBackgroundModes` plist key needs no entitlement; the Xcode toggle on a free account is unverified); Apple Place ID on a real device (one report says `identifier` was nil on iOS 18.1.1). | record in `OPEN-QUESTIONS.md` |
| 5 | **WhatsApp preview page** (no Mac needed): a static page with Open Graph tags, shared to a WhatsApp chat. | — |
| 6 | **Backend 1-day test** (BK-1), 16 to 17 Nov. | — |

## 4. Work-size reality check (numbers, not opinions)
The pool is about **116 tasks**. Using the sizes in `docs/TASKS.md` (S = ½ day, M = 1, L = 1¾; my estimates, **not measured**):
- frontend + tooling + content ≈ **98 person-days**; backend ≈ **24 more**;
- available Mac time: 4 people × (3 working days this week + 25 working days from 16 Nov) ≈ **112 person-days**; there are no Macs
  7 to 15 Nov.

So the frontend alone uses about 88% of all available Mac time, and the backend, TestFlight and fixes don't fit unless AI-assisted
tasks go faster than these estimates. Two ways to stay honest without cutting the plan: (1) **measure**: after the first 10 merged
tasks, divide days elapsed by tasks done and re-estimate the rest; (2) work the **critical path first** (waves in `docs/TASKS.md`),
so whatever is unfinished at any date is the least important thing. Re-plan with mentors on Fri 6 Nov with real numbers. (Shape Up:
fix the time, vary the scope; unfinished work is cancelled by default.)

## 5. How we work
`docs/START-HERE.md` section 2 and `docs/PROCESS.md`. Short version: pick a task whose dependencies are merged → plan with AI → branch
→ build → `./scripts/check.sh` → PR (about 300 lines, screenshot, "In my own words") → Lohitaksh reviews → merge in the 13:00 or 19:00
window → next task. Only Lohitaksh edits `VybeKit/Package.swift`, `Vybe.xcodeproj` and signing.

## 6. Lead times: start today

| Item | Why now | Action |
|---|---|---|
| **Apple Developer enrollment** (individual) | Apple gives no processing time; Indian applicants report ID-verification rejections and payment failures lasting weeks (forum threads; anecdotal). TestFlight, push, Sign in with Apple, Xcode Cloud and universal links wait on it. | Lohitaksh enrolls **now** with his exact legal name. An organisation account needs a registered company and a D-U-N-S number: not realistic by 18 Dec. |
| **Domain** | web share pages, support email, privacy policy URL | buy one after the name is chosen, or a neutral one now |
| **Firebase and Supabase accounts** | the 16 to 17 Nov test; Firebase Storage needs a paid Blaze plan and a card | create both; add the card before 16 Nov |
| **GitHub Education / Team** | days to verify; needed for branch protection on a private repo | ask a faculty member |
| **Lawyer contact** | privacy policy, Terms, IT Rules (`docs/RISKS.md` 7) | ask mentors |
| **Name** | bundle ID, domain and App Store record depend on it | run `docs/prompts/NAME-RESEARCH.md` |

## 7. What I could not verify
The Figma file's contents (not opened; a loose reference) · whether previews work in packages on Xcode 27.1 · whether the free Apple
account allows the Background Modes capability toggle · Apple's enrollment processing time in India · the real iPhone share at the
target college · the task sizes (estimates).

## Sources
Evidence links: `docs/SOURCES.md` (section "Before and while building").
