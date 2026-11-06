# Vybe: Product and Scope

Fresh start: do not look for older code or designs. Open questions: `docs/OPEN-QUESTIONS.md`.

## 0. Problem (draft, team to confirm)
College friend groups in Pune want to go out on a low budget, but planning where to go, in what order, and agreeing on it takes too
long, so plans die in the group chat. Success metrics: `docs/PROCESS.md` section 1.

## 1. Product
- **Vybe** (working name; final brand undecided). Bundle ID: `com.lohitaksh.Vybe`.
- A social app for discovering places and doing multi-spot Hangouts with friends.
- Audience: Gen Z college students (18 to 23) in Indian cities. Start: Pune, Kothrud. Low budget, spontaneous, friend groups.
- Tone: fun, reliable, mischievous friend with light meme humour ("Find your Vybe", "One more spot?"). UI text stays short.

## 2. Vocabulary
Use exactly, in code, comments and UI text.

| Use | Never use |
|---|---|
| Hangout | Plan, Trace, outing |
| Spot | Stop, Node |
| Remix | Fork, Make it yours |
| Picks (official Vybe Hangouts) | Featured, Curated |
| Start Hangout (the main button) | Go, Begin |

- **Hangout** is the only noun for the thing people browse, save, do and post. In the data (`docs/DATA-MODEL.md`): a Hangout is
  *Draft* or *Published*; each time someone does it, that run is *Live*, then *Done*, then maybe *Posted*; *Saved* is a bookmark,
  not a state.
- **Spot**: one place inside a Hangout. **Place**: the real venue (code word). **Remix**: your own editable copy of a Hangout.
- **Picks**: Hangouts the Vybe team has actually done and posted from the official Vybe account. They look a little different (Picks
  badge) but behave like any other post (like, comment, Save, Remix, Share).
- No "Organiser". No voting inside Hangouts. Polls live in group chats (later).

## 3. Phase 1: the whole frontend on sample data (no backend)
SwiftUI frontend for **every screen** on local sample data. The work is a pool of tasks (`docs/TASKS.md`); the earlier "feature
freeze Thu 5 Nov" is superseded (new date to be set after measuring speed: `docs/BEFORE-BUILD.md` 4). The complete screen list with
IDs is `docs/IA.md` section 4. A screen ID is a short code name used in the branch name (`t/sc-d1-discover-map`), the PR title
(`SC-D1: show pins on the map`) and the Figma frame.

- **Tabs (4):** **Discover**, **Community** (feed, friends and chat are built on sample social data; `docs/tasks/40-...`),
  **Profile**, and **Search** as a separate tab at the trailing end (never in the middle). Chat lives inside Community. Search is a
  search-role tab and the only place to find new things: no segment control, results ranked by the last non-Search tab.
- **Phase 1 screens** (`docs/IA.md` marks each with its phase): O1 to O4 onboarding · D1 Discover map, D2 pin preview card (an
  overlay, not a sheet, so the tab bar stays visible), D3 filters · HD1 Hangout detail, HD2 Spot sheet · S1 Search · PR1 Profile,
  PR2 Settings (edit name and photo, reset onboarding, about) · H1 Hangout live, H2 Mark visited, H3 summary · CM1 Community feed
  (a "Coming soon" state only if its task is not merged yet). Every data screen needs loading, empty and error states.
- **Flow:** open the app; onboarding not done: O1 to O4 then tabs. D1 pin › D2 › HD1; S1 result › HD1; PR1 saved Hangout › HD1;
  HD1 Spot › HD2; HD1 Start Hangout › H1 (H2 as a popup) › H3 › back to Discover. Share is the system share sheet; in version 1 the
  shared link opens a public **web page** (WEB1) so Android friends can see it and say "I'm in".
- **Phase 1 data:** a small local sample set in the app bundle, one JSON file per Hangout and per Place, using real Kothrud names.
  The verified full dataset is built after the vacation. Saved Hangouts persist on the device.

## 4. The full app (version 1, target 18 Dec 2026)
"Phase 1" and "Phase 2" are build order only: **everything in this section ships in version 1.** Phase 2 = backend, verification
and TestFlight. Data-level decisions: `docs/DATA-MODEL.md` section 7.

### Hangouts
- Fields: title, summary, tags (e.g. "good for groups"), vibe tags, budget per person (a range), best time, required time estimate,
  author, Spots in order. 2 to 10 Spots; Spots can be reordered and have notes.
- **Save** = bookmark someone else's Hangout (follows the author's edits). **Draft** = your own Hangout in progress; Remix always
  creates a Draft.
- Hangouts are created from scratch or by Remix. A Remix links to the original and credits its author; Remixes of Remixes are
  allowed, no depth limit.
