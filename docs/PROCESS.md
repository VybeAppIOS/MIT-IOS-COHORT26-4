# Vybe: How We Work (PROPOSAL, for mentor review)

Status: **proposal.** Written 3 Nov 2026. Compares how professional teams build and ship
apps in 2025-2026 with what Vybe does, and adds only what fits 4 students and ~6 weeks.
Sources at the end.

---

## 1. Problem and success (draft, team to confirm)

**Problem (draft):** college friend groups in Pune want to go out on a low budget, but
planning where to go, in what order, and agreeing on it takes too long, so plans die in
the group chat.

**Success metrics** (measured from Phase 2 TestFlight; with ~50 testers, watch trends and
talk to people rather than chase industry numbers):
| Metric | Definition |
|---|---|
| Activation | finished onboarding **and** saved or started a Hangout on day 1 |
| Core loop | Hangouts started → completed (2+ Spots visited) → posted |
| Social | friends added in the first week |
| Retention | came back on day 1 and day 7 |

## 2. The professional process, and where we fit

| Stage | What professionals produce | What Vybe has | What we add (sized for us) | When |
|---|---|---|---|---|
| Discovery | problem statement, tests with ~5 real users, metrics | audience, tone | problem statement and metrics (section 1); **5 quick tests of the Figma prototype with Kothrud students** (20 min each, notes in `docs/research/`) | statement now; tests over vacation |
| Scope | spec per feature, priorities, out-of-scope list | PRODUCT.md, out-of-scope list, the task pool (`docs/TASKS.md`) | task sizes re-estimated from measured speed | Phase 2 |
| Design | tokens, components, prototype, usability and accessibility notes | Figma prototype, Theme rule | freeze Theme tokens in F0; free Figma Education plan for Dev Mode; screenshot next to the Figma frame in every PR | now |
| Planning | issues with acceptance criteria, a board, Definition of Ready and Done | work packages, stand-up, merge windows, Definition of Done | **one GitHub issue per work package** (template 4.1) on a GitHub Projects board; max 1 item in progress per person; Definition of Ready | now |
| Tech design | design docs, decision records | ARCHITECTURE.md, DATA-MODEL.md, IA.md | short **decision records** (`docs/adr/`), template 4.2. First ones: MVVM, library rule, backend choice | Phase 2 (first at the backend decision) |
| Build | small PRs, review checklist, CI, feature flags, separate environments, secrets out of the repo | small PRs, "In my own words", `check.sh`, lead reviews | PR checklist (template 4.3); Phase 2: rotate peer review, two backend projects (dev and prod), a simple `FeatureFlags` struct to hide unfinished features | checklist now; rest Phase 2 |
| AI-assisted work | spec per task, a check the agent runs itself, evidence, human review, hard rules as tool settings | plan first, ~300 lines, `check.sh`, AGENTS.md | paste the issue's acceptance criteria into the AI prompt; **paste the `check.sh` output and a screenshot** in the PR (not "tests pass"); before opening a PR, ask a fresh AI session to review the change against the issue ("skip style") | now |
| Quality | test pyramid, manual checklist, device matrix, accessibility and performance checks | test plan, Q1 bug hunt | Q1 checklist (section 3) | Friday 6 Nov |
| Beta | TestFlight groups, feedback, triage | TestFlight planned | team and mentors first, then ~20 friends; a weekly Friday build; triage feedback every Monday | Phase 2 |
| Crashes and analytics | crash dashboards, privacy-friendly analytics | privacy manifest planned | Xcode Organizer crash reports (free, no library); a few events through the backend; declared in privacy labels | Phase 2 |
| Release | release checklist, App Review notes, demo account, store listing | guideline research | template 4.4; a demo account with friends, posts and chat so reviewers can test block and report | week of 7 Dec |
| Operations | alerts, support inbox, moderation rota, incident notes | moderation questions | budget alerts, one support email, weekly report-queue rota, a one-page "if it's down" note | Phase 2 |

