# backend/ (Phase 2 — not started)

Server side of Vybe, kept outside the iPhone app. Nothing here is built yet; the frontend
runs on sample data (`VybeKit/Sources/LocalData`). Planned contents (see
`docs/ARCHITECTURE.md` sections 3.2, 4b and 8):

- `firebase.json`, `firestore.rules`, `storage.rules`, `firestore.indexes.json` (or the Supabase equivalent)
- `functions/` — TypeScript server code (feeds, counters, account deletion, push)
- `web/` — WEB1 public share pages for Android friends (WhatsApp preview + "I'm in")
- `rules-tests/` — unit tests for the security rules, run in CI

The backend choice (Firebase or Supabase) is decided on 16-17 Nov (`docs/OPEN-QUESTIONS.md`).