- Remix credit: a Remix counts toward the original when it keeps at least 70% of the original's Spots, comes from a different person
  (counted once), and has been done and posted. Highly done and remixed Hangouts show on the zoomed-out map ("Done 40×, Remixed 12×").

### Doing and posting
- One person runs a Hangout on their phone (multi-person: revisit later). "Mark visited" is trusted, no location check.
- A Hangout can be posted when done, or partly done. Only visited Spots are shown. Minimum 2 visited Spots to post.
- Photos: asked for and nudged, but optional. Max 2 × the number of **visited** Spots.
- After posting: title, caption, photos, tags and visibility can change; Spots cannot. Remixed Hangouts cannot be posted until
  actually done.
- Post card: cover photo (or route mini-map), title, avatar and username, "3 of 5 Spots", budget, time taken, like, comment and Remix
  counts, Picks badge.

### Community tab
- Feed of posted Hangout cards: friends first, then newest; a trending section. Likes on posts and comments. Threaded comments; you
  delete your own and the poster can delete comments on their post.
- Save, share (to chat or outside the app) and Remix from a post. Picks appear in Discover and Community, for everyone.
- Find friends ("you might know": mutual friends) and chat live here.

### Accounts and profiles
- Unique usernames (follow big social media rules). Profile photo and bio optional. Date of birth and an 18+ confirmation at sign-up.
- Visibility rule A (like Instagram): a private profile makes all posts friends-only; public profiles choose per post, Public or
  Friends, changeable later.
- No deactivation. Account deletion is in-app (required by Apple); posts stay; photos may be removed (open question).

### Friends
- Mutual friends (request, then accept), like Facebook; no following. Max 500 friends. Requests can be cancelled; ignoring does not
  show as "declined". Friend lists are private; on someone's profile you see your mutual friends.
- Blocking hides the person everywhere: feed, search, comments and chat.

