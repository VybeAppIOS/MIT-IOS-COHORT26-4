# Prompt: backend decision (Firebase vs Supabase)

Give this to a cloud or research agent. Research and write only: no code, no changes to existing files.

> Read `AGENTS.md`, `docs/PRODUCT.md`, `docs/DATA-MODEL.md`, `docs/ARCHITECTURE.md`, `docs/RISKS.md`,
> `docs/OPEN-QUESTIONS.md` and `docs/tasks/70-backend-later.md`.
> We must choose a backend for an iOS (SwiftUI, iOS 26) social app built by four first-time students in
> India: login (Apple, Google, email code), friends and blocks, a friends-first feed, chat with photos and
> voice notes, push notifications, reports and account deletion, and a public web share page. Budget is
> near zero. Current lean: Firebase. Alternative: Supabase.
>
> Write `docs/BACKEND-DECISION.md` with:
> 1. A comparison table for our needs: auth, data model fit (see DATA-MODEL), private/blocked data rules,
>    feed, chat and realtime, file storage and cost, push, offline cache, Swift SDK quality, free-tier limits
>    and pricing at 1,000 / 10,000 users, access from India, learning curve for beginners, lock-in and exit.
> 2. A recommendation with the three strongest reasons against it.
> 3. The data rules (who can read and write what) for blocks, private posts and chat, as the chosen product
>    would express them, so we can judge whether beginners can get them right.
> 4. A one-day test plan to confirm the choice, and a list of what is unverified.
> Cite a source URL for every pricing or limit claim and mark anything you could not verify. Do not invent
> product features. Keep the vocabulary: Hangout, Spot, Remix, Picks.
