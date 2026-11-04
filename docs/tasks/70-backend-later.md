# Backend and web tasks (NOT started: after the frontend is on sample data, from 16 Nov)

These plug into the repository protocols from F-5/F-7 through a new `VybeRemote` package (ADR 007), so **no screen
changes**. Details come after the backend decision (Firebase or Supabase, `docs/ARCHITECTURE.md` section 8
and `docs/OPEN-QUESTIONS.md` section 6). They are listed so nothing is forgotten; do not start them yet, **except BK-1**,
which should happen before the social repository protocols (F-7) are merged (`docs/PLAN.md` 7, rule 5).

| ID | Task | Notes |
|---|---|---|
| BK-1 | One-day backend test (login + one table + one listener + People prefix search with blocks + WhatsApp preview page) | decides Firebase vs Supabase |
| BK-2 | `VybeRemote` package + SDK exception decision | a **separate local package** (`docs/adr/007-remote-package.md`) that depends on VybeKit; the only place that may import the backend SDK; runs the same repository contract checks as LocalData |
| BK-3 | Auth: Apple, Google, email code; username uniqueness; 30-day username hold | replaces the `AuthRepository` stub |
| BK-4 | Data rules: deny-by-default database and storage rules + rule tests in CI | privacy per `docs/DATA-MODEL.md` 3; blocking everywhere |
| BK-5 | Hangouts, Places, Saves, runs, feed (friends-first fan-out) | `HangoutRepository`, `FeedRepository` |
| BK-6 | Friends, requests (caps, "Other" folder), blocks | `FriendsRepository`, `SafetyRepository` |
| BK-7 | Chat: conversations, messages, read receipts, polls, voice/photo upload, group invitations | `ChatRepository` |
| BK-8 | Server functions: counters, Remix credit, account deletion cascade, `audience` rewrite, scheduled posts | TypeScript or SQL; local emulator first |
| BK-9 | Push notifications (needs the paid Apple account) | ask permission at the first friend request or chat |
| BK-10 | WEB1 share pages with WhatsApp preview and "I'm in" without an account | `backend/web/` |
| BK-11 | Admin tooling server side + report auto-hide + on-call alerts | the 2-hour and 3-hour rules in `docs/RISKS.md` |
| BK-12 | Offline cache strategy (SDK cache or our own JSON) | `LoadState.loaded(isStale:)` |
| BK-13 | Privacy policy, Terms, grievance contact, lawyer review | `docs/RISKS.md` section 7 |
| BK-14 | TestFlight pipeline (Xcode Cloud or Actions), demo account for App Review | `docs/PROCESS.md` 4.4 |
