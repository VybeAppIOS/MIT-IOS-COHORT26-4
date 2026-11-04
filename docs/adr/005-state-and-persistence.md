# 005: Refresh never erases content, cancellation is not an error, one serial disk writer
Status: accepted as the working default (4 Nov 2026). Date: 4 Nov 2026

## Context
The ViewModel sketch in `ARCHITECTURE.md` 2.4 is right for the first load but has three gaps that every screen would
copy: (1) a failed refresh sets `.failed` and throws away content already on screen; (2) `catch { state = .failed }`
also catches the cancellation that SwiftUI triggers when a screen disappears or a `.task(id:)` restarts, flashing an
error; (3) persistence has no rule for write order, corrupt files or app suspension, yet the live Hangout must survive
the app being killed.

## Decision
1. `LoadState` describes a screen's **first** load. Once content exists, a failed refresh keeps it and sets
   `isStale` (and shows the offline/stale banner); only a first load can end in `.failed`.
2. ViewModels have **`load()`** (idempotent, called by `.task`) and **`reload()`** (pull to refresh, Retry).
3. `catch is CancellationError { return }` in every `load`/`reload`. Cancellation never changes `state`.
4. "Empty" is decided by the ViewModel (empty content becomes `.empty`); "not found" is `AppError.notFound` with its
   own message ("This Hangout is no longer available"), not a generic error.
5. Optimistic actions (like, save) update local state first, call the repository, then roll back and show a short
   error on failure. State that two tabs show (Saved, blocked IDs, my own likes) lives in a store, so every card agrees.
6. **Disk writes go through one serial writer** (an `actor` in LocalData per file, e.g. `LibraryFile`). It coalesces
   to the latest snapshot, writes atomically, and flushes when the app goes to the background
   (`scenePhase == .background`). `LiveHangoutStore` updates memory immediately and persists write-behind; a write
   failure is logged and exposed as `persistenceError` on the store.
7. **A file that cannot be read is never deleted silently:** rename it to `<name>.corrupt-<timestamp>`, log it
   (no personal data), start empty, and surface a one-time notice.
8. Photo files are written before the JSON that points to them; on launch, files no run points to are removed.

## Consequences
Easier: the same pattern on 60 screens; fewer "error flash" and "lost my draft" bugs. Harder: a little more code in each
`load`. The template (`docs/templates/new-screen/README.md`) already contains the pattern; F-8 and F-10 contain the
persistence tests (ten rapid `markVisited` calls end in one consistent file; a corrupt file is quarantined).
Undo: per screen.
