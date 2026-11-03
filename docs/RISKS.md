# Vybe: Risks, Safety and Legal (PROPOSAL, for mentor and lawyer review)

Status: **proposal; the safety defaults in section 3, the web share page and the 30-day
username hold were accepted by the team on 3 Nov (without a detailed review: mentors and
a lawyer should still check them).** Written 3 Nov 2026 from research into the Indian market, App Store
rules, Indian law and real safety incidents. Not legal advice. Items marked **checked**
were confirmed on the original source. Sources at the end.

---

## 1. The biggest risks (ranked)

| # | Risk | Evidence | Proposed answer | Decide by |
|---|---|---|---|---|
| 1 | **Most friends are on Android.** iOS is **5.1%** of phones in use in India (StatCounter, Oct 2026, **checked**). Even at a richer college, almost every group of 5 friends includes Android users, who can't accept requests, join chats or see posts. TestFlight is Apple-only. | StatCounter; Counterpoint/IDC (iPhone ~9-10% of 2025 shipments) | A **web page for every shared Hangout and post** with a WhatsApp preview, plus "I'm in" on the web without an account (Partiful's approach). Data model lets a Hangout invite include non-users. | mentors, 16 Nov |
| 2 | **The name "Vybe" is taken.** "Vybe: Go Out Smarter" (going-out app with a venue map and "where friends are heading") and "Vybe - The Going Out App" (hangouts, group chat, map) are both on the App Store (**checked**). A US "VYBE" software trademark is reportedly registered (aggregator data). | App Store listings | Try reserving a longer name in App Store Connect now (e.g. "Vybe: Hangouts in Pune"); run official IP India (Class 9/42) and USPTO searches; pick the final brand early. Keep "Vybe" out of code names where easy. | before TestFlight |
| 3 | **Cold start:** empty feed and no friends on day one. | Andrew Chen, *The Cold Start Problem*; a16z social benchmarks | Launch at **one college** (200 to 500 students), 30+ Picks, ~10 student ambassadors who post Hangouts; sharing to WhatsApp is the main growth loop. | mentors |
| 4 | **Location leakage** (posts reveal where someone lives or their routine). | Strava heatmap 2018, Strava 2024 (Le Monde), KU Leuven 2022: privacy zones defeated for 85% of activities | Safety defaults in section 3. | before Phase 2 build |
| 5 | **Legal deadlines a 4-person team can't meet manually.** India's IT Amendment Rules 2026 (in force 20 Feb 2026, all intermediaries, **checked**): 2 h for nudity/morphed images/CSAM, 3 h for government or court orders, 36 h unlawful content, 7 days general. | Khaitan & Co | Auto-hide on report for nudity, self-harm and threats; phone alert to an on-call teammate; named grievance contact in the app. | lawyer |
| 6 | **Database misconfiguration leaks private data.** | Tea app 2025 (open Firebase Storage, ~72,000 IDs and selfies); Supabase RLS-missing CVE-2025-48757 | Deny-by-default rules for database **and** storage; rule tests in CI; no admin keys in the app. | Phase 2 |
| 7 | **Dangerous treks and waterfalls.** | Rajgad fall (June 2025), Tamhini and Bhushi Dam drownings, monsoon tourism bans at Rajgad, Torna and dams | Trek safety note, monsoon banner (June to Sep), "closed by authorities" status on Places, no monsoon waterfall Picks. | Phase 1 data |
| 8 | **Platforms copy the idea.** District (Zomato), Instagram Map (India, Oct 2025). | Medianama, Meta | Edge: verified low-budget local data, ordered multi-spot routes, "done it" proof, Remix. | — |
| 9 | Low-frequency use makes daily metrics look bad. | going out isn't daily | Track weekly: Hangouts started, completed and posted per active group. | — |
| 10 | Business-model choices later break the data. | District, magicpin, Locket Gold | Reserve: external IDs on Place, a separate `Promotion` entity (never reuse `isPick` for paid content), entitlements on the user. | design only |

