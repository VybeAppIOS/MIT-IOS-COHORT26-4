import Core
import Foundation
import Models
import Observation

/// One row of the Chats list, ready to draw.
struct ChatRowData: Identifiable, Equatable {
    let id: ConversationID
    let title: String
    /// "Alex: See you at 5" in a group, "You: Thanks" for your own message, or "No messages yet".
    let preview: String
    let timeText: String
    let unreadCount: Int
    let isGroup: Bool
    /// The names behind the avatar (one for a direct message, up to three for a group).
    let memberNames: [String]
}

/// The view-ready values of the Chats list (never a raw model).
struct ChatListContent: Equatable {
    let rows: [ChatRowData]
}

/// Builds the New chat sheet's ViewModel (made in `ChatScreens`, so this screen knows nothing of its parts).
typealias NewChatFactory = @MainActor (@escaping @MainActor (NewChatExit) -> Void) -> NewChatViewModel

/// Chats list (SC-CH1): every conversation, newest first, with the last message, the time and the unread count.
@MainActor @Observable
final class ListViewModel {
    private(set) var state: LoadState<ChatListContent> = .loading
    /// True while the New chat sheet (SC-CH3) is open.
    var isShowingNewChat = false

    private let chat: any ChatRepository
    private let profiles: any ProfileRepository
    private let session: SessionStore
    private let badges: BadgeStore
    private let network: NetworkMonitor
    private let router: Router
    private let now: @Sendable () -> Date
    private let makeNewChat: NewChatFactory
    private var people = ChatPeople()
    private var openAfterSheet: ConversationID?
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        chat: any ChatRepository, profiles: any ProfileRepository, session: SessionStore, badges: BadgeStore,
        network: NetworkMonitor, router: Router, now: @escaping @Sendable () -> Date,
        makeNewChat: @escaping NewChatFactory
    ) {
        self.chat = chat
        self.profiles = profiles
        self.session = session
        self.badges = badges
        self.network = network
        self.router = router
        self.now = now
        self.makeNewChat = makeNewChat
    }

    // MARK: Words

    var title: String { String(localized: "chat.list.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "chat.list.empty", bundle: #bundle) }
    var emptyAction: String { String(localized: "chat.list.emptyAction", bundle: #bundle) }
    var newChatLabel: String { String(localized: "chat.list.new", bundle: #bundle) }
    var isOffline: Bool { network.isOffline }

    func unreadText(_ count: Int) -> String {
        String(localized: "chat.list.unread \(count)", bundle: #bundle)
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
            async let list = chat.conversations()
            async let counts = chat.unreadCounts()
            let (conversations, unread) = try await (list, counts)
            await people.load(conversations.flatMap(\.memberIDs), from: profiles)
            let myID = session.currentUser?.id
            let rows = conversations.filter { !$0.memberIDs.contains(where: session.isBlocked) || $0.kind == .group }
                .sorted { ($0.lastMessage?.sentAt ?? $0.createdAt) > ($1.lastMessage?.sentAt ?? $1.createdAt) }
                .map { row(for: $0, unread: unread[$0.id] ?? 0, myID: myID) }
            state = rows.isEmpty ? .empty : .loaded(ChatListContent(rows: rows))
            hasLoaded = true
            await badges.refresh()
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

    private func row(for conversation: Conversation, unread: Int, myID: UserID?) -> ChatRowData {
        let names = conversation.memberIDs.filter { $0 != myID }.map(people.name)
        return ChatRowData(
            id: conversation.id, title: people.title(for: conversation, me: myID),
            preview: preview(of: conversation, myID: myID),
            timeText: (conversation.lastMessage?.sentAt).map { ChatTime.text(for: $0, now: now()) } ?? "",
            unreadCount: unread, isGroup: conversation.kind == .group, memberNames: Array(names.prefix(3)))
    }

    /// The last message as one line. The repository words the kind ("Photo", "Voice note", "Hangout"); here we add who
    /// said it: "You: " for yours, the first name in a group.
    func preview(of conversation: Conversation, myID: UserID?) -> String {
        guard let last = conversation.lastMessage else {
            return String(localized: "chat.list.noMessages", bundle: #bundle)
        }
        if last.senderID == myID { return String(localized: "chat.list.you \(last.text)", bundle: #bundle) }
        guard conversation.kind == .group else { return last.text }
        let first = people.name(last.senderID).split(separator: " ").first.map(String.init) ?? ""
        return first.isEmpty ? last.text : "\(first): \(last.text)"
    }

    // MARK: Taps

    func rowTapped(_ id: ConversationID) { router.open(.conversation(id)) }
    func newChatTapped() { isShowingNewChat = true }

    func makeNewChatViewModel() -> NewChatViewModel {
        makeNewChat { [weak self] exit in
            if case .open(let id) = exit { self?.openAfterSheet = id }
            self?.isShowingNewChat = false
        }
    }

    /// The New chat sheet has closed: open the conversation it made, and refresh the list.
    func newChatDismissed() async {
        if let id = openAfterSheet {
            openAfterSheet = nil
            router.open(.conversation(id))
        }
        await reload()
    }
}
