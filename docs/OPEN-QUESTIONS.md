# Vybe: Open Questions

Things we have not decided yet. Each one says who should answer it.
Research notes come from web searches on 3 Nov 2026; most sources are blogs or forums,
so check the official page before relying on them. None of this is legal advice.

Owners: **Team** (us), **Mentor** (people who have built apps like this),
**Legal** (needs a lawyer or official text), **Backend** (Lohitaksh's research).

---

## 1. Login and fake accounts (Team + Backend)
We want email-only because of cost, but worry about fake accounts.

Research so far:
- SMS OTP in India: roughly ₹0.10 to ₹0.45 per OTP, plus DLT registration and 18% GST.
  ([Message Central](https://www.messagecentral.com/blog/sms-otp-pricing-india),
  [Authgear](https://www.authgear.com/post/best-otp-service-providers/))
- WhatsApp OTP ("authentication" messages) in India: about ₹0.115 to ₹0.145 per message
  for an India-registered business, but about ₹2.30 if the business is registered abroad.
  Roughly the same price as SMS, not clearly cheaper, but no DLT.
  ([Authgear](https://www.authgear.com/post/whatsapp-api-pricing),
  [AiSensy](https://m.aisensy.com/blog/whatsapp-business-pricing/))
- Firebase phone login needs the paid Blaze plan; Indian price per SMS is unclear
  ($0.01 to $0.07 depending on source).
  ([Logto](https://blog.logto.io/it/firebase-authentication-pricing))
- If we offer Google login, Apple requires Sign in with Apple or an equivalent
  (guideline 4.8). ([ptkd](https://ptkd.com/app-store/guidelines/4-8))
- Firebase App Check (App Attest) proves a request came from our real app, but does not
  stop fake accounts by itself. ([Firebase](https://firebase.google.com/docs/app-check))

Suggestion to discuss: **Sign in with Apple + Google + verified email**, no phone.
Apple and Google accounts are free for us and harder to fake. Add rate limits,
App Attest, and a verified-email check before posting or chatting.

Questions:
- [ ] Team: is Apple + Google + email acceptable instead of phone?
- [ ] Mentor: how bad were fake accounts in your apps with email-only login? What worked?
- [ ] Backend: can our backend send WhatsApp OTPs, and what does it cost us end to end?

## 2. Account deletion (Legal + Mentor)
Decision so far: no deactivation; posts stay after deletion; photos may be deleted.

Research so far:
- Apple requires in-app account deletion, and says the account and its personal data
  must be deletable; deactivation is not enough. Sign in with Apple tokens must be revoked.
  ([Apple 5.1.1(v)](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion),
  [Apple: offering account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app))
- India's DPDP Rules (notified Nov 2025, full obligations about May 2027) give users
  rights over their personal data; startups are not exempt.
  ([Mondaq](https://www.mondaq.com/india/data-protection/1706890/a-closer-look-at-the-dpdp-rules-2025))

Questions:
- [ ] Legal: can posts stay (shown as "[deleted]") after an account is deleted, under
      Apple's rules and the DPDP Rules? Is the post text "personal data"?
- [ ] Team: are photos always removed on deletion, or only on request?
- [ ] Mentor: how did you handle deletion in your app, and did Apple ever reject it?

## 3. Age and minors (Legal)
Decision: date of birth and 18+ confirmation at sign-up.
- DPDP Rules require verifiable parental consent for minors.
  ([SCC Online](https://www.scconline.com/blog/post/2025/12/26/digital-personal-data-protection-rules-2025-key-highlights/))
- [ ] Legal: is a self-declared date of birth enough, or do we need real age checks?
- [ ] Legal: what do we do if we find out a user is under 18?

## 4. Places data source (Backend + Team)
Decision: our own Place database, with Apple's Place ID stored. Never copy MapKit or Google data.

Research so far:
- Apple: MapKit data may not be stored except temporarily; no bulk downloads.
  The iOS 18 Place ID can be stored and used later. One report says the ID was missing
  on a real device in iOS 18.1.1.
  ([Apple agreement](https://developer.apple.com/support/terms/apple-developer-program-license-agreement),
  [MKMapItem.identifier](https://developer.apple.com/documentation/mapkit/mkmapitem/identifier-swift.property.md),
  [WWDC24 Place ID](https://developer.apple.com/la/videos/play/wwdc2024/10097/))
- Google: since 2024, Places data cannot be used with a non-Google map. Out for us.
  ([Google terms](https://cloud.google.com/maps-platform/terms/maps-service-terms/index-20240522))
- **Foursquare Open Source Places**: 100M+ places, Apache 2.0, free for commercial use,
  downloadable as Parquet files. India coverage unknown.
  ([Foursquare docs](https://docs.foursquare.com/data-products/docs/fsq-places-open-source),
  [Simon Willison](https://simonwillison.net/2024/Nov/20/foursquare-open-source-places))
- **Overture Maps Places**: from Meta and Microsoft, CDLA Permissive 2.0 (commercial use
  allowed). India coverage unknown.
  ([Linux Foundation](https://linuxfoundation.org/press/overture-maps-foundation-releases-first-open-map-dataset))
- **OpenStreetMap**: free, but mixing it into our Place list may force us to publish
  that list under ODbL (share-alike).
  ([OSMF FAQ](https://osmfoundation.org/wiki/Licence_and_Legal_FAQ))

Questions:
- [ ] Team: search 20 real Kothrud Spots (include chai stalls) in Apple Maps, and in
      Foursquare and Overture data. Which has the most correct?
- [ ] Backend: test the Apple Place ID on the lab iPhone (iOS 18+).
- [ ] Mentor: where did you get your places data from?
- [ ] Team: who reviews user-suggested Places, and how (online check, call, visit)?

Proposed categories (to confirm):
- Food and drink: Café, Street food, Chai/tapri, Restaurant, Dessert, Juice/shakes
- Outdoors: Trek, Fort, Viewpoint/hill, Lake/dam, Waterfall (seasonal), Park/garden, Camping
- Fun: Gaming/arcade, Bowling, Go-karting, Trampoline, Escape room, Board-game café, Karaoke
- Entertainment: Cinema, Comedy/open mic, Live music, Events
- Culture: Museum, Heritage/temple, Art gallery, Theatre, Bookstore/library
- Shopping: Street market, Thrift, Mall
- Active: Sports turf, Swimming, Cycling
- Chill/study: Study café, Library
- [ ] Team: treks need extra fields (difficulty, duration, season, start point, safety note). Confirm.
- [ ] Legal: bars stay out. Maharashtra: beer 21, spirits 25, plus permits (old sources).
      ([Business Today](https://www.businesstoday.in/amp/latest/policy/story/home-delivery-of-liquor-to-be-made-legal-in-maharashtra-151838-2018-10-14))

## 5. Moderation (Team + Mentor)
- Apple guideline 1.2 needs: filtering, reporting, blocking, in-app contact details.
  Reviewers test that blocking really hides the person everywhere.
  ([Vettly](https://vettly.pages.dev/blog/app-store-guideline-1-2))
- Proposed report reasons: spam, harassment or bullying, hate, nudity or sexual content,
  violence or threats, self-harm, drugs or illegal goods, scam, impersonation, copyright,
  fake or unsafe Spot, possibly under 18, something else.
- Proposed handling: reports are anonymous; the reporter stops seeing the item at once;
  auto-hide for everyone after N reports, or at once for self-harm and threats, until reviewed.
- [ ] Team: what is N (reports before auto-hide)?
- [ ] Team: who checks the report queue, and how fast? (All four share it.)
- [ ] Mentor: what moderation setup worked for a small team? Any tools you used?
- [ ] Team: how do we handle voice notes, which are hard to moderate?

## 6. Backend (Backend + Mentor)
Research so far:
- Supabase: official Mumbai region; free tier (500 MB database, pauses after 7 days idle);
  Pro $25/month; phone login needs our own SMS provider.
  ([Supabase regions](https://supabase.com/docs/guides/platform/regions),
  [pricing summary](https://designrevision.com/blog/supabase-pricing.md))
- Firebase: Mumbai region per blogs only (verify); phone login built in but paid; push built in.
  ([Supabase vs Firebase for India](https://rohitraj.tech/en/notes/supabase-vs-firebase-india-mvp-2026))
- Current lean: **Firebase** (see `docs/ARCHITECTURE.md` section 8), whichever login methods are chosen.

Questions:
- [ ] Backend: Firebase or Supabase? Build a tiny test (login + one table) in each.
- [ ] Team: we must allow one library (the backend SDK). OK to change that rule?
- [ ] Backend: real-time chat with photos and voice notes: what does it cost at 1,000 users?
- [ ] Backend: push notifications need the paid Apple Developer account. When do we buy it?
- [ ] Mentor: what would you pick for a 4.5-week build by beginners?
- [ ] Backend: admin page for reports, Picks and Place suggestions: web page or hidden app screen?

## 7. Privacy policy and Terms (Legal)
- The App Store needs a privacy policy. Sources disagree on whether outside TestFlight
  testers need one. ([Apple forums](https://developer.apple.com/forums/thread/706282))
- [ ] Legal: who writes the privacy policy and Terms, and by when (before TestFlight)?
- [ ] Legal: Terms must cover user photo licence, photos of other people, and Remix credit.
- [ ] Legal: where is user data stored (India region?), and do we need to say so?

## 8. Product questions still to discuss (Team)
- [ ] Multi-person Hangouts: when do we revisit?
- [ ] Offline game: what is it?
- [ ] Feed "trending": what counts as trending?
- [ ] "You might know": mutual friends only, or more later?
- [ ] Limits: Spots 2 to 10, photos 2 × Spots, 2 per chat message, 500 friends. Final?
- [ ] Code word check: is "Place" (venue) vs "Spot" (inside a Hangout) clear to everyone?

## 8a. Data decisions — DECIDED 3 Nov (see `docs/DATA-MODEL.md` section 7)
- [x] All 12 decided. Everything ships in version 1; phases are build order only.
- [x] Picks are posts by the Vybe account (one feed card type).
- [x] Same Place twice allowed, with a warning.
- [x] Deleted usernames are held for 30 days (changed 3 Nov from "free immediately").
- [ ] Team: are Picks physically done by the team before posting? With ~40 Picks by
      Thursday, that's a lot of outings. Can early Picks be posted from the team's
      past real visits?

## 8a-2. Decisions of 3 Nov (evening)
- [x] **No cut list:** build all frontend screens properly on sample data; no fixed roles; a task pool.
- [x] **Figma** is only a loose reference (not the spec).
- [x] **Picks** come from the team's **real past visits**.
- [x] **Account deletion deletes all of the person's photos**; posts stay as "[deleted]".
- [x] **No Claude Code settings/hook files** are added.
- [ ] **New "frontend done" date** after measuring speed (see `docs/BEFORE-BUILD.md` 4).

## 8b. Project changes — APPROVED for Phase 1 (3 Nov)
- [x] Location permission text (`NSLocationWhenInUseUsageDescription`).
- [x] Kothrud `.gpx` simulated walk in the Xcode scheme.
- [x] Background Modes → Location updates + `CLBackgroundActivitySession` for the live Hangout.
      (Apple: it is only the `UIBackgroundModes` Info.plist key, no entitlement; whether a
      free account allows the capability toggle in Xcode is UNVERIFIED: test on Fri 6 Nov.)
- [ ] Later: camera and microphone permission texts; a UI test target for the accessibility audit.

## 8c. New decisions from the 3 Nov research (Team, then mentors) — details in `docs/RISKS.md`
- [ ] **Name:** "Vybe" is used by two going-out apps on the App Store. Reserve a longer
      name now, check trademarks, and pick the final brand before TestFlight?
- [x] **Safety defaults ACCEPTED 3 Nov** (RISKS section 3): friends-only posts by default,
      exact visit times never shown, 30-minute post delay, no GPS track upload,
      ask-before-group-add. (Team note: accepted without reviewing the detail; mentors
      and a lawyer should look at them.)
- [x] **Android friends: web page + web "I'm in" in version 1** (decided 3 Nov).
- [x] **Deleted usernames: 30-day hold** (decided 3 Nov).
- [x] **First launch group: MIT-WPU, for advertising only.** The college's name must not
      appear anywhere in the app, and no college field is collected.
- [x] **iOS 26 minimum** (decided 3 Nov). Project setting changed; docs updated.
- [ ] **App name:** being researched in parallel; use `docs/prompts/NAME-RESEARCH.md`.
- [ ] **Firestore edition** (Standard vs Enterprise) if Firebase is chosen; permanent.
- [ ] **Server photo screening** (e.g. SafeSearch) in version 1?
- [ ] Install an iOS 26 simulator runtime (our minimum; only iOS 27 is installed).
- [ ] Lawyer questions: `docs/RISKS.md` section 7.

## 9. Design (Team, later)
- [ ] Theme values (colours, fonts) and who decides.
- [ ] Figma frames for components and screens.
- [ ] App icon and launch screen.
- [ ] D3 filters list. S1 empty-state suggestions. PR1 stats. D1 pin style.
- [ ] Share in Phase 1: what does the shared text say?