## 2. Competitors (India)
District by Zomato (movies, events, dining), Swiggy Dineout and Scenes (events),
magicpin (deals), Instagram Map (friends' locations, tagged places), Google Maps lists,
and WhatsApp groups (the real default). No funded Indian startup found doing ordered
multi-spot group plans for students in 2025-26.

## 3. Safety defaults (proposed)

| Setting | Default |
|---|---|
| New post audience | **Friends** (Public is opt-in, with a one-line warning) |
| Exact visit times on posts | **never shown** to others; show order and rounded duration ("about 3 h") and the day |
| Post delay after a Hangout ends | at least **30 minutes** (options: 2 h, next day) |
| Live Hangout visible to others | **never** (no setting) |
| GPS track | **never uploaded**; the mini-map draws straight lines between Place pins |
| Comments on my public posts | Friends |
| Friend requests | from everyone; requests with no mutual friends go to an "Other" folder; caps of 30 per day and 100 pending |
| Added to a group by a non-friend | asks first ("Join" / "Leave and block") |
| Show me in search and "You might know" | on, with easy switches |
| College or home area on profile | not collected |
| Photo location data | stripped (already decided) |

## 4. Proposed product changes (team to decide)
1. Visit and run times become **owner-only**; posts carry order and rounded duration.
2. Don't store the raw GPS route on the server.
3. Post delay of at least 30 minutes.
4. Non-friends must ask before adding you to a group (changes "any member adds friends").
5. **Deleted usernames:** **30-day hold** (decided 3 Nov, replacing "free immediately") to
   stop someone impersonating the deleted person to their friends. Indian rules may also
   require keeping registration data for 180 days; ask the lawyer.
6. New privacy settings: comments, who can send requests, group adds, search visibility.
7. New report reasons: "photo of me without consent", "private address", "impersonation";
   auto-hide immediately for nudity, self-harm and threats; show Tele-MANAS (14416) and
   112 in the self-harm flow.
8. Trek safety note, monsoon banner, "closed by authorities" Place status.
9. Grievance officer contact in Settings; on-call rota with push alerts for priority reports.
10. App Store age rating set to 18+ (Apple rates social feeds 13+ by default, **checked**);
    available in India only at first.
11. Unit tests for backend security rules before TestFlight.
12. Reviewers reject residential addresses in Place suggestions.

## 5. Threat table

| Threat | Likelihood | Impact | Mitigation | When |
|---|---|---|---|---|
| Visit times reveal routine | high | high | owner-only times, rounded duration | v1 |
| Real-time tracking via quick posting | medium | high | 30-min delay; live run never visible | v1 |
| GPS track reveals home | medium | high | never upload tracks | v1 |
| Home or hostel added as a Place | low | high | review rejects residential; report reason | v1 |
| Friend-request spam or stalking | high | medium | caps, "Other" folder, who-can-request | v1 |
| Stranger comments | high | medium | friends-only comments by default; keyword filter (Apple 1.2) | v1 |
| Added to a stranger group | medium | medium | ask first | v1 |
| Impersonation | medium | high | username hold; verified email; report reason | v1 |
| Intimate or morphed image | medium | high | auto-hide on report (2 h rule) | v1 |
| Under-18 user | high | high | neutral date-of-birth question; report freezes account; Declared Age Range on iOS 26 as a hint | v1 |
| Self-harm content | low | high | auto-hide; Tele-MANAS 14416 and 112 | v1 |
| Trek danger | medium | high | safety notes, monsoon banner, closures | v1 |
| Scam links, fake Places | medium | medium | link warning; review; report reason | v1 |
| Missed legal deadlines | high | high | auto-hide, on-call alerts, grievance contact | v1 |
| CSAM | low | high | never forward; preserve; report to police (POCSO s.19) and cybercrime.gov.in | v1 |
| Ban evasion | medium | medium | ban by Apple/Google account + DeviceCheck bit | v1 |
| Open database or storage | medium | high | deny by default; rule tests | v1 |
| Leaked admin key | low | high | no secret keys in the app | v1 |
| Account takeover | medium | high | Apple/Google sign-in, no SMS-only login, new-login alert | v1 |

## 6. App Store facts (2026)
- Social feed with likes, comments and shares = **13+** under Apple's new ratings (**checked**);
  we would set 18+. New "Shared Location" and Dating questions: all apps by **12 Jan 2027**.
- Guideline 1.2 (updated Oct 2026): filtering, reporting with timely responses, blocking,
  published contact details; failing to fix violations can be a Code of Conduct breach.
- From **April 2027**, uploads must use the iOS 27 SDK, and apps built with the iOS 27.1 SDK
  need iPhone Duo screenshots.
- Declared Age Range API: iOS 26+, age confirmed only in some regions (not India).
- Sign in with Apple hidden emails now use `private.icloud.com`.

## 7. Questions for a lawyer
1. Is Vybe an "intermediary" from day one? Do the 2 h / 3 h / 36 h / 7-day timelines apply at our size? Do we need a resident grievance officer?
2. Do CERT-In's 6-hour incident reporting and 180-day log rules apply to a student team?
3. Does keeping registration data 180 days conflict with Apple's deletion rule and DPDP erasure? Can posts stay after deletion?
4. Is a self-declared date of birth plus an 18+ rating enough? What must we do with an under-18 account?
5. Procedure and liability for police data requests and CSAM reporting (POCSO s.19).
6. Liability for a trek accident at a Spot we list or a Pick we post; disclaimer wording.
7. Can posts show alcohol when many users are under 21 or 25 in Maharashtra?
8. Is the name "Vybe" usable given existing App Store apps and trademarks?
9. Who legally publishes the app: an individual account or a company?

## Sources
Market: [StatCounter India](https://gs.statcounter.com/os-market-share/mobile/india) ·
[TechCrunch: iPhone in India 2025](https://techcrunch.com/2026/01/23/apple-iphone-just-had-its-best-year-in-india-as-the-smartphone-market-stays-broadly-flat) ·
[EE Times India / IDC](https://www.eetindia.co.in/idc-india-smartphone-market-flat-in-2025/) ·
[Partiful on the App Store](https://apps.apple.com/app/id1662982304) ·
[Clubhouse Android in India](https://businesstoday.in/technology/story/clubhouse-is-coming-to-indian-android-users-on-may-21-296289-2021-05-17)
Name: [Vybe: Go Out Smarter](https://apps.apple.com/us/app/-/id6762636915) ·
[Vybe - The Going Out App](https://apps.apple.com/app/id1668442386) ·
[App name rules](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
Growth: [Andrew Chen interview](https://techcrunch.com/2021/12/08/andrew-chen-of-a16z-on-how-startups-get-past-a-cold-start-to-survive-and-thrive) ·
[a16z social benchmarks](https://a16z.com/2023/03/03/how-to-benchmark-your-social-app) ·
[WhatsApp link previews](https://developers.facebook.com/documentation/business-messaging/whatsapp/link-previews/)
Competitors: [District](https://www.medianama.com/2026/01/223-eternal-doubling-down-district-despite-rising-losses/) ·
[Swiggy Scenes](https://www.medianama.com/2024/12/223-swiggy-launches-live-events-vertical-scenes-takes-on-zomato-district/) ·
[Instagram Map India](https://about.fb.com/news/2025/10/now-in-india-instagram-rolls-out-map-feature-to-help-people-connect-with-friends/)
Location safety: [Strava heatmap 2018](https://www.helpnetsecurity.com/2018/01/29/strava-user-heatmap-reveals-patterns-of-life-in-western-military-bases/) ·
[Strava 2024](https://fortune.com/2024/10/29/biden-trump-harris-confidential-movements-fitness-app-strava-le-monde) ·
[KU Leuven privacy zones](https://www.darkreading.com/application-security/popular-fitness-apps-leak-location-data-even-when-users-set-privacy-zones) ·
[Home location inference (ICWSM)](https://ojs.aaai.org/index.php/ICWSM/article/view/14762)
Harassment: [Amnesty India study](https://www.amnesty.org.uk/press-releases/india-women-politicians-face-shocking-scale-abuse-twitter-new-research) ·
[IT for Change: young women online](https://ruralindiaonline.org/en/library/resource/born-digital-born-free-a-socio-legal-study-on-young-womens-experiences-of-online-violence-in-south-india/) ·
[Bumble India safety](https://www.businessinsider.in/advertising/ad-tech/news/at-bumble-safety-is-our-number-one-priority-priti-joshi-bumble/articleshow/81670547.cms)
Age and App Store: [Apple age ratings](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/) ·
[Apple age assurance](https://developer.apple.com/support/age-assurance) ·
[App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) ·
[Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/)
Treks: [Rajgad](https://www.freepressjournal.in/pune/tragedy-at-rajgad-21-year-old-pune-woman-falls-400-feet-to-her-death-during-trek) ·
[Monsoon bans](https://www.punekarnews.in/?p=210286) ·
[Bhushi Dam 2024](https://en.wikipedia.org/wiki/2024_Lonavala_waterfall_tragedy)
Law: [IT Amendment Rules 2026 (Khaitan)](https://www.khaitanco.com/thought-leadership/MeitY-notifies-the-IT-Amendment-Rules-2026) ·
[IT Rules 2021 (Trilegal)](https://trilegal.com/knowledge-repository/information-technology-rules-2021/) ·
[CERT-In directions](https://www.mondaq.com/india/it-and-internet/1270362/6-hours-to-report-cyber-incidents-to-cert-in-and-more-compliances) ·
[Tele-MANAS](https://pib.gov.in/PressReleasePage.aspx?PRID=2022057)
Security: [Tea app breach](https://www.404media.co/women-dating-safety-app-tea-breached-users-ids-posted-to-4chan/) ·
[Firebase insecure rules](https://firebase.google.com/docs/firestore/security/insecure-rules) ·
[Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) ·
[DeviceCheck](https://developer.apple.com/documentation/devicecheck)
