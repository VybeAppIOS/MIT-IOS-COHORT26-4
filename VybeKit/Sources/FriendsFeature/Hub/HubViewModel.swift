import Core
import Foundation
import Models
import Observation

/// The limits from `docs/RISKS.md` 3: 500 friends, 100 requests waiting, 30 requests a day.
enum FriendLimits {
    static let friends = 500
    static let pendingRequests = 100
    static let requestsPerDay = 30

    enum Reached: Equatable {
        case friends
        case pending
        case today
    }

    /// The first limit that is reached, if any.
    static func reached(friendCount: Int, pendingCount: Int, sentToday: Int) -> Reached? {
        if friendCount >= friends { return .friends }
        if pendingCount >= pendingRequests { return .pending }
        if sentToday >= requestsPerDay { return .today }
        return nil
    }
}

/// The view-ready values of the Friends hub (never a raw model).
struct HubContent: Equatable {
    var requests: [PersonRowData]
    var otherRequests: [PersonRowData]
    var sent: [PersonRowData]
    var suggestions: [PersonRowData]
    var friends: [PersonRowData]
    var limit: FriendLimits.Reached?
}

/// Friends hub (SC-FR1): requests to answer, requests with no mutual friends ("Other"), requests you sent,
/// people you might know (mutual friends only) and your friends, A to Z. A small search field filters your friends on
/// the phone (name or username); while it is used the other sections are hidden. Finding new people is another tab.
@MainActor @Observable
final class HubViewModel {
    private(set) var state: LoadState<HubContent> = .loading
    /// True while the "Other requests" list is open (a local sheet).
    var showsOtherRequests = false
    /// What the person typed in the search field. Filters the friends on the phone, with no repository call.
    var searchText = ""
    /// The friend waiting for a "Remove?" answer.
    private(set) var removingID: UserID?
    /// A short message to show once. The View clears it.
    var notice: String?

    private let friends: any FriendsRepository
    private let profiles: any ProfileRepository
    private let session: SessionStore
    private let router: Router
    private let now: @Sendable () -> Date
    private var ignored: Set<UserID> = []
    private var people: [UserID: UserProfile] = [:]
    private var raw: Loaded?
    private var hasLoaded = false

