# Mentor session kit

A script for the mentor meeting: bring him up to speed, ask whether our approach is normal, then go
deeper (database, backend, safety, legal). Every question is general ("how do most teams do this?")
and says what we plan, so he can answer "that's normal" or "no, do this instead".

## 0. Before you meet
**Be honest about where we are:** no screens are built yet. What exists is the plan, the architecture,
a folder skeleton and 116 tasks ready to take.

**Show him, in this order (about 5 minutes):**
1. The mentor page (private until shared from its Share menu).
2. The screen map: `docs/IA.md` section 5.
3. The folder map: `docs/ARCHITECTURE.md` section 3.2.
4. The task list: `docs/TASKS.md`.

Ask permission to record or take notes, and decide who writes the answers down.

## 1. The 60-second recap (say this out loud)
> "Vybe is an iPhone app for college students in Pune. You find real local places, plan a multi-stop
> outing with friends, which we call a Hangout, do it live on a map, and post what you did. There are
> friends, a feed, and chat.
> Since you last saw us we've done a lot of planning. We know exactly what the app is: 61 screens. We
> chose how to build it. We built an empty project skeleton. We broke the work into 116 small tasks that
> any of us can pick up. We're about to start building, and we want your experience on whether our
> approach is normal, before we find out the hard way."

**Already decided (so he knows what we are not asking about):** iPhone only, iOS 26 and newer, light
mode, English · four tabs: Discover, Community, Profile, and Search as a separate trailing tab · words:
Hangout, Spot, Remix, Picks · build all screens on sample data first, then add the backend.

## 2. Session plan (60 minutes)
| Time | Part | Questions |
|---|---|---|
| 5 min | Recap and demo | section 1 |
| 10 min | A. Big picture | A1–A5 |
| 15 min | B. How we build | B1–B9 |
| 10 min | C. Data and backend | C1–C8 |
| 10 min | D. Safety and legal | D1–D8 |
| 5 min | E. Launch | E1–E4 |
| 5 min | F. Wrap-up | F1–F3 |

**★ = ask even if time is short.**

## A. Big picture: is our plan sane?
- **★A1.** "Here's our scope. Looking at teams you've helped, is this too much for four first-timers and
  about six weeks? What usually breaks first?"
- **★A2.** "How do most teams decide what to cut when they're behind? Do you cut features, quality, or
  the date?"
- **A3.** "We build all the screens on sample data first and add the real server later. Did the teams
  you saw do it in that order? What went wrong when they did?"
- **A4.** "How do teams usually test an idea like this with real users before building everything? What's
  the cheapest version we could do this month?"
- **A5.** "What are the three mistakes first-time student teams make most often on a social app?"

## B. How we build (process and structure)
Say the decision in one sentence, then ask.
- **★B1.** "We split the app into 18 small modules that can only import what we allow, so four people
  don't break each other's code. Is that normal for a team this size, or too much structure? Would you
  start simpler and split later?"
- **★B2.** "Every screen has the same two parts: one that draws, and one that holds the logic so we can
  test it. Is that common, or do teams usually keep it looser?"
- **B3.** "Our screens can't open each other directly; they ask a central 'router'. Did the teams you
  helped hit problems with navigation as the app grew? How did they handle it?"
- **★B4.** "We have 116 tasks and no fixed roles: anyone picks the next one, finishes it, pushes, and
  takes another. Did that work for beginners? Would you assign owners per area instead?"
- **B5.** "We use AI tools for most of the code. How do the teams you know keep AI-written code consistent
  between four people? What review habits actually worked?"
- **B6.** "One person reviews every pull request. Does that become a bottleneck? How did other teams share
  review without people rubber-stamping?"
- **B7.** "Our rule is that nobody merges code they can't explain. How do teams check that in practice?"
- **B8.** "We run a script (lint and tests) before merge. What's the minimum set of automatic checks you'd
  insist on for a team like ours?"
- **B9.** "Our GitHub repo is private and branch protection needs a paid plan. What did teams do: pay,
  make the repo public, or rely on agreements?"

## C. Data and backend
- **★C1.** "For now our data is sample files inside the app, with a clear boundary so we can plug in a
  real server later without changing screens. Is that how teams usually avoid rewrites? Have you seen it
  go wrong?"
