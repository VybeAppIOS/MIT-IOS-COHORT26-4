# Screen tasks: Editor, Posting, Report/Block and Admin

Same rules as `docs/tasks/20-screens-start-discover-detail.md`. Common dependencies: **F-4, F-5, F-9,
DS-1/2/3**. Read `docs/RISKS.md` section 3 before the posting and safety tasks.

## Editor (folder `EditorFeature/`; shown in `Cover.editor`, stack `StackID.editor`)

### SC-E1 — Hangout editor  `[L]`
- **Depends on:** common, F-6, CP-2, CP-10, SC-E2
- **Read:** IA 4 (E1), 6 (flow 4) · PRODUCT 4 (Hangouts, Remix) · DATA-MODEL 7 (decisions 4, 5, 12)
- **Build:** `Editor/`: opened by `Cover.editor(.new / .draft(id) / .remix(id))` with its own
  `NavigationStack`. Fields: title (3–60), summary (≤200), the **Spot list** (reorder with drag, swipe to
  delete, per-Spot minutes and note, **Add Spot** → SC-E2), budget range (lower/upper), estimated minutes
  (auto-sum, override allowed), tags and best-time chips. Live validation with `HangoutRules`: 2…10 Spots; if the
  same Place appears twice show the warning **"You've added this place twice"** (allowed). A Remix shows a
  banner "Remixed from @x" with how many of the original Spots are kept (the 70% credit rule). **Autosave**
  as a Draft; **Done** → saves and `router.show(.drafts, in: .profile)`; close with a discard confirmation.
- **Done when:** tests: validation messages, duplicate warning, reorder, remix kept-count, autosave restores.

### SC-E2 — Add Spot  `[M]`
- **Depends on:** common, CP-3
- **Read:** IA 4 (E2) · OPEN-QUESTIONS (pickers vs the Search-only rule)
- **Build:** `AddSpot/`: a sheet listing Places with `FilterChip`s by category (no free-text search box until
  the mentors answer the picker question); tapping adds the Spot; "Can't find it?" **pushes** SC-E3 inside
  the sheet.
- **Done when:** previews; adding a Place appends a Spot with a stable `SpotID`.

### SC-E3 — Suggest a Place  `[M]`
- **Depends on:** common, F-13, F-7
- **Read:** IA 4 (E3) · RISKS 3 (no residential addresses) · PRODUCT 4 (Places)
- **Build:** `SuggestPlace/`: opened as a push inside E2 **or** as `Sheet.suggestPlace` from an empty
  Search. Name, a map with a centre pin to place it, category, note, a **required photo** taken there
  (`PhotoProcessor`). A clear line: "We'll check it before it appears. We don't accept homes or hostels."
  Submit → `PlaceSuggestion` (pending); success state.
- **Done when:** validation tests (photo required, name length); success and failure states.

## Posting (folder `PostingFeature/`)

### SC-PO1 — Post composer  `[L]`
- **Depends on:** common, F-6, CP-6
- **Read:** IA 4 (PO1), 6 (flow 3) · PRODUCT 4 (Doing and posting, Safety defaults) · RISKS 3
- **Build:** `Composer/`: opened by `Route.composePost(runID)`. Cover picker from the run's photos, title
  (prefilled), caption (≤280), photos (≤ `2 × visited`, reorder/remove), tags, **audience** (Friends by default;
  choosing Public shows a one-line warning and asks to confirm), **when**: "in 30 minutes" (default), "in 2
  hours", "tomorrow morning", and a live **PostCard preview**. The button is disabled with the reason below
  2 visited Spots. Posting schedules the run (`scheduled`) and the cover closes on Profile › Ready to post
  with "Scheduled for 8:30 pm". Exact visit times are never part of the post.
- **Done when:** tests for the disabled reason, the default audience and delay, the photo limit, and the
  scheduled time.

### SC-PO2 — Edit post  `[M]`
- **Depends on:** common, CP-6
- **Build:** `EditPost/`: `Sheet.editPost(runID)`: title, caption, photos, tags, audience; the Spots are
  shown read-only ("Spots can't be changed after posting"); **Delete post** (confirmation; its comments go with it).
- **Done when:** tests: Spots immutable; delete confirms and removes the post from the feed stub.

## Report, block and admin (folder `ModerationFeature/`)

### SC-R1 — Report  `[M]`
- **Depends on:** common, F-3, F-7
- **Read:** IA 4 (R1) · RISKS 3, 4 (report reasons, self-harm flow) · ARCHITECTURE 2.6 (Report as a push inside a sheet)
- **Build:** `Report/`: `Sheet.report(target)` (or `Route.report` when already inside a sheet). Reason list:
  spam, harassment or bullying, hate, nudity or sexual content, violence or threats, self-harm, drugs or
  illegal goods, scam or fraud, impersonation, copyright, **photo of me without consent**, **private
  address**, fake or unsafe Spot, possibly under 18, something else (text ≤300). **Anonymous** (the reported
  person never sees who reported). Self-harm shows **Tele-MANAS 14416** and **112**. Success: "Thanks. We'll
  look at it." and **"Also block @x?"** → SC-R2. For nudity, self-harm and threats the content is hidden for
  you straight away.
- **Done when:** tests: each reason maps to the right `ReportReason`; the self-harm card shows both numbers;
  the sheet works as a presented sheet and as a push.

### SC-R2 — Block confirm  `[S]`
- **Depends on:** common, SC-R1
- **Build:** `BlockConfirm/`: `confirmationDialog` explaining "They won't be able to see your posts or message
  you, and you won't see theirs. They won't be told." Block / Cancel → `SafetyRepository.block` and
  `session.blockedIDs` so every screen hides them at once. Also an **Unblock** path (used by ST3).
- **Done when:** tests: after blocking, a feed from the stub no longer contains that person.

### SC-AD1 — Admin: reports queue  `[M]`
- **Depends on:** common, F-7
- **Read:** IA 4 (Admin) · RISKS 4 (response times: 2 h for nudity/morphed images/child safety, 3 h for
  orders, 36 h unlawful content, 7 days general)
- **Build:** `Admin/Reports/`: visible only if `session.isTeamAccount`. List sorted by severity then age with a
  **time-left** label per category; detail with the content, reporter-anonymous info for the team, actions: hide,
  restore, warn, ban (→ AD3), dismiss. Priority reports show at the top.
- **Done when:** tests for severity ordering and time-left calculation; hidden for non-team accounts.

### SC-AD2 — Admin: Place suggestions  `[S]`
- **Depends on:** SC-AD1
- **Build:** `Admin/Suggestions/`: pending list; approve into a `Place` (editable) or reject with a note;
  "residential address" is a one-tap reject reason.
- **Done when:** states; tests for approve/reject.

### SC-AD3 — Admin: users  `[S]`
- **Depends on:** SC-AD1
- **Build:** `Admin/Users/`: look up by username (this admin tool is allowed to search people), see reports
  against them, **ban / unban** with a note. 
- **Done when:** states; tests.