    private struct Loaded {
        var friends: [UserProfile]
        var requests: FriendRequests
        var suggestions: [(profile: UserProfile, mutual: Int)]
    }

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        friends: any FriendsRepository, profiles: any ProfileRepository, session: SessionStore, router: Router,
        now: @escaping @Sendable () -> Date
    ) {
        self.friends = friends
        self.profiles = profiles
        self.session = session
        self.router = router
        self.now = now
    }

    // MARK: Words

    var title: String { String(localized: "friends.hub.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "friends.hub.empty", bundle: #bundle) }
    var emptyAction: String { String(localized: "friends.hub.emptyAction", bundle: #bundle) }
    var requestsTitle: String { String(localized: "friends.hub.requests", bundle: #bundle) }
    var sentTitle: String { String(localized: "friends.hub.sent", bundle: #bundle) }
    var suggestionsTitle: String { String(localized: "friends.hub.suggestions", bundle: #bundle) }
    var friendsTitle: String { String(localized: "friends.hub.friends", bundle: #bundle) }
    var acceptLabel: String { String(localized: "friends.hub.accept", bundle: #bundle) }
    var ignoreLabel: String { String(localized: "friends.hub.ignore", bundle: #bundle) }
    var cancelRequestLabel: String { String(localized: "friends.hub.cancelRequest", bundle: #bundle) }
    var addLabel: String { String(localized: "friends.hub.add", bundle: #bundle) }
    var moreLabel: String { String(localized: "friends.hub.more", bundle: #bundle) }
    var messageLabel: String { String(localized: "friends.hub.message", bundle: #bundle) }
    var removeLabel: String { String(localized: "friends.hub.remove", bundle: #bundle) }
    var blockLabel: String { String(localized: "friends.hub.block", bundle: #bundle) }
    var cancelLabel: String { String(localized: "friends.hub.cancel", bundle: #bundle) }
    var doneLabel: String { String(localized: "friends.hub.done", bundle: #bundle) }
    var okLabel: String { String(localized: "friends.hub.ok", bundle: #bundle) }
    var searchPrompt: String { String(localized: "friends.hub.searchPrompt", bundle: #bundle) }
    var otherTitle: String { String(localized: "friends.hub.otherTitle", bundle: #bundle) }

    func otherRequestsText(_ count: Int) -> String {
        String(localized: "friends.hub.other \(count)", bundle: #bundle)
    }

    var removeTitle: String {
        let name = removingID.flatMap { people[$0]?.displayName } ?? ""
        return String(localized: "friends.hub.removeTitle \(name)", bundle: #bundle)
    }

    /// The message shown when a limit stops new requests; nil while there is room.
    func limitText(_ limit: FriendLimits.Reached) -> String {
        switch limit {
        case .friends: String(localized: "friends.hub.limit.friends \(FriendLimits.friends)", bundle: #bundle)
        case .pending: String(localized: "friends.hub.limit.pending \(FriendLimits.pendingRequests)", bundle: #bundle)
        case .today: String(localized: "friends.hub.limit.today \(FriendLimits.requestsPerDay)", bundle: #bundle)
        }
    }

    // MARK: Search

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// True while something is typed in the search field. The View then shows only `matchingFriends`.
    var isSearching: Bool { !query.isEmpty }

    /// The friends whose name or username match what was typed. Case and accents are ignored.
    func matchingFriends(in content: HubContent) -> [PersonRowData] {
        guard isSearching else { return content.friends }
        return content.friends.filter {
            $0.name.localizedStandardContains(query) || $0.username.localizedStandardContains(query)
        }
    }

    // MARK: Loading

    /// Called by `.task`. Runs once; `.task` runs again whenever the screen reappears.
    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    /// Pull to refresh and the Retry button.
    func reload() async { await fetch() }

    private func fetch() async {
        do {
            async let friendList = friends.friends()
            async let requests = friends.requests()
            async let suggestions = friends.suggestions()
            let (list, pending, suggested) = try await (friendList, requests, suggestions)
            var withMutual: [(profile: UserProfile, mutual: Int)] = []
            for person in suggested where !session.isBlocked(person.id) {
                let count = (try? await friends.mutualFriends(with: person.id).count) ?? 0
                if count > 0 { withMutual.append((person, count)) }   // "You might know" needs a mutual friend
            }
            raw = Loaded(friends: list, requests: pending, suggestions: withMutual)
            await loadNames(pending)
            publish()
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))   // only a first load can fail
            }
        }
    }

    private func loadNames(_ requests: FriendRequests) async {
        let ids = Set((requests.received + requests.other).map(\.fromID) + requests.sent.map(\.toID))
        for id in ids where people[id] == nil { people[id] = try? await profiles.profile(id: id) }
    }

    private func publish() {
        guard let raw else { return }
        for person in raw.friends + raw.suggestions.map(\.profile) { people[person.id] = person }
        func rows(_ ids: [UserID]) -> [PersonRowData] {
            ids.compactMap { id in people[id].map { PersonRowData($0) } }.filter { !session.isBlocked($0.id) }
        }
        let received = raw.requests.received.map(\.fromID).filter { !ignored.contains($0) }
        let other = raw.requests.other.map(\.fromID).filter { !ignored.contains($0) }
        let sentIDs = raw.requests.sent.map(\.toID)
        let content = HubContent(
            requests: rows(received), otherRequests: rows(other), sent: rows(sentIDs),
            suggestions: raw.suggestions.filter { !sentIDs.contains($0.profile.id) }.map { suggestion in
                let reason = String(localized: "friends.hub.mutual \(suggestion.mutual)", bundle: #bundle)
                return PersonRowData(suggestion.profile, subtitle: reason)
            },
            friends: raw.friends.filter { !session.isBlocked($0.id) }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                .map { PersonRowData($0) },
            limit: currentLimit())
        let isEmpty = content.requests.isEmpty && content.otherRequests.isEmpty && content.sent.isEmpty
            && content.suggestions.isEmpty && content.friends.isEmpty
        state = isEmpty ? .empty : .loaded(content)
    }

    private func currentLimit() -> FriendLimits.Reached? {
        guard let raw else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        let today = raw.requests.sent.filter { calendar.isDate($0.createdAt, inSameDayAs: now()) }.count
        return FriendLimits.reached(
            friendCount: raw.friends.count, pendingCount: raw.requests.sent.count, sentToday: today)
    }

    // MARK: Taps

    func personTapped(_ id: UserID) { router.open(.profile(id)) }
    func otherRequestsTapped() { showsOtherRequests = true }
    func messageTapped(_ id: UserID) {
        guard let myID = session.currentUser?.id else { return }
        router.open(.conversation(.dm(myID, id)))
    }
    func blockTapped(_ id: UserID) { router.present(.blockConfirm(id)) }
    func findPeopleTapped() { router.show(nil, in: .search) }

    func acceptTapped(_ id: UserID) async {
        await perform { try await self.friends.acceptRequest(from: id) }
    }

    /// Ignore hides the request on this screen. Nobody is told.
    func ignoreTapped(_ id: UserID) {
        ignored.insert(id)
        publish()
    }

    func cancelRequestTapped(_ id: UserID) async {
        await perform { try await self.friends.cancelRequest(to: id) }
    }

    func addTapped(_ id: UserID) async {
        guard case .loaded(let content, _) = state, content.limit == nil else { return }
        await perform { _ = try await self.friends.sendRequest(to: id) }
    }

    func removeTapped(_ id: UserID) { removingID = id }
    func cancelRemove() { removingID = nil }

    func confirmRemove() async {
        guard let id = removingID else { return }
        removingID = nil
        await perform { try await self.friends.removeFriend(id) }
    }

    /// Runs a change, then reloads the lists so every section is right. A failed change shows a message.
    private func perform(_ change: () async throws -> Void) async {
        do {
            try await change()
            await fetch()
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }
}
