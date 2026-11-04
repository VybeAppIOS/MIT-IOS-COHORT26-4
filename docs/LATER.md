# Vybe: Think About Later (does NOT block building now)

Written 3 Nov 2026. These don't change what you build now, but each has a
deadline after which it gets expensive. "Decide by" uses these milestones:
**Phase 2 start (16 Nov)** · **Before TestFlight (~10 Dec)** · **Before public launch** ·
**After launch**. Items that DO block building are in `docs/BEFORE-BUILD.md`.

## Decide by Phase 2 start (16 Nov)
| Item | Why then |
|---|---|
| **Backend choice** (Firebase vs Supabase) and the SDK exception to "no third-party libraries" | the Remote module and the data rules depend on it (`docs/ARCHITECTURE.md` section 8) |
| **Firestore edition** (Standard vs Enterprise), if Firebase | permanent once the database exists |
| **Moderation operations**: who is on call, how reports are triaged, the 2-hour and 3-hour rules | shapes the report data and admin screens (`docs/RISKS.md`) |
| **Data retention vs deletion** (180-day records vs Apple's and DPDP's deletion rules) | a lawyer question; affects what we store |
| **Server owner** (one teammate for Cloud Functions or SQL) | ~8 to 10 functions to write and test |
| **Android / web strategy** | the web share page is already v1; decide how guests and notifications work |
| **Server photo screening** (e.g. SafeSearch) yes or no | cost and design |
| **Dev vs prod backend projects** | Firebase advises separate projects per environment |

## Decide before TestFlight (~10 Dec)
| Item | Why |
|---|---|
| **Final app name, brand, logo, app icon** | bundle ID, domain, App Store record, web URL and screenshots all depend on it. "Vybe" is used by two going-out apps on the App Store. |
| **Privacy policy and Terms of Service** (hosted on the domain) | Terms cover the photo licence, photos of other people, Remix credit, deletion. Needs a lawyer. The App Store requires a privacy policy; whether external TestFlight does is unclear (sources disagree). |
| **Crash reporting and analytics** | start with free Xcode Organizer crashes (no library); keep analytics events few and in the privacy labels |
| **Push notification design** (which events, when to ask permission) | needs the paid Apple account; ask at the first friend request or chat |
| **Launch plan for MIT-WPU** (advertising only; the name never appears in the app) | ambassadors, the first 30+ Picks, where invite links are shared. The Picks must be real visits |
| **Support channel and grievance contact** | required by Apple 1.2 and India's IT Rules |
| **App Store listing**: subtitle, screenshots (incl. iPhone Duo from April 2027), age-rating answers (due 12 Jan 2027), privacy labels | needs the final name and the build |
| **Demo account** for App Review | seeded with friends, posts and chat so reviewers can test block and report |

## Decide before public launch
| Item | Why |
|---|---|
| Accessibility labels in App Store Connect | voluntary now, expected to become required; we can never claim "Dark Interface" |
| Performance budgets (launch under ~400 ms to first frame, smooth feed) | measure on the lab iPhone after Phase 2 |
| Incident response note ("if it's down") and blameless post-incident notes | one page |
| Backups and restore test | before real users |
| Release process: weekly build, release captain, phased release for updates | `docs/PROCESS.md` |
| Legal entity / who owns the app | an individual account shows a personal name and carries personal liability for user content |
| Trademark filing for the final name | after the name is chosen and cleared |

## After launch
| Item | Notes |
|---|---|
| Hindi / Marathi | strings are already in String Catalogs, so it's cheap later |
| Android app | the data and backend are reusable; screens are not |
| Monetisation | the data model reserves a separate `Promotion` entity and external Place IDs. Never reuse `isPick` for paid content |
| Other cities | `city` is already a field on every Place |
| Multi-person Hangouts, polls in a Hangout, "Organiser" | revisit when one-person Hangouts work |
| Funding, team handover | depends on whether the project continues past the cohort |

## Nice ideas that were mentioned but not scheduled
- The **offline mini-game** shown when there is no signal.
- **Live Activity** on the lock screen for a live Hangout (Apple's preferred companion to background location).
- **Home-screen widget** ("tonight's Pick").
- **TipKit** hints on first use; **App Intents / Shortcuts** ("Start a Hangout").
- **Share cards** for Instagram stories from a posted Hangout.
- **College leaderboards or badges** (Beli does this) — would need a college field, which we decided not to collect.
- **Remix credit shown on the zoomed-out map** (cut-order candidate).
- **Voice notes** and **chat polls** (cut-order candidates if 18 Dec is at risk).

## Things to keep re-checking (they change)
- India's IT Rules and DPDP deadlines (13 May 2027 for most DPDP duties).
- App Store age-rating questionnaire and the April 2027 iOS 27 SDK requirement.
- Previews in packages on new Xcode versions.
- Firebase Extensions shutdown (31 Mar 2027), if any are used.
- Whether SwiftUI `Map` gains clustering.
