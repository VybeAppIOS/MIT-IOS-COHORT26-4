# Vybe: Open Questions

Things we have not decided yet, each with who should answer it. Research notes come from web searches on 3 Nov 2026; most sources are
blogs or forums, so check the official page before relying on them. None of this is legal advice. If your task touches an open
question, stop and ask a human.

Owners: **Team** (us), **Mentor** (people who have built apps like this), **Legal** (a lawyer or official text), **Backend**
(Lohitaksh's research).

---

## 1. Login and fake accounts (Team + Backend)
We want email-only because of cost, but worry about fake accounts.
- SMS OTP in India: about ₹0.10 to ₹0.45 per OTP plus DLT registration and 18% GST
  ([Message Central](https://www.messagecentral.com/blog/sms-otp-pricing-india), [Authgear](https://www.authgear.com/post/best-otp-service-providers/)).
  WhatsApp OTP: about ₹0.115 to ₹0.145 per message for an India-registered business, about ₹2.30 if registered abroad; no DLT
  ([Authgear](https://www.authgear.com/post/whatsapp-api-pricing), [AiSensy](https://m.aisensy.com/blog/whatsapp-business-pricing/)).
- Firebase phone login needs the paid Blaze plan; the Indian price per SMS is unclear ($0.01 to $0.07 by source;
  [Logto](https://blog.logto.io/it/firebase-authentication-pricing)).
- If we offer Google login, Apple requires Sign in with Apple or an equivalent (guideline 4.8; [ptkd](https://ptkd.com/app-store/guidelines/4-8)).
- Firebase App Check (App Attest) proves a request came from our real app but does not stop fake accounts by itself
  ([Firebase](https://firebase.google.com/docs/app-check)).
- **Suggestion:** Sign in with Apple + Google + verified email, no phone (free for us, harder to fake), plus rate limits, App
  Attest and a verified-email check before posting or chatting.
- [ ] Team: is Apple + Google + email acceptable instead of phone? [ ] Mentor: how bad were fake accounts with email-only login, and
  what worked? [ ] Backend: can our backend send WhatsApp OTPs, and what does it cost end to end?

## 2. Account deletion (Legal + Mentor)
Decided: no deactivation; posts stay after deletion; all of the person's photos are deleted (8a-2).
- Apple requires in-app deletion of the account and its personal data (deactivation is not enough); Sign in with Apple tokens must
  be revoked ([5.1.1(v)](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion),
  [offering deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app)). India's DPDP Rules (notified Nov
  2025, full obligations about May 2027) give users rights over their personal data; startups are not exempt
  ([Mondaq](https://www.mondaq.com/india/data-protection/1706890/a-closer-look-at-the-dpdp-rules-2025)).
- [ ] Legal: can posts stay (shown as "[deleted]") under Apple's rules and the DPDP Rules? Is post text "personal data"?
  [ ] Mentor: how did you handle deletion, and did Apple ever reject it?

## 3. Age and minors (Legal)
Decided: date of birth and 18+ confirmation at sign-up. DPDP Rules require verifiable parental consent for minors
([SCC Online](https://www.scconline.com/blog/post/2025/12/26/digital-personal-data-protection-rules-2025-key-highlights/)).
- [ ] Legal: is a self-declared date of birth enough, or do we need real age checks? What do we do on finding an under-18 user?

## 4. Places data source (Backend + Team)
Decided: our own Place database with Apple's Place ID stored; never copy MapKit or Google data.
- Apple: MapKit data may not be stored except temporarily, no bulk downloads; the iOS 18 Place ID can be stored and used later (one
  report: missing on a real device in iOS 18.1.1)
  ([agreement](https://developer.apple.com/support/terms/apple-developer-program-license-agreement),
  [MKMapItem.identifier](https://developer.apple.com/documentation/mapkit/mkmapitem/identifier-swift.property.md),
  [WWDC24](https://developer.apple.com/la/videos/play/wwdc2024/10097/)). Google: since 2024 Places data cannot be used with a
  non-Google map, so out ([terms](https://cloud.google.com/maps-platform/terms/maps-service-terms/index-20240522)).
- **Foursquare Open Source Places:** 100M+ places, Apache 2.0, free commercial use, Parquet files; India coverage unknown
  ([docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source)). **Overture Maps Places** (Meta, Microsoft; CDLA
  Permissive 2.0; India coverage unknown; [Linux Foundation](https://linuxfoundation.org/press/overture-maps-foundation-releases-first-open-map-dataset)).
  **OpenStreetMap:** free, but mixing it into our Place list may force publishing that list under ODbL (share-alike;
  [OSMF FAQ](https://osmfoundation.org/wiki/Licence_and_Legal_FAQ)).
- [ ] Team: search 20 real Kothrud Spots (include chai stalls) in Apple Maps, Foursquare and Overture data; which has the most
  correct? [ ] Backend: test the Apple Place ID on the lab iPhone (iOS 18+). [ ] Mentor: where did you get your places data?
  [ ] Team: who reviews user-suggested Places, and how (online check, call, visit)?

Proposed categories (to confirm): **Food and drink** (Café, Street food, Chai/tapri, Restaurant, Dessert, Juice/shakes) · **Outdoors**
(Trek, Fort, Viewpoint/hill, Lake/dam, Waterfall (seasonal), Park/garden, Camping) · **Fun** (Gaming/arcade, Bowling, Go-karting,
Trampoline, Escape room, Board-game café, Karaoke) · **Entertainment** (Cinema, Comedy/open mic, Live music, Events) · **Culture**
(Museum, Heritage/temple, Art gallery, Theatre, Bookstore/library) · **Shopping** (Street market, Thrift, Mall) · **Active** (Sports
turf, Swimming, Cycling) · **Chill/study** (Study café, Library).
- [ ] Team: treks need extra fields (difficulty, duration, season, start point, safety note); confirm. [ ] Legal: bars stay out
  (Maharashtra: beer 21, spirits 25, plus permits; old sources, [Business Today](https://www.businesstoday.in/amp/latest/policy/story/home-delivery-of-liquor-to-be-made-legal-in-maharashtra-151838-2018-10-14)).

## 5. Moderation (Team + Mentor)
- Apple guideline 1.2 needs filtering, reporting, blocking and in-app contact details; reviewers test that blocking really hides the
  person everywhere ([Vettly](https://vettly.pages.dev/blog/app-store-guideline-1-2)).
- Proposed report reasons: spam, harassment or bullying, hate, nudity or sexual content, violence or threats, self-harm, drugs or
  illegal goods, scam, impersonation, copyright, fake or unsafe Spot, possibly under 18, something else.
- Proposed handling: reports are anonymous; the reporter stops seeing the item at once; auto-hide for everyone after N reports, or at
  once for self-harm and threats, until reviewed.
- [ ] Team: what is N? Who checks the report queue, and how fast (all four share it)? How do we handle voice notes, which are hard to
  moderate? [ ] Mentor: what moderation setup worked for a small team, and which tools?

## 6. Backend (Backend + Mentor)
- Supabase: official Mumbai region; free tier (500 MB, pauses after 7 days idle); Pro $25/month; phone login needs our own SMS
  provider ([regions](https://supabase.com/docs/guides/platform/regions), [pricing](https://designrevision.com/blog/supabase-pricing.md)).
  Firebase: Mumbai region per blogs only (verify); phone login built in but paid; push built in
  ([comparison](https://rohitraj.tech/en/notes/supabase-vs-firebase-india-mvp-2026)). Current lean: **Firebase**
  (`docs/ARCHITECTURE.md` section 8).
- [ ] Backend: Firebase or Supabase? Build a tiny test (login + one table) in each (BK-1). [ ] Team: we must allow one library (the
  backend SDK); OK to change that rule? [ ] Backend: real-time chat with photos and voice notes: cost at 1,000 users? [ ] Backend: push
  needs the paid Apple Developer account; when do we buy it? [ ] Mentor: what would you pick for a 4.5-week build by beginners?
  [ ] Backend: admin page for reports, Picks and Place suggestions: web page or hidden app screen?

## 7. Privacy policy and Terms (Legal)
- The App Store needs a privacy policy; sources disagree on whether outside TestFlight testers need one
  ([Apple forums](https://developer.apple.com/forums/thread/706282)).
- [ ] Legal: who writes the privacy policy and Terms, and by when (before TestFlight)? Terms must cover the user photo licence,
  photos of other people and Remix credit. Where is user data stored (India region?) and must we say so?

## 8. Product questions still to discuss (Team)
- [ ] Multi-person Hangouts: when do we revisit? [ ] Offline game: what is it? [ ] Feed "trending": what counts? [ ] "You might
  know": mutual friends only, or more later? [ ] Limits final? (Spots 2 to 10, photos 2 × Spots, 2 per chat message, 500 friends)
  [ ] Is "Place" (venue) vs "Spot" (inside a Hangout) clear to everyone?

## 8a. Data decisions (DECIDED 3 Nov; `docs/DATA-MODEL.md` section 7)
- [x] All 12 decided; everything ships in version 1 (phases are build order only). Picks are posts by the Vybe account (one feed card
  type). Same Place twice allowed, with a warning. Deleted usernames held 30 days.
- [ ] Team: are Picks physically done by the team before posting? With about 40 Picks that is a lot of outings; can early Picks be
  posted from the team's past real visits? (8a-2 says yes, from real past visits.)

## 8a-2. Decisions of 3 Nov (evening)
- [x] **No cut list:** build all frontend screens properly on sample data; no fixed roles; a task pool. [x] **Figma** is a loose
  reference, not the spec. [x] **Picks** come from the team's real past visits. [x] **Account deletion deletes all of the person's
  photos**; posts stay as "[deleted]". [x] **No Claude Code settings/hook files** are added.
- [ ] **New "frontend done" date** after measuring speed (`docs/BEFORE-BUILD.md` 4).

## 8b. Project changes: APPROVED for Phase 1 (3 Nov)
- [x] Location permission text (`NSLocationWhenInUseUsageDescription`). [x] Kothrud `.gpx` simulated walk in the Xcode scheme.
  [x] Background Modes → Location updates + `CLBackgroundActivitySession` for the live Hangout (Apple: only the `UIBackgroundModes`
  Info.plist key, no entitlement; whether a free account allows the capability toggle in Xcode is UNVERIFIED: test on Fri 6 Nov).
- [x] **Done in X-9 (5 Nov), not yet built on a Mac:** location and microphone purpose texts (`INFOPLIST_KEY_…` in the app
  target), `UIBackgroundModes: location` in `Config/Vybe-Info.plist`, `Config/Kothrud-Walk.gpx` (EXAMPLE route, same as the
  simulated walk) in the scheme, `Config/Base.xcconfig` including the git-ignored `Local.xcconfig`. Privacy manifest was done earlier.
- [ ] **Device test, Fri 6 Nov (lab iPhone):** does a free account allow background location? Live Hangout keeps updating with the
  screen locked? Apple Place ID resolves on a real device? Write the answers here.
- [ ] Later: camera permission text (only if a camera screen is added; `PhotosPicker` needs none); a UI test target for the
  accessibility audit (X-10).

## 8c. Decisions from the 3 Nov research (details in `docs/RISKS.md`)
- [x] **Safety defaults ACCEPTED 3 Nov** (RISKS section 3): friends-only posts by default, exact visit times never shown, 30-minute
  post delay, no GPS track upload, ask-before-group-add. (Accepted without reviewing the detail: mentors and a lawyer should look.)
- [x] **Android friends: web page + web "I'm in" in version 1.** [x] **Deleted usernames: 30-day hold.** [x] **First launch group:
  MIT-WPU, for advertising only:** its name must not appear in the app and no college field is collected. [x] **iOS 26 minimum.**
- [ ] **Name:** "Vybe" is used by two going-out apps on the App Store; reserve a longer name now, check trademarks and pick the final
  brand before TestFlight? Researching in parallel with `docs/prompts/NAME-RESEARCH.md`.
- [ ] **Firestore edition** (Standard vs Enterprise) if Firebase is chosen; permanent. [ ] **Server photo screening** (e.g.
  SafeSearch) in version 1? [ ] Install an iOS 26 simulator runtime (only iOS 27 is installed). [ ] Lawyer questions: `docs/RISKS.md`
  section 7.

## 8d. Decisions of 4 Nov (review of every PR: `docs/REVIEW-4-NOV.md`)
- [x] **Social stays in version 1** (Lohitaksh): Community, Friends and Chat ship in v1 and go to TestFlight; nothing moves to
  a v1.1.
- [ ] **Release builds crash at launch** until the backend exists: the social repositories are DEBUG-only stubs
  (`fatalError` in `AppDependencies+Local.swift`). Before the first TestFlight: the backend (BK-2…BK-7), or an internal
  "sample data" build flag. Decide at BK-14.
- [ ] **GitHub Actions never ran** (no workflow runs on any PR, public repo): turn Actions on in Settings → Actions → General
  (Lohitaksh), then check that `lint.yml` and `test.yml` run on the next PR.
- [ ] **Bundled content is empty** until X-C1 (5 real Places, 2 real Hangouts): the app on the simulator shows empty states;
  previews and tests use the EXAMPLE samples.

## 9. Design (Team, later)
- [ ] Theme values (colours, fonts) and who decides. [ ] Figma frames for components and screens. [ ] App icon and launch screen.
  [ ] D3 filters list, S1 empty-state suggestions, PR1 stats, D1 pin style. [ ] Share in Phase 1: what does the shared text say?
