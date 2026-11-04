# Vybe (working name)

An iPhone app for college students in Pune: find real places, plan a multi-stop **Hangout**
with friends, do it live on a map, and post it. Built in SwiftUI by four students.

**New here? Read [`docs/START-HERE.md`](docs/START-HERE.md).** Then pick a task from
[`docs/TASKS.md`](docs/TASKS.md).

| Where | What |
|---|---|
| `docs/DAY-ONE.md` | what to start today, who does what, the prompt for your AI tool |
| `docs/START-HERE.md` | reading list, how we work, repository map |
| `docs/TASKS.md`, `docs/tasks/` | the pool of tasks (what to build, what to read, when it is done) |
| `docs/PRODUCT.md`, `docs/IA.md` | what the app is, every screen |
| `docs/adr/` | the short decision records that win over older documents (read 001 to 003 first) |
| `docs/ARCHITECTURE.md`, `docs/DATA-MODEL.md`, `docs/MOTION.md` | how it is built |
| `docs/SOURCES.md` | the evidence links behind the decisions (kept out of the other documents) |
| `AGENTS.md` | rules every person and AI tool follows |
| `Vybe/` | the app target (wiring only) |
| `VybeKit/` | the local Swift package: almost all the code |

Run all checks: `./scripts/check.sh`
CI: Lint runs on every pull request; Test (macOS) runs once a pull request is ready for review.
