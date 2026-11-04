# Vybe: How We Work

Status: proposal for mentor review (3 Nov 2026). Compares how professional teams build and ship apps in 2025-2026 with what Vybe
does, and adds only what fits 4 students and about 6 weeks. Sources at the end.

---

## 1. Problem and success
**Problem (draft, team to confirm):** see `docs/PRODUCT.md` section 0. **Success metrics** (from the Phase 2 TestFlight; with about 50
testers watch trends and talk to people rather than chase industry numbers):

| Metric | Definition |
|---|---|
| Activation | finished onboarding **and** saved or started a Hangout on day 1 |
| Core loop | Hangouts started → completed (2+ Spots visited) → posted |
| Social | friends added in the first week |
| Retention | came back on day 1 and day 7 |

## 2. The professional process, and where we fit

| Stage | What professionals produce | What Vybe has | What we add (sized for us) | When |
|---|---|---|---|---|
| Discovery | problem statement, tests with about 5 real users, metrics | audience, tone | problem statement and metrics (section 1); **5 quick tests of the Figma prototype with Kothrud students** (20 min each, notes in `docs/research/`) | statement now; tests over vacation |
| Scope | spec per feature, priorities, out-of-scope list | PRODUCT.md, out-of-scope list, the task pool (`docs/TASKS.md`) | task sizes re-estimated from measured speed | Phase 2 |
| Design | tokens, components, prototype, usability and accessibility notes | Figma prototype, Theme rule | freeze Theme tokens in F-0; free Figma Education plan for Dev Mode; screenshot next to the Figma frame in every PR | now |
| Planning | issues with acceptance criteria, a board, Definition of Ready and Done | work packages, stand-up, merge windows, Definition of Done | **one GitHub issue per task** (template 4.1) on a GitHub Projects board; max 1 item in progress per person; Definition of Ready | now |
| Tech design | design docs, decision records | ARCHITECTURE.md, DATA-MODEL.md, IA.md | short **decision records** (`docs/adr/`, template 4.2): first MVVM, library rule, backend choice | Phase 2 (first at the backend decision) |
| Build | small PRs, review checklist, CI, feature flags, separate environments, secrets out of the repo | small PRs, "In my own words", `check.sh`, lead reviews | PR checklist (template 4.3); Phase 2: rotate peer review, two backend projects (dev and prod), a simple `FeatureFlags` struct to hide unfinished features | checklist now; rest Phase 2 |
| AI-assisted work | spec per task, a check the agent runs itself, evidence, human review, hard rules as tool settings | plan first, about 300 lines, `check.sh`, AGENTS.md | paste the issue's acceptance criteria into the AI prompt; **paste the `check.sh` output and a screenshot** in the PR (not "tests pass"); before opening a PR, ask a fresh AI session to review the change against the issue ("skip style") | now |
| Quality | test pyramid, manual checklist, device matrix, accessibility and performance checks | test plan, Q1 bug hunt | Q1 checklist (section 3) | Fri 6 Nov |
| Beta | TestFlight groups, feedback, triage | TestFlight planned | team and mentors first, then about 20 friends; a weekly Friday build; triage feedback every Monday | Phase 2 |
| Crashes and analytics | crash dashboards, privacy-friendly analytics | privacy manifest planned | Xcode Organizer crash reports (free, no library); a few events through the backend; declared in privacy labels | Phase 2 |
| Release | release checklist, App Review notes, demo account, store listing | guideline research | template 4.4; a demo account with friends, posts and chat so reviewers can test block and report | week of 7 Dec |
| Operations | alerts, support inbox, moderation rota, incident notes | moderation questions | budget alerts, one support email, weekly report-queue rota, a one-page "if it's down" note | Phase 2 |

Deliberately skipped for now: paid Figma Code Connect, RICE scoring, GitHub Spec Kit, remote config, a staging environment,
third-party analytics.