Deliberately skipped for now: paid Figma Code Connect, RICE scoring, GitHub Spec Kit,
remote config, a staging environment, third-party analytics.

## 3. Q1 manual QA checklist (Friday 6 Nov)
- [ ] Every flow in `docs/PRODUCT.md` section 3 works start to finish.
- [ ] Every screen's loading, empty and error states look right.
- [ ] Location permission denied: area picker works.
- [ ] Small screen (iPhone SE or mini simulator) and a large one.
- [ ] iOS 26 simulator (our minimum) **and** the newest simulator (iOS 27).
- [ ] Largest text size (Settings › Accessibility › Larger Text).
- [ ] VoiceOver: every button and pin is read out sensibly.
- [ ] Live Hangout on the lab iPhone: lock the phone mid-walk and check it recovers.
- [ ] No banned words in the UI (Plan, Trace, Stop, outing...).

## 4. Templates

### 4.1 Issue (`.github/ISSUE_TEMPLATE/story.md`)
```
Title: <ID>: <what it does>          Time budget: ½ day | 1 day
Story: As a Kothrud student, I want <x> so that <y>.
Figma frame: <link>     Depends on: <#issues merged>
Acceptance criteria:
- Given <state>, when <action>, then <result>
- Loading / empty / error: <what each shows>
Out of scope: <...>
Check: ./scripts/check.sh passes + screenshot next to the Figma frame
```
**Definition of Ready** (before anyone starts): screen ID, Figma link, acceptance
criteria, dependencies merged.

### 4.2 Decision record (`docs/adr/001-title.md`)
```
# 001: <decision>      Status: proposed | accepted | replaced by 00X      Date:
Context: what forced this decision (2-5 lines)
Options: A / B / C, one line each
Decision: we chose B because...
Consequences: what gets easier, what gets harder, what we'll watch
```

### 4.3 PR checklist (added to the PR template)
```
- [ ] Linked issue; every acceptance criterion ticked
- [ ] check.sh output pasted (not just "passes")
- [ ] Simulator screenshot next to the Figma frame
- [ ] Tried at the largest text size; VoiceOver labels on icon-only buttons
- [ ] Fresh-session AI review against the issue done; findings fixed or explained
- [ ] No new library, no secrets, no files outside my folder
- [ ] "In my own words" (3 to 5 sentences) and which AI I used
```

### 4.4 TestFlight release checklist
```
- [ ] Build number bumped; main is green; Q1 checklist run on the lab iPhone
- [ ] "What to Test" notes written; tester group chosen
- [ ] Privacy manifest and App Privacy labels match what we collect
- [ ] Demo account (email + password) with seeded friends, posts, chat
- [ ] Block, report and account deletion tested end to end
- [ ] Privacy policy and Terms links live; support email works
- [ ] Release captain checks crashes and feedback after 24 hours
```

### 4.5 Bug report (`.github/ISSUE_TEMPLATE/bug.md`)
```
Screen ID:      Device/simulator + iOS:      Build:
Steps: 1. 2. 3.
Expected:       Actual:
Screenshot/video:      Severity: crash | blocks a flow | wrong | cosmetic
```

### 4.6 Look at your own screen: debug launch options and `scripts/snap.sh` (task X-14)
Every screen PR needs screenshots, and an agent can look at its own result before asking for review. The app (DEBUG builds
only, never Release) understands these launch options: `-stubMode loaded|empty|failing|loading` (the whole app on the sample
stubs in that state), `-debugRoute <short form or JSON Route>` (open one screen), `-skipOnboarding`, `-resetState` and
`-simulateWalk`. One command does it all:

```
scripts/snap.sh hd1 hangout/hangout-example-evening-c3d4 all    # four screenshots: loaded, empty, failing, loading
scripts/snap.sh settings settings/privacy loaded                 # one screenshot
```
Pictures go to `build/screenshots/` (git-ignored). The short forms (`hangout/<id>`, `saved`, `sheet/spot/<id>`,
`cover/live/<id>` ...) are listed in `Vybe/App/LaunchOptions.swift`. No personal data is used: the stubs only hold
EXAMPLE and "Sample" data.

