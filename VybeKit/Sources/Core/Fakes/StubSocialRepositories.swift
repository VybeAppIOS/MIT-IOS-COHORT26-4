#if DEBUG
import Foundation
import Models

extension StubMode {
    /// Runs a call against the shared social store. `empty` answers with `empty`; `failing` throws offline;
    /// `neverReturns` waits forever (the loading state).
    func social<T: Sendable>(_ empty: T, _ body: () async throws -> T) async throws -> T {
        switch self {
        case .loaded: return try await body()
        case .empty: return empty
        case .failing: throw AppError.offline
        case .neverReturns:
            try await Task.sleep(for: .seconds(60 * 60 * 24 * 365))
            throw CancellationError()
        }
    }
}

/// A page of `items` starting at the cursor (the index of the first item).
func stubPage<T: Sendable>(_ items: [T], after cursor: String?, size: Int) throws -> Page<T> {
    let start = cursor.flatMap(Int.init) ?? 0
    guard start >= 0, start <= items.count else { throw AppError.invalid("Bad page cursor.") }
    let end = min(start + size, items.count)
    return Page(items: Array(items[start..<end]), nextCursor: end < items.count ? String(end) : nil)
}

public struct StubFeedRepository: FeedRepository {
    public let mode: StubMode
    public let store: SocialStubStore
    public static let pageSize = 3

    public init(mode: StubMode = .loaded, store: SocialStubStore = SocialStubStore()) {
        self.mode = mode
        self.store = store
    }

    public func feed(after cursor: String?) async throws -> Page<HangoutRun> {
        try await mode.social(Page(items: []), {
            try stubPage(await store.feedPosts(), after: cursor, size: Self.pageSize)
        })
    }

    public func trending() async throws -> [HangoutRun] { try await mode.social([], { await store.trendingPosts() }) }

    public func post(id: RunID) async throws -> HangoutRun {
        try await mode.social(nil, { try await store.post(id) }).orNotFound()
    }

    public func comments(for runID: RunID, after cursor: String?) async throws -> Page<Comment> {
        try await mode.social(Page(items: []), {
            try stubPage(await store.comments(for: runID), after: cursor, size: 5)
        })
    }

    public func likes() async throws -> Set<LikeTarget> { try await mode.social([], { await store.myLikes }) }

    public func like(_ target: LikeTarget) async throws {
        try await mode.social((), { try await store.setLike(target, liked: true) })
    }

    public func unlike(_ target: LikeTarget) async throws {
        try await mode.social((), { try await store.setLike(target, liked: false) })
    }

    public func addComment(to runID: RunID, text: String, replyingTo parentID: CommentID?) async throws -> Comment {
        try await mode.social(nil, { try await store.addComment(to: runID, text: text, parent: parentID) }).orNotFound()
    }

    public func deleteComment(_ id: CommentID) async throws {
        try await mode.social((), { try await store.deleteComment(id) })
    }

    public func activity(after cursor: String?) async throws -> Page<Activity> {
        try await mode.social(Page(items: []), { try stubPage(await store.activityItems(), after: cursor, size: 20) })
    }

    public func markActivityRead() async throws { try await mode.social((), { await store.markActivityRead() }) }
}

extension Optional {
    /// `.empty` stub mode answers `nil` for a single item: that is "not found".
    func orNotFound() throws -> Wrapped {
        guard let self else { throw AppError.notFound }
        return self
    }
}

public struct StubFriendsRepository: FriendsRepository {
    public let mode: StubMode
    public let store: SocialStubStore

    public init(mode: StubMode = .loaded, store: SocialStubStore = SocialStubStore()) {
        self.mode = mode
        self.store = store
    }

    public func friends() async throws -> [UserProfile] { try await mode.social([], { await store.friends() }) }

    public func requests() async throws -> FriendRequests {
        try await mode.social(FriendRequests(), { await store.requests() })
    }

    public func suggestions() async throws -> [UserProfile] {
        try await mode.social([], { await store.friendSuggestions() })
    }

    public func mutualFriends(with user: UserID) async throws -> [UserProfile] {
        try await mode.social([], { try await store.mutualFriends(with: user) })
    }

