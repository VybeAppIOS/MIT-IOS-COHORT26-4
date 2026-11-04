# Screen tasks: Community, Friends and Chat

Same rules as `docs/tasks/20-screens-start-discover-detail.md`. Everything runs on the **sample social
data and stub repositories** from F-7 (the backend comes later). Before any of these, read
`docs/RISKS.md` section 3 (safety defaults): **never show exact times**, posts are Friends-only by default,
blocked people disappear everywhere, and reporting is one tap away on every post, comment, profile and
message. Common dependencies: **F-4, F-5, F-7, F-9, DS-1/2/3**.

## Community (folder `CommunityFeature/`)

### SC-CM1 — Feed  `[L]`
- **Depends on:** common, CP-1, CP-6, DS-4
- **Read:** IA 2 (Community icons), 4 (CM1) · PRODUCT 4 (Community tab) · RISKS 3
- **Build:** `Feed/`: top bar icons → **Friends** (`.friends`), **bell** (`.activity`, dot when unread),
  **chat** (`.chats`, unread count). Sections: a **Picks** strip (`HangoutCard(.featured)`), then the feed of
  `PostCard`s (**friends first, then newest**), a **Trending** teaser (→ `.trending`). Pull to refresh;
  paging with `Page` cursors; actions: **like** (optimistic with rollback), comment (opens SC-CM3 as a local
  sheet), **Remix** (`presentCover(.editor(.remix))`), save, share, ••• (Report → `present(.report)`); tap a
  card → `.post(runID)`. The Community tab shows the combined unread badge from `BadgeStore`.