- **C2.** "We decided not to use a database on the phone, just simple files. Is that normal for an app
  like this, or do most teams need one early?"
- **★C3.** "For the real backend we're choosing between Firebase and Supabase. Which have the teams
  you've helped used for a social app with friends, a feed, comments and chat? What did they like and
  regret?"
- **C4.** "Would you build chat yourself, or use a ready-made chat service? Why?"
- **C5.** "How do teams build a feed that shows friends' posts first, then newer posts, without it
  getting slow or expensive?"
- **C6.** "People can upload photos and voice notes. How did teams control storage cost? Do they resize
  photos on the phone before upload?"
- **★C7.** "How do teams make sure private posts and blocked people can't leak, even if the app has a
  bug? Is that done on the server?"
- **C8.** "How long did a team of beginners typically take to get login, friends, a feed and chat working
  on a real backend? Is four weeks realistic?"

## D. Safety, moderation and legal
Frame these as "what did teams do?", not "what does the law say?". (Details: `docs/RISKS.md`.)
- **★D1.** "Apple requires that users can report and block, and we must act fast. In India the rules say
  we may have to remove some content within 2 to 3 hours. How did small teams you know handle after-hours
  reports?"
- **D2.** "We plan to hide a reported post automatically for serious categories (nudity, self-harm,
  threats) until we review it. Is that standard?"
- **D3.** "Posts show where people went. To protect them we never show exact times, we delay posting by
  30 minutes, we default to friends-only, and we never upload the GPS route. Did teams do something
  similar? Will that hurt how much people use the app?"
- **D4.** "Users must be 18+. We only ask for a date of birth. Is that enough in practice? What happens
  when a younger person gets in?"
- **★D5.** "We'll publish under one of our personal developer accounts. How did teams handle who legally
  owns the app and who is responsible for what users post? Should we form a company first?"
- **★D6.** "India's data protection and IT rules apply to us. Did the teams you helped talk to a lawyer?
  What did that cost, and what did they ask?"
- **D7.** "We need a privacy policy and terms of service. Did teams write their own, use templates, or
  pay for them?"
- **D8.** "Our working name 'Vybe' is already used by two similar apps. How did teams handle choosing a
  name? When did they check trademarks?"

## E. Launch and growth
- **E1.** "How did teams get their first 50 to 100 real users for a social app that needs friends to be
  useful? Does launching at one college work?"
- **E2.** "Most of our users' friends use Android and we're iPhone only. Did teams build a web page so
  friends without the app can still see and respond? How did that go?"
- **★E3.** "What does Apple's review usually reject social apps for? How long did the first TestFlight
  review take for teams you know?"
- **E4.** "What numbers should we watch in the first month after launch, and which should we ignore?"

## F. Wrap-up
- **F1.** "If you could tell us one thing to do differently right now, what would it be?"
- **F2.** "Who else should we talk to: someone who has done chat, someone who has dealt with moderation,
  someone for the legal part?"
- **F3.** "Can we show you the app again in two or three weeks, once there are real screens?"

## Where we are least sure (say this openly)
1. Whether 18 modules is too much structure for four beginners.
2. Firebase or Supabase.
3. Whether the safety defaults will hurt engagement.
4. Whether the plan fits the time (`docs/BEFORE-BUILD.md` section 4).
5. Anything legal: none of it has been reviewed by a lawyer.

## Capturing the answers
```
Q: <the question number, e.g. B1>
Mentor said: <his answer in his words>
Does it agree with our plan? yes / partly / no
What he suggested instead: <if any>
Who/what he mentioned (names, tools, numbers): <if any>
```

## Prompt to give an AI afterwards
> "Read AGENTS.md, docs/ARCHITECTURE.md, docs/OPEN-QUESTIONS.md and docs/RISKS.md. Below are my notes
> from a mentor session. For each answer: (1) say whether it confirms, changes or contradicts a decision
> in our docs, (2) list the exact documents and sections that need to change, (3) propose the new
> wording, (4) list new or removed tasks in docs/tasks/ and (5) list anything the mentor said that we
> should verify before trusting. Don't edit any file yet. Plan only. Be honest where his advice
> conflicts with what we researched. Notes: …"