    public func sendRequest(to user: UserID) async throws -> FriendRequest {
        try await mode.social(nil, { try await store.sendRequest(to: user) }).orNotFound()
    }

    public func acceptRequest(from user: UserID) async throws {
        try await mode.social((), { try await store.acceptRequest(from: user) })
    }

    public func cancelRequest(to user: UserID) async throws {
        try await mode.social((), { try await store.cancelRequest(to: user) })
    }

    public func removeFriend(_ user: UserID) async throws {
        try await mode.social((), { try await store.removeFriend(user) })
    }
}

public struct StubChatRepository: ChatRepository {
    public let mode: StubMode
    public let store: SocialStubStore

    public init(mode: StubMode = .loaded, store: SocialStubStore = SocialStubStore()) {
        self.mode = mode
        self.store = store
    }

    public func conversations() async throws -> [Conversation] {
        try await mode.social([], { await store.myConversations() })
    }

    public func unreadCounts() async throws -> [ConversationID: Int] {
        try await mode.social([:], { await store.unreadCounts() })
    }

    public func messages(in id: ConversationID) -> AsyncThrowingStream<[Message], any Error> {
        let mode = mode
        let store = store
        return AsyncThrowingStream { continuation in
            let work = Task {
                switch mode {
                case .loaded:
                    do {
                        _ = try await store.messageList(in: id)
                    } catch {
                        continuation.finish(throwing: error)
                        return
                    }
                    let token = await store.subscribe(id, listener: continuation)
                    continuation.onTermination = { _ in Task { await store.unsubscribe(id, token: token) } }
                case .empty:
                    continuation.yield([])
                case .failing:
                    continuation.finish(throwing: AppError.offline)
                case .neverReturns:
                    break   // never yields: the loading state
                }
            }
            let previous = continuation.onTermination
            continuation.onTermination = { reason in
                work.cancel()
                previous?(reason)
            }
        }
    }

    public func send(_ payload: MessagePayload, in id: ConversationID) async throws -> Message {
        try await mode.social(nil, { try await store.send(payload, in: id) }).orNotFound()
    }

    public func edit(_ id: MessageID, text: String) async throws {
        try await mode.social((), { try await store.edit(id, text: text) })
    }

    public func delete(_ id: MessageID) async throws { try await mode.social((), { try await store.delete(id) }) }

    public func markRead(_ id: ConversationID) async throws {
        try await mode.social((), { try await store.markRead(id) })
    }

    public func vote(_ choice: PollChoice, on message: MessageID) async throws {
        try await mode.social((), { try await store.vote(choice, on: message) })
    }

    public func votes(for message: MessageID) async throws -> [PollVote] {
        try await mode.social([], { await store.votes(for: message) })
    }

    public func startChat(with user: UserID) async throws -> Conversation {
        try await mode.social(nil, { try await store.startChat(with: user) }).orNotFound()
    }

    public func createGroup(name: String, members: [UserID]) async throws -> Conversation {
        try await mode.social(nil, { try await store.createGroup(name: name, members: members) }).orNotFound()
    }

    public func rename(_ id: ConversationID, to name: String) async throws {
        try await mode.social((), { try await store.rename(id, to: name) })
    }

    public func add(_ members: [UserID], to id: ConversationID) async throws {
        try await mode.social((), { try await store.add(members, to: id) })
    }

    public func remove(_ member: UserID, from id: ConversationID) async throws {
        try await mode.social((), { try await store.remove(member, from: id) })
    }

    public func leave(_ id: ConversationID) async throws { try await mode.social((), { try await store.leave(id) }) }

    public func respondToInvitation(to id: ConversationID, accept: Bool) async throws {
        try await mode.social((), { try await store.respondToInvitation(to: id, accept: accept) })
    }
}

public struct StubSafetyRepository: SafetyRepository {
    public let mode: StubMode
    public let store: SocialStubStore

    public init(mode: StubMode = .loaded, store: SocialStubStore = SocialStubStore()) {
        self.mode = mode
        self.store = store
    }

    public func report(_ target: ReportTarget, reason: ReportReason, detail: String?) async throws -> Report {
        try await mode.social(nil, { try await store.report(target, reason: reason, detail: detail) }).orNotFound()
    }