- **Done when:** tests: like then failure rolls back; friends-first ordering; paging; empty state ("Add
  friends to see their Hangouts here", button → `.friends`); stale/offline read-only.

### SC-CM2 — Post detail  `[L]`
- **Depends on:** common, CP-1, CP-2, CP-3, CP-6, CP-7, CP-9
- **Read:** IA 4 (CM2) · PRODUCT 4 (Doing and posting, Community) · RISKS 3
- **Build:** `PostDetail/`: photo gallery, author header (avatar, username, relationship), visited Spots
  with **order only** (no times), "3 of 5 Spots · about 3 h · ₹150–400", counts, actions (like, comment,
  **Remix**, save = saves the underlying Hangout, share), the first 3 comments with "View all" (→ SC-CM3), for
  a Pick the "Done 40× · Remixed 12×" line, "Friends only" note for friends-only posts, ••• (own post: **Edit**
  → `present(.editPost(runID))`; others: Report/Block).
- **Done when:** states incl. "This post is unavailable" (removed or blocked); tests for the actions.

### SC-CM3 — Comments  `[M]`
- **Depends on:** common, CP-7
- **Read:** IA 4 (CM3) · PRODUCT 4 (Community: threaded, likes on comments, delete)
- **Build:** `Comments/`: local large sheet with its own `NavigationStack`: threaded `CommentRow`s (reply
  indent up to 2 levels), like a comment, **Reply**, a composer pinned above the keyboard (≤500 characters),
  delete your own (post owner can delete any on their post), ••• → Report as a **push** (`Route.report`)
  inside the sheet. Empty: "Be the first to comment." Optimistic send with retry on failure.
- **Done when:** tests: reply nests under the right parent; delete shows "[deleted]"; ordering oldest first.

### SC-CM4 — Trending  `[S]`
- **Depends on:** common, CP-6
- **Build:** `Trending/`: "Trending this week near Kothrud" list of `PostCard`s (full list for the CM1 teaser),
  paging, empty state.
- **Done when:** paging test; states.

### SC-CM5 — Activity  `[M]`
- **Depends on:** common, CP-4, F-7 (BadgeStore)
- **Build:** `Activity/`: grouped Today / Earlier; rows for like, comment, reply, **friend request** (top row,
  inline **Accept / Ignore**, never shows "declined"), friend accepted, Remix credit. Unread dots; opening the
  screen marks read via `BadgeStore`; tap → the post, profile or Hangout. Empty: "Quiet here."
- **Done when:** tests: accept updates the list and badge; mark-as-read clears the dot.

## Friends (folder `FriendsFeature/`)

### SC-FR1 — Friends hub  `[M]`
- **Depends on:** common, CP-4, F-7
- **Read:** IA 4 (FR1) · PRODUCT 4 (Friends) · RISKS 3 (request limits)
- **Build:** `Hub/`: sections **Requests** (received, Accept/Ignore), an **Other requests** row (requests
  with no mutual friends; opens a list), **Sent** (Cancel), **You might know** (mutual friends only, with the
  reason "3 mutual friends"), **My friends** (alphabetical; menu: Remove, Block, Message). No search field here
  (all search is the Search tab). Shows the friend cap (500) message and the request limits (30 a day, 100
  pending) when reached.
- **Done when:** tests: accept/ignore/cancel; limits message; "Other" folder routing.

### SC-PR3 — Other person's profile  `[M]`
- **Depends on:** common, CP-6, CP-9
- **Read:** IA 4 (PR3) · RISKS 3 · DATA-MODEL 3 (privacy rules)
- **Build:** `OtherProfile/`: `ProfileHeader` with the right **relationship button** (Add friend → Requested;
  Respond; Friends; blocked: "Not available"); **private gate** (a private profile shows only name, photo and
  "Friends only"); posts grid (only what the viewer may see); mutual friends row (→ `.mutualFriends`); ••• Block
  (SC-R2 flow) and Report; **Message** (friends only → open the DM).
- **Done when:** previews for every relationship state; tests for the gate and for blocked.

### SC-PR7 — Mutual friends  `[S]`
- **Depends on:** common, CP-4
- **Build:** `MutualFriends/`: list of mutual friends (tap → `.profile`), empty state.
- **Done when:** states.

## Chat (folder `ChatFeature/`)

### SC-CH1 — Chats list  `[M]`
- **Depends on:** common, CP-4, F-7
- **Read:** IA 4 (CH1) · PRODUCT 4 (Chat)
- **Build:** `List/`: rows with avatar (or `AvatarStack` for groups), name, last-message preview (text, "Photo",
  "Voice note", "Hangout"), time, unread badge; **new chat** button (opens SC-CH3 as a local sheet); empty state;
  offline = read-only; tap → `.conversation(id)`.
- **Done when:** tests for preview text per payload kind and for unread counts.

### SC-CH2 — Conversation  `[L]`
- **Depends on:** common, CP-8, F-15 (voice), F-13 (photos), SC-CH6
- **Read:** IA 4 (CH2) · PRODUCT 4 (Chat: all message types, edit/delete, read receipts always on) · RISKS 3
- **Build:** `Conversation/`: message list (`MessageBubble`s, grouped, newest at the bottom, scroll to latest);
  a composer with text, **photos (max 2 per message)**, **voice note** (hold to record, slide to cancel, 2
  minute cap), a "+" menu for **Hangout** (pick from Saved) and **Poll** (→ SC-CH6); long-press a message:
  **Edit** (own text), **Delete for everyone**, Copy, Report (push); **read receipts always on** ("Seen");
  tap a Hangout card → `.hangout(id)`; links show a small "Be careful with links" note; group header →
  `.groupInfo`, DM header → profile. Incoming messages arrive through the `AsyncStream` (the stub sends one
  after 2 s). Offline: read-only, composer disabled. Blocked person in a group: their messages hidden for you.
- **Done when:** tests: send/edit/delete update state; read receipt logic; poll vote; voice cap; the stream
  cancels when the screen disappears.

### SC-CH3 — New chat or group  `[M]`
- **Depends on:** common, CP-4
- **Build:** `NewChat/`: local sheet; pick friends (multi-select). One friend → a DM; two or more → a group
  (**minimum 3 people including you**) with a name field; Create → opens the conversation.
- **Done when:** tests: group below 3 is blocked with a message; DM reuses an existing conversation.

### SC-CH4 — Group info  `[M]`
- **Depends on:** common, CP-4
- **Build:** `GroupInfo/`: name (admin edits), members with roles, **add members** (your friends; a non-friend
  of the added person must accept first → their invitation is SC-CH7), **remove** (admin only), **leave**
  (confirm; if the admin leaves, the oldest member becomes admin; below 3 members the group becomes
  read-only with a note).
- **Done when:** tests for admin handover and the below-3 rule.

### SC-CH5 — Share to…  `[M]`
- **Depends on:** common, CP-1, CP-4
- **Read:** ARCHITECTURE 2.6 (`Sheet.share`) · IA 4 (CH5)
- **Build:** `ShareSheet/`: opened with `router.present(.share(item))` from Hangout detail and post detail;
  friends and groups at the top (multi-select, **Send**), plus **More…** (system `ShareLink`, for WhatsApp).
  Sending posts a Hangout message card in each chat and shows a confirmation.
- **Done when:** tests: sending to 2 chats creates 2 Hangout messages; More… present.

### SC-CH6 — Poll composer  `[S]`
- **Depends on:** common, CP-8
- **Build:** `Poll/`: local sheet in the conversation: a question and the two fixed answers **"I'm in"** and
  **"Not for me"**; Send posts a poll message. (Voting happens in chat only; never inside a Hangout.)
- **Done when:** tests: empty question disabled; the options are exactly the two labels.

### SC-CH7 — Group invitation  `[S]`
- **Depends on:** common, CP-4
- **Read:** RISKS 3 (added by a non-friend) · IA 4 (CH7)
- **Build:** `Invitation/`: opened with `Sheet.groupInvitation(id)`: "Alex added you to Kothrud Crew" with the
  member avatars and **Join** or **Leave and block**.
- **Done when:** tests: Join activates the membership; Leave and block blocks the adder and removes the invite.