## 3. Q1 manual QA checklist (Friday 6 Nov)
- [ ] Every flow in `docs/PRODUCT.md` section 3 works start to finish. [ ] Every screen's loading, empty and error states look right.
- [ ] Location permission denied: the area picker works. [ ] Small screen (iPhone SE or mini simulator) and a large one.
- [ ] iOS 26 simulator (our minimum) **and** the newest (iOS 27). [ ] Largest text size (Settings › Accessibility › Larger Text).
- [ ] VoiceOver: every button and pin is read out sensibly. [ ] Live Hangout on the lab iPhone: lock the phone mid-walk and check it
  recovers. [ ] No banned words in the UI (Plan, Trace, Stop, outing...).

## 4. Templates
- **4.1 Issue:** `.github/ISSUE_TEMPLATE/story.md` (time budget, story, Figma frame, depends on, acceptance criteria given/when/then
  plus loading/empty/error, out of scope, check). **Definition of Ready** (before anyone starts): screen ID, Figma link, acceptance
  criteria, dependencies merged.
- **4.2 Decision record** (`docs/adr/00N-title.md`): `# 00N: <decision>`, Status (proposed | accepted | replaced by 00X), Date, then
  Context (2 to 5 lines), Options (A / B / C, one line each), Decision (we chose B because…), Consequences (what gets easier, what
  gets harder, what we'll watch).
- **4.3 PR checklist:** `.github/pull_request_template.md` (linked issue with every acceptance criterion ticked; `check.sh` output
  pasted; simulator screenshot next to the Figma frame; largest text size and VoiceOver labels tried; fresh-session AI review against
  the issue done; no new library, secrets or files outside my folder; "In my own words" and which AI).
- **4.4 TestFlight release checklist:**
  ```
  - [ ] Build number bumped; main is green; Q1 checklist run on the lab iPhone
  - [ ] "What to Test" notes written; tester group chosen
  - [ ] Privacy manifest and App Privacy labels match what we collect
  - [ ] Demo account (email + password) with seeded friends, posts, chat
  - [ ] Block, report and account deletion tested end to end
  - [ ] Privacy policy and Terms links live; support email works
  - [ ] Release captain checks crashes and feedback after 24 hours
  ```
- **4.5 Bug report:** `.github/ISSUE_TEMPLATE/bug.md` (screen ID, device + iOS, build, steps, expected, actual, screenshot, severity
  crash | blocks a flow | wrong | cosmetic).

## 5. Rhythm
- **This week:** stand-up 9:30, merge windows 13:00 and 19:00 (unchanged).
- **Phase 2:** kanban (not sprints); a 30-minute Friday demo to a mentor, then a 15-minute "keep / stop / try" retro; a rotating release
  captain.

## 6. What the research says about AI-assisted teams (why these rules exist)
- DORA 2025 (about 5,000 people): 90% use AI; it speeds up delivery but still hurts stability, and "amplifies" a team's existing habits.
- Anthropic's Claude Code guidance: give the agent a check it can run, ask for evidence, review in a fresh session, put hard rules in
  tool settings rather than prose. Thoughtworks lists "complacency with AI-generated code" as an antipattern.
- One vendor study found about 45% of AI-generated code samples had security flaws, which is why backend security rules get a human review.

## 7. Process questions for mentors
Full mentor script: `docs/MENTOR-SESSION.md`. Process-specific: (1) the cheapest real-user test over vacation with only a Figma
prototype? (2) which 3 to 5 metrics did you watch in your first TestFlight; is "Hangout completed" the right core action? (3) kanban
or 1-week sprints for 4 beginners over 4.5 weeks, and what demo or retro rhythm stuck? (4) how to split code review when one person
knows the codebase best? (5) what do you insist on before merging AI-written code? (6) separate dev and prod backends from day one, or
only before TestFlight? (7) feature flags in a first version, or just don't ship unfinished screens? (8) what caused your App Review
rejections? (9) is Xcode Organizer enough for crashes at first? (10) who handled support and moderation after launch, and how many
hours a week?

## Sources
Evidence links: `docs/SOURCES.md` (section "How we work").