## 5. Rhythm
- **This week:** stand-up 9:30, merge windows 13:00 and 19:00 (unchanged).
- **Phase 2:** kanban (not sprints); a 30-minute Friday demo to a mentor, then a
  15-minute "keep / stop / try" retro; a rotating release captain.

## 6. What the research says about AI-assisted teams (why these rules exist)
- DORA 2025 (about 5,000 people): 90% use AI; AI speeds up delivery but still hurts
  stability, and "amplifies" a team's existing habits, good or bad.
- Anthropic's Claude Code guidance: give the agent a check it can run, ask for evidence,
  review in a fresh session, and put hard rules in tool settings rather than prose.
- Thoughtworks lists "complacency with AI-generated code" as an antipattern.
- One study found ~45% of AI-generated code samples had security flaws (vendor study),
  which is why backend security rules get a human review.

## 7. Process questions for mentors
1. Cheapest real-user test over vacation with only a Figma prototype?
2. Which 3 to 5 metrics did you watch in your first TestFlight? Is "Hangout completed" the right core action?
3. Kanban or 1-week sprints for 4 beginners over 4.5 weeks? What demo or retro rhythm stuck?
4. How to split code review when one person knows the codebase best?
5. What do you insist on before merging AI-written code?
6. Separate dev and prod backends from day one, or only before TestFlight?
7. Feature flags in a first version, or just don't ship unfinished screens?
8. What caused your App Review rejections?
9. Is Xcode Organizer enough for crashes at first?
10. Who handled support and moderation after launch, and how many hours a week?

## Sources
[YC: how to build an MVP](https://ycombinator.com/library/Io-how-to-build-an-mvp) ·
[NN/g: test with 5 users](https://nngroup.com/articles/why-you-only-need-to-test-with-5-users/) ·
[Figma Education plan](https://help.figma.com/hc/en-us/articles/360041061214) ·
[Figma Code Connect](https://developers.figma.com/docs/code-connect) ·
[Linear for small teams](https://linear.app/docs/how-to-use-linear-small-teams) ·
[Shape Up](https://basecamp.com/shapeup/0.3-chapter-01) ·
[Given/When/Then](https://martinfowler.com/bliki/GivenWhenThen.html) ·
[Decision records (arc42)](https://docs.arc42.org/tips/9-5/) ·
[Google code review standard](https://google.github.io/eng-practices/review/reviewer/standard.html) ·
[Feature toggles](https://martinfowler.com/articles/feature-toggles.html) ·
[Firebase environments](https://firebase.google.com/docs/projects/dev-workflows/overview-environments) ·
[OWASP MASWE-0005](https://mas.owasp.org/MASWE/MASVS-AUTH/MASWE-0005/) ·
[DORA 2025](https://cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report) ·
[Claude Code best practices](https://code.claude.com/docs/en/best-practices) ·
[Thoughtworks Radar](https://www.thoughtworks.com/about-us/news/2025/thoughtworks-technology-radar-highlights-genai-s-impact-and-key-) ·
[Veracode AI code study](https://www.veracode.com/press-release/ai-generated-code-poses-major-security-risks-in-nearly-half-of-all-development-tasks-veracode-research-reveals/) ·
[WWDC23 accessibility audits](https://developer.apple.com/videos/play/wwdc2023/10035/) ·
[App Store phased release](https://developer-mdn.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases) ·
[Xcode crash reports](https://developer.apple.com/documentation/xcode/acquiring-crash-reports-and-diagnostic-logs) ·
[TestFlight feedback](https://www.developer.apple.com/help/app-store-connect/test-a-beta-version/view-tester-feedback) ·
[Google SRE postmortems](https://sre.google/sre-book/postmortem-culture/) ·
[Shopify mobile releases](https://shopify.engineering/mobile-release-engineering-scale-shipit-mobile)
