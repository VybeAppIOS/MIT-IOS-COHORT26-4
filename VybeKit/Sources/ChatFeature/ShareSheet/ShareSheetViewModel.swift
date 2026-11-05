import Core
import Foundation
import Models
import Observation

/// A friend or a group the Hangout can be sent to.
struct ShareTarget: Identifiable, Equatable {
    enum Kind: Equatable {
        case friend(UserID)
        case group(ConversationID)
    }

    let id: String
    let name: String
    let kind: Kind
}

/// The view-ready values of the Share sheet (never a raw model).
struct ShareContent: Equatable {
    let groups: [ShareTarget]
    let friends: [ShareTarget]
}

/// Share to… (SC-CH5): pick friends and groups, then Send. Each chosen chat gets a Hangout card. "More…" is the
/// system share sheet (for WhatsApp). Opened with `router.present(.share(item))`.
@MainActor @Observable
final class ShareSheetViewModel {
    private(set) var state: LoadState<ShareContent> = .loading
    private(set) var selected: [String] = []
    private(set) var isSending = false
    /// What More… shares: the Hangout's title and "find it on Vybe". Nil until the Hangout is known.
    private(set) var shareText: String?
    /// How many chats the last Send reached (the confirmation shows it).
    private(set) var sentCount: Int?
    /// A short message to show once. The View clears it.
    var notice: String?

    private let item: ShareItem
    private let chat: any ChatRepository
    private let friends: any FriendsRepository
    private let hangouts: any HangoutRepository
    private let feed: any FeedRepository
    private let session: SessionStore
    private let network: NetworkMonitor
    private let router: Router
    private var hangoutID: HangoutID?
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        item: ShareItem, chat: any ChatRepository, friends: any FriendsRepository, hangouts: any HangoutRepository,
        feed: any FeedRepository, session: SessionStore, network: NetworkMonitor, router: Router
    ) {
        self.item = item
        self.chat = chat
        self.friends = friends
        self.hangouts = hangouts
        self.feed = feed
        self.session = session
        self.network = network
        self.router = router
    }

    // MARK: Words

    var title: String { String(localized: "chat.share.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "chat.share.empty", bundle: #bundle) }
    var sendLabel: String { String(localized: "chat.share.send", bundle: #bundle) }
    var cancelLabel: String { String(localized: "chat.share.cancel", bundle: #bundle) }
    var moreLabel: String { String(localized: "chat.share.more", bundle: #bundle) }
    var groupsHeader: String { String(localized: "chat.share.groups", bundle: #bundle) }
    var friendsHeader: String { String(localized: "chat.share.friends", bundle: #bundle) }
    var okLabel: String { String(localized: "chat.share.ok", bundle: #bundle) }
    var isOffline: Bool { network.isOffline }

    var sentText: String? {
        sentCount.map { String(localized: "chat.share.sent \($0)", bundle: #bundle) }
    }

    var canSend: Bool { !selected.isEmpty && !isSending && !network.isOffline && hangoutID != nil }

    func isSelected(_ id: String) -> Bool { selected.contains(id) }

    func toggle(_ id: String) {
        if let index = selected.firstIndex(of: id) { selected.remove(at: index) } else { selected.append(id) }
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
            hangoutID = try await resolveHangout()
            if let hangoutID, let hangout = try? await hangouts.hangout(id: hangoutID) {
                shareText = String(localized: "chat.share.text \(hangout.title)", bundle: #bundle)
            }
            async let groupList = chat.conversations()
            async let friendList = friends.friends()
            let (conversations, people) = try await (groupList, friendList)
            let groups = conversations.filter { $0.kind == .group }.map {
                ShareTarget(id: "group:\($0.id.rawValue)", name: $0.name ?? "", kind: .group($0.id))
            }
            let friendTargets = people.filter { !session.isBlocked($0.id) }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                .map { ShareTarget(id: "friend:\($0.id.rawValue)", name: $0.displayName, kind: .friend($0.id)) }
            state = groups.isEmpty && friendTargets.isEmpty
                ? .empty : .loaded(ShareContent(groups: groups, friends: friendTargets))
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

    /// A Hangout is shared as is; a post is shared as the Hangout behind it.
    private func resolveHangout() async throws -> HangoutID {
        switch item {
        case .hangout(let id): id
        case .post(let id): try await feed.post(id: id).hangoutID
        }
    }

    // MARK: Actions

    func cancelTapped() { router.dismissSheet() }

    /// Sends a Hangout card to every chosen chat. A friend you have not written to yet gets a new direct message.
    func sendTapped() async {
        guard canSend, let hangoutID, case .loaded(let content, _) = state else { return }
        isSending = true
        defer { isSending = false }
        let chosen = (content.groups + content.friends).filter { selected.contains($0.id) }
        var sent = 0
        for target in chosen {
            do {
                let id: ConversationID
                switch target.kind {
                case .group(let groupID): id = groupID
                case .friend(let friendID): id = try await chat.startChat(with: friendID).id
                }
                _ = try await chat.send(.hangout(hangoutID), in: id)
                sent += 1
            } catch is CancellationError {
                return
            } catch {
                notice = AppError(error).message   // the chats that worked stay sent; the rest stay picked
            }
        }
        sentCount = sent
        if sent == chosen.count { router.dismissSheet() }
    }
}
