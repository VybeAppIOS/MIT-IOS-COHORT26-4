#if DEBUG
import Foundation
import Models

/// The shared memory behind every social stub (feed, friends, chat, safety, admin). One store, so a like in the feed
/// also shows on the post, a block hides the person everywhere, and a sent message reaches every listener.
/// Starts from `SampleSocialData`; the stubs change it the way a backend would.
public actor SocialStubStore {
    typealias Listener = AsyncThrowingStream<[Message], any Error>.Continuation

    let currentUserID: UserID
    let now: @Sendable () -> Date
    let makeID: @Sendable () -> String
    let simulateIncoming: Bool

    var people = SampleSocialData.people
    var friendIDs = SampleSocialData.myFriendIDs
    var received = SampleSocialData.receivedRequests
    var other = SampleSocialData.otherRequests
    var sent = SampleSocialData.sentRequests
    var blockedIDs: Set<UserID> = []
    var bannedIDs: Set<UserID> = []
    var hiddenTargets: Set<ReportTarget> = []
    var posts = SampleSocialData.posts
    var comments = SampleSocialData.comments
    var myLikes: Set<LikeTarget> = [.run("run-sample-3")]
    var activity = SampleSocialData.activity
    var conversations = SampleSocialData.conversations
    /// Groups I was invited to and have not answered. They stay out of my conversations until I join.
    var pendingIDs = SampleSocialData.pendingInvitationIDs
    var addedBy = SampleSocialData.addedBy
    var joinedAt: [ConversationID: [UserID: Date]] = [:]
    /// Who is muted, per group.
    var mutedAt: [ConversationID: [UserID: Date]] = [:]
    var messages = SampleSocialData.messages
    var lastRead = SampleSocialData.lastRead
    /// When each other person last read a chat (what "Seen" is worked out from).
    var othersLastRead = SampleSocialData.othersLastRead
    var votes = SampleSocialData.pollVotes
    var reports = SampleSocialData.reports
    var suggestions = SampleSocialData.placeSuggestions
    var listeners: [ConversationID: [UUID: Listener]] = [:]
    var simulated: Set<ConversationID> = []

    public init(
        simulateIncomingMessages: Bool = false, mutedIn mutedGroups: Set<ConversationID> = [],
        now: @escaping @Sendable () -> Date = { SampleData.day },
        makeID: @escaping @Sendable () -> String = { UUID().uuidString.lowercased() }
    ) {
        currentUserID = SampleSocialData.currentUser.id
        simulateIncoming = simulateIncomingMessages
        self.now = now
        self.makeID = makeID
        for group in mutedGroups { mutedAt[group, default: [:]][currentUserID] = now() }
    }

    // MARK: Visibility (blocking and hiding are applied here, like a backend would)

    func isHidden(authoredBy user: UserID) -> Bool {
        blockedIDs.contains(user) || bannedIDs.contains(user)
    }

    func canSee(_ post: HangoutRun) -> Bool {
        if isHidden(authoredBy: post.runnerID) || hiddenTargets.contains(.run(post.id)) { return false }
        return post.audience == .public || post.runnerID == currentUserID || friendIDs.contains(post.runnerID)
    }

    func visiblePosts() -> [HangoutRun] { posts.filter(canSee) }

    func profile(_ id: UserID) -> UserProfile? { people.first { $0.id == id } }

    func requireProfile(_ id: UserID) throws -> UserProfile {
        guard let found = profile(id) else { throw AppError.notFound }
        return found
    }

    // MARK: Feed

    func feedPosts() -> [HangoutRun] {
        visiblePosts().sorted {
            let left = ($0.runnerID == currentUserID || friendIDs.contains($0.runnerID)) ? 0 : 1
            let right = ($1.runnerID == currentUserID || friendIDs.contains($1.runnerID)) ? 0 : 1
            return (left, $1.postedAt ?? .distantPast) < (right, $0.postedAt ?? .distantPast)
        }
    }

    func trendingPosts() -> [HangoutRun] {
        Array(visiblePosts().filter { $0.audience == .public }.sorted { $0.likeCount > $1.likeCount }.prefix(5))
    }

    func post(_ id: RunID) throws -> HangoutRun {
        guard let found = visiblePosts().first(where: { $0.id == id }) else { throw AppError.notFound }
        return found
    }

    func comments(for runID: RunID) throws -> [Comment] {
        _ = try post(runID)
        return comments.filter {
            $0.runID == runID && !isHidden(authoredBy: $0.authorID) && !hiddenTargets.contains(.comment($0.id))
        }.sorted { $0.createdAt < $1.createdAt }
    }

    func setLike(_ target: LikeTarget, liked: Bool) throws {
        switch target {
        case .run(let id): _ = try post(id)
        case .comment(let id): guard comments.contains(where: { $0.id == id }) else { throw AppError.notFound }
        }
        guard liked != myLikes.contains(target) else { return }   // liking twice changes nothing
        if liked { myLikes.insert(target) } else { myLikes.remove(target) }
        let change = liked ? 1 : -1
        switch target {
        case .run(let id):
            if let index = posts.firstIndex(where: { $0.id == id }) { posts[index].likeCount += change }
        case .comment(let id):
            if let index = comments.firstIndex(where: { $0.id == id }) { comments[index].likeCount += change }
        }
    }

    func addComment(to runID: RunID, text: String, parent: CommentID?) throws -> Comment {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.invalid("Write something first.") }
        _ = try post(runID)
        if let parent, !comments.contains(where: { $0.id == parent && $0.runID == runID }) { throw AppError.notFound }
        let created = Comment(id: CommentID(makeID()), runID: runID, authorID: currentUserID, parentID: parent,
                              text: trimmed, createdAt: now())
        comments.append(created)
        if let index = posts.firstIndex(where: { $0.id == runID }) { posts[index].commentCount += 1 }
        return created
    }

    func deleteComment(_ id: CommentID) throws {
        guard let index = comments.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        let ownsPost = posts.first { $0.id == comments[index].runID }?.runnerID == currentUserID
        guard comments[index].authorID == currentUserID || ownsPost else {
            throw AppError.invalid("You can only delete your own comments.")
        }
        comments[index].text = ""
        comments[index].deletedAt = now()
    }

    func activityItems() -> [Activity] { activity.sorted { $0.createdAt > $1.createdAt } }

    func markActivityRead() {
        let stamp = now()
        activity = activity.map { var item = $0; item.readAt = item.readAt ?? stamp; return item }
    }

    // MARK: Friends

    func friends() -> [UserProfile] { friendIDs.compactMap(profile).filter { !isHidden(authoredBy: $0.id) } }

    func requests() -> FriendRequests {
        FriendRequests(received: received.filter { !isHidden(authoredBy: $0.fromID) }, sent: sent,
                       other: other.filter { !isHidden(authoredBy: $0.fromID) })
    }

    func friendSuggestions() -> [UserProfile] {
        let asked = Set(sent.map(\.toID) + received.map(\.fromID) + other.map(\.fromID))
        return people.filter {
            $0.id != currentUserID && !friendIDs.contains($0.id) && !isHidden(authoredBy: $0.id)
                && !asked.contains($0.id)
        }
    }

    /// Sample people do not have friend lists, so every other person "shares" the same two of my friends.
    func mutualFriends(with user: UserID) throws -> [UserProfile] {
        _ = try requireProfile(user)
        return friendIDs.filter { $0 != user }.prefix(2).compactMap(profile)
    }

    func sendRequest(to user: UserID) throws -> FriendRequest {
        _ = try requireProfile(user)
        guard user != currentUserID else { throw AppError.invalid("You cannot add yourself.") }
        guard !isHidden(authoredBy: user) else { throw AppError.invalid("You cannot add this person.") }
        guard !friendIDs.contains(user) else { throw AppError.invalid("You are already friends.") }
        if let existing = sent.first(where: { $0.toID == user }) { return existing }
        let request = FriendRequest(fromID: currentUserID, toID: user, createdAt: now())
        sent.append(request)
        return request
    }

    func acceptRequest(from user: UserID) throws {
        guard received.contains(where: { $0.fromID == user }) || other.contains(where: { $0.fromID == user }) else {
            throw AppError.notFound
        }
        received.removeAll { $0.fromID == user }
        other.removeAll { $0.fromID == user }
        if !friendIDs.contains(user) { friendIDs.append(user) }
    }

    func cancelRequest(to user: UserID) throws {
        guard sent.contains(where: { $0.toID == user }) else { throw AppError.notFound }
        sent.removeAll { $0.toID == user }
    }

    func removeFriend(_ user: UserID) throws {
        guard friendIDs.contains(user) else { throw AppError.notFound }
        friendIDs.removeAll { $0 == user }
    }

    // MARK: Safety

    func report(_ target: ReportTarget, reason: ReportReason, detail: String?) throws -> Report {
        let owner: UserID? = switch target {
        case .run(let id): posts.first { $0.id == id }?.runnerID
        case .comment(let id): comments.first { $0.id == id }?.authorID
        case .message(let id): messages.first { $0.id == id }?.senderID
        case .user(let id): id
        case .place, .hangout: nil
        }
        let filed = Report(id: ReportID(makeID()), reporterID: currentUserID, target: target, targetOwnerID: owner,
                           reason: reason, detail: detail, createdAt: now())
        reports.append(filed)
        if reason.hidesContentImmediately { hiddenTargets.insert(target) }
        return filed
    }

    func block(_ user: UserID) throws {
        _ = try requireProfile(user)
        guard user != currentUserID else { throw AppError.invalid("You cannot block yourself.") }
        blockedIDs.insert(user)
        friendIDs.removeAll { $0 == user }
        sent.removeAll { $0.toID == user }
    }

    func unblock(_ user: UserID) { blockedIDs.remove(user) }

    func blockedProfiles() -> [UserProfile] { blockedIDs.compactMap(profile).sorted { $0.username < $1.username } }

    // MARK: Admin

    func allReports() -> [Report] { reports.sorted { $0.createdAt > $1.createdAt } }

    func setStatus(_ status: ReportStatus, for id: ReportID) throws {
        guard let index = reports.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        reports[index].status = status
    }

    func allSuggestions() -> [PlaceSuggestion] {
        func rank(_ suggestion: PlaceSuggestion) -> Int { suggestion.status == .pending ? 0 : 1 }
        return suggestions.sorted { (rank($0), $0.createdAt) < (rank($1), $1.createdAt) }
    }

    func approve(_ id: PlaceSuggestionID, as place: Place) throws {
        guard let index = suggestions.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        suggestions[index].status = .approved
        suggestions[index].approvedPlaceID = place.id
        suggestions[index].reviewedAt = now()
    }

    func reject(_ id: PlaceSuggestionID, note: String) throws {
        guard let index = suggestions.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        guard !note.trimmingCharacters(in: .whitespaces).isEmpty else { throw AppError.invalid("Add a note.") }
        suggestions[index].status = .rejected
        suggestions[index].reviewNote = note
        suggestions[index].reviewedAt = now()
    }

    func user(username: String) throws -> UserProfile {
        guard let found = people.first(where: { $0.username == username.lowercased() }) else { throw AppError.notFound }
        return found
    }

    func setBanned(_ user: UserID, _ banned: Bool) throws {
        _ = try requireProfile(user)
        if banned { bannedIDs.insert(user) } else { bannedIDs.remove(user) }
    }

    func isUsernameTaken(_ username: String) -> Bool { people.contains { $0.username == username.lowercased() } }
}
#endif