    public func block(_ user: UserID) async throws { try await mode.social((), { try await store.block(user) }) }

    public func unblock(_ user: UserID) async throws { try await mode.social((), { await store.unblock(user) }) }

    public func blocked() async throws -> [UserProfile] { try await mode.social([], { await store.blockedProfiles() }) }
}

/// Sign-in stubs: no network and no real accounts. The email code that works is `123456`.
public struct StubAuthRepository: AuthRepository {
    public let mode: StubMode
    public let now: @Sendable () -> Date
    public static let workingEmailCode = "123456"

    public init(mode: StubMode = .loaded, now: @escaping @Sendable () -> Date = { SampleData.day }) {
        self.mode = mode
        self.now = now
    }

    public func signInWithApple() async throws -> UserProfile {
        try await mode.run(loaded: SampleSocialData.currentUser, empty: SampleSocialData.currentUser)
    }

    public func signInWithGoogle() async throws -> UserProfile {
        try await mode.run(loaded: SampleSocialData.currentUser, empty: SampleSocialData.currentUser)
    }

    public func sendEmailCode(to email: String) async throws {
        _ = try await mode.run(loaded: true, empty: true)
        guard email.contains("@"), email.contains(".") else { throw AppError.invalid("Enter a valid email address.") }
    }

    public func verifyEmailCode(_ code: String, email: String) async throws -> UserProfile {
        let user = try await mode.run(loaded: SampleSocialData.currentUser, empty: SampleSocialData.currentUser)
        guard code == Self.workingEmailCode else { throw AppError.invalid("That code is not right.") }
        return user
    }

    public func isUsernameAvailable(_ username: String) async throws -> Bool {
        let taken = SampleSocialData.people.contains { $0.username == username.lowercased() }
        return try await mode.run(loaded: !taken, empty: !taken)
    }

    public func completeAccount(username: String, dateOfBirth: Date, confirmed18: Bool) async throws -> UserProfile {
        _ = try await mode.run(loaded: true, empty: true)
        guard confirmed18 else { throw AppError.invalid("You must be 18 or older to use Vybe.") }
        let name = username.lowercased()
        let allowed = name.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "." || $0 == "_" }
        guard (3...20).contains(name.count), allowed else {
            throw AppError.invalid("Use 3 to 20 letters, numbers, dots or underscores.")
        }
        guard try await isUsernameAvailable(name) else { throw AppError.invalid("That username is taken.") }
        return UserProfile(id: UserID("user-sample-\(name)"), username: name, displayName: name, createdAt: now())
    }

    public func signOut() async throws { _ = try await mode.run(loaded: true, empty: true) }

    public func deleteAccount() async throws { _ = try await mode.run(loaded: true, empty: true) }
}

public struct StubAdminRepository: AdminRepository {
    public let mode: StubMode
    public let store: SocialStubStore

    public init(mode: StubMode = .loaded, store: SocialStubStore = SocialStubStore()) {
        self.mode = mode
        self.store = store
    }

    public func reports() async throws -> [Report] { try await mode.social([], { await store.allReports() }) }

    public func setStatus(_ status: ReportStatus, for report: ReportID) async throws {
        try await mode.social((), { try await store.setStatus(status, for: report) })
    }

    public func placeSuggestions() async throws -> [PlaceSuggestion] {
        try await mode.social([], { await store.allSuggestions() })
    }

    public func approve(_ id: PlaceSuggestionID, as place: Place) async throws {
        try await mode.social((), { try await store.approve(id, as: place) })
    }

    public func reject(_ id: PlaceSuggestionID, note: String) async throws {
        try await mode.social((), { try await store.reject(id, note: note) })
    }

    public func user(username: String) async throws -> UserProfile {
        try await mode.social(nil, { try await store.user(username: username) }).orNotFound()
    }

    public func ban(_ user: UserID) async throws {
        try await mode.social((), { try await store.setBanned(user, true) })
    }

    public func unban(_ user: UserID) async throws {
        try await mode.social((), { try await store.setBanned(user, false) })
    }
}
#endif