### Chat (inside Community)
- Friends only. Direct messages and groups. Groups are permanent friend groups (not one per Hangout), minimum 3 people; the admin
  removes members; any member can add their own friends, but anyone added by a non-friend must accept first ("Join" / "Leave and
  block"); groups can be renamed; new members do not see earlier messages.
- **Mute (approved by Lohitaksh):** the admin can mute a member from the ••• menu on their row in Group info. A muted person stays in
  the group and can read, but cannot send, add a photo, record a voice note or start a poll. The admin cannot be muted. Only the
  admin and the muted person see the "Muted" label.
- **Group photos (approved by Lohitaksh):** Group info has a Photos row that opens a grid of every photo sent in the group, newest
  first; tap one to open it full screen and swipe between them.
- Messages: text, photos (max 2 per message), shared Hangouts, links, voice notes. Delete for everyone and edit are allowed. Read
  receipts always on. No typing indicators or online status. Polls ("I'm in" / "Not for me") in the first version of chat.
- **Voice notes (approved by Lohitaksh):** hold the microphone to record, let go to send, slide left and let go to cancel; 2 minute
  cap (the note is sent when the cap is reached). A tap shorter than 1 second is thrown away.
- **Read receipts (approved by Lohitaksh):** "Seen" under your last message shows when another active, unblocked member has read
  the chat after it was sent (from each member's `lastReadAt`); until then it says "Delivered".

### Search, Places, Photos
- **Search:** every search for new things is in the Search tab: Hangouts, Places and people. One exception (approved by Lohitaksh):
  a small on-device filter (name or username, nothing sent anywhere) in lists of people you already have, New chat and the Friends
  hub. It is not a second search.
- **Places:** our own Place database, checked by the team, is the source of truth. Apple's Place ID is stored on each Place for live
  details; MapKit and Google data are never copied into our files. Users can suggest Places; the team reviews them (pending,
  approved, rejected).
- **Photos:** compressed on the phone before upload, location data (EXIF GPS) stripped. Team photos for Picks: each teammate gives a
  saved written OK, credit kept. User photos belong to the user, who grants Vybe a licence in the Terms.

### Safety
- Report anything (post, comment, user, chat message, Place); reports are anonymous. Block, report, filtering and in-app contact
  details are required by App Store Review Guideline 1.2. Moderation follows how big social apps do it (open questions).

### Offline
- Online app. When offline, screens keep showing the last loaded state, read-only, with no actions. (A small offline game is a later
  nice-to-have.)

### Safety defaults (accepted 3 Nov; reasons in `docs/RISKS.md`)
- New posts are **Friends** only; Public is opt-in with a one-line warning.
- Other people never see exact visit times: only the order, "3 of 5 Spots", a rounded duration ("about 3 h") and the day.
- A post appears at least **30 minutes** after the Hangout ends (options: 2 h, next day).
- A live Hangout is never visible to anyone else. The GPS track is never uploaded.
- Comments on a public post: Friends by default. Friend requests from people with no mutual friends go to an "Other" folder; at most
  30 requests a day and 100 pending.
- Settings: who can comment, who can send requests, who can add me to groups, show me in search.
- Report reasons include "photo of me without consent", "private address" and "impersonation". Nudity, self-harm and threats are
  hidden automatically on report; the self-harm flow shows Tele-MANAS 14416 and 112.
- Treks and waterfalls show a safety note; a monsoon banner runs June to September; a Place can be marked "closed by authorities".
- Deleted usernames are held for 30 days.

### Web page for Android friends (version 1)
iOS is about 5% of phones in India, so most friend groups include Android users. Every shared Hangout and post gets a public web page
(WEB1) with a WhatsApp preview, the Spots list and an "I'm in" button that works without an account. Hosted on Firebase Hosting's free
web.app address at first; opening the app from the link needs the paid Apple account. Details: `docs/ARCHITECTURE.md` 4b.

### Branding rule
The college where we launch (MIT-WPU) is used only in advertising. Its name never appears in the app, and the app collects no college
field.

## 5. Design rules
- Photo-led, visual, not text-heavy; Hangouts look tappable with photos. Must not look AI-generated. One main action per screen.
- Native iOS components (tab bar, sheets, nav bar, search); follow Apple's Human Interface Guidelines.
- Detail sheets (Spot, Filters, Mark visited) slide up over the map; the pin preview is a card, not a sheet.
- Hangout live: big text, glanceable while walking. Real Kothrud place names and words in previews, never lorem ipsum.
- Colours, fonts and spacing live only in `Theme` tokens (values to be decided; start with the system font). Never hard-code them.
- Design source: Figma file "05 · Full Prototype 3" (file key `meutmF6Wo2kJ2Iq1BeYQg0`). Read the frame before building a screen; if a
  frame is unclear, ask.

## 6. Technical decisions
Details: `docs/ARCHITECTURE.md` and `docs/adr/`.
- **iOS 26 minimum** (decided 3 Nov; iPhone XS/XR can't install). iPhone only, portrait only, light and dark appearance (decided 6 Nov).
- SwiftUI and `@Observable`. No third-party libraries (a backend SDK will need an exception; see open questions).
- Plain `Codable` structs with stable string IDs. **MVVM:** every screen is a `SomethingView` (layout only) plus a
  `SomethingViewModel` (`@Observable`, the screen's state and logic); data structs and repositories are the Model layer.
- Code names: `Hangout` (the blueprint: Spots, author, isPick) and `HangoutRun` (one person doing it: visited Spots, photos, times,
  visibility); both are "Hangout" in the UI. `Place` is the venue; `Spot` is a Place inside a Hangout.
- One `NavigationStack` per tab (plus one for onboarding and one inside each full-screen cover); typed `Route` enums carry IDs only;
  one `Router`.
- Shared `@Observable` stores and repositories are created once (`AppDependencies`) and passed to ViewModels through their `init`s
  (nothing is read from the SwiftUI Environment), so the data source (local JSON now, a server later) can change without touching
  screens. Core never imports Features; Features never import each other; shared views go in `Components`.
- Location: real permission; simulated movement for Hangout live so it demos at a desk.
- Signing: everyone uses the simulator; only Lohitaksh installs on the lab iPhone. Signing and project settings are never committed
  without his OK.

## 7. Folder layout
`Vybe/` (app wiring) + `VybeKit/` (local package: Models, Core, Design, Components, LocalData, one target per feature) + later a
`VybeRemote/` package + `backend/` (Phase 2) + `docs/` + `scripts/`. `AGENTS.md` and `CLAUDE.md` (exactly `@AGENTS.md`) sit at the
root. The full map and "where does X go?": `docs/ARCHITECTURE.md` section 3.2.

## 8. Content rules
- Real Pune places only. Real photos only (team photos with a credit). No AI images. Gemini or other AI may suggest ideas only; a
  human verifies every Place.
- Fields for every model, with JSON examples: `docs/DATA-MODEL.md`. Money is whole rupees as a min-max range; each photo has its own
  credit.
- **IDs:** team content `place-<slug>-<4 chars>` / `hangout-<slug>-<4 chars>`; user content a random UUID. IDs never change once set.
- Content is written in a shared Google Sheet, then converted to JSON by a script (K1). A content test must load every JSON file.
- Categories: see `docs/OPEN-QUESTIONS.md` (proposed list). No bars for now.
