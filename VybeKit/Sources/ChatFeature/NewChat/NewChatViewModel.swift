import Core
import Foundation
import Models
import Observation

/// Why the New chat sheet wants to close: a chat was made and should open.
enum NewChatExit: Equatable {
    case open(ConversationID)
}

/// The view-ready values of the New chat sheet (never a raw model).
struct NewChatContent: Equatable {
    let friends: [PersonChoice]
}

struct PersonChoice: Identifiable, Equatable {
    let id: UserID
    let name: String
    let username: String
}

/// New chat or group (SC-CH3): pick friends. One friend opens a direct message (an existing one is reused); two or
/// more make a group, which needs a name and at least 3 people counting you.
@MainActor @Observable
final class NewChatViewModel {
    static let minimumGroupSize = 3

    private(set) var state: LoadState<NewChatContent> = .loading
    private(set) var selected: [UserID] = []
    private(set) var isCreating = false
    var groupName = ""
    /// A short message to show once. The View clears it.
    var notice: String?

    private let friends: any FriendsRepository
    private let chat: any ChatRepository
    private let session: SessionStore
    private let network: NetworkMonitor
    private let onExit: @MainActor (NewChatExit) -> Void
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        friends: any FriendsRepository, chat: any ChatRepository, session: SessionStore, network: NetworkMonitor,
        onExit: @escaping @MainActor (NewChatExit) -> Void
    ) {
        self.friends = friends
        self.chat = chat
        self.session = session
        self.network = network
        self.onExit = onExit
    }

    // MARK: Words

    var title: String { String(localized: "chat.new.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "chat.new.empty", bundle: #bundle) }
    var namePlaceholder: String { String(localized: "chat.new.namePlaceholder", bundle: #bundle) }
    var cancelLabel: String { String(localized: "chat.new.cancel", bundle: #bundle) }
    var okLabel: String { String(localized: "chat.new.ok", bundle: #bundle) }

    var createLabel: String {
        isGroup ? String(localized: "chat.new.createGroup", bundle: #bundle)
            : String(localized: "chat.new.createChat", bundle: #bundle)
    }

    /// Under the list: what to do next, or why Create is off. Nil when it is ready.
    var hint: String? {
        if selected.isEmpty { return String(localized: "chat.new.hintPick", bundle: #bundle) }
        if isGroup && trimmedName.isEmpty { return String(localized: "chat.new.hintName", bundle: #bundle) }
        return nil
    }

    // MARK: Rules

    /// Two or more friends make a group (with you that is at least 3 people).
    var isGroup: Bool { selected.count >= Self.minimumGroupSize - 1 }
    private var trimmedName: String { groupName.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canCreate: Bool {
        guard !isCreating, !network.isOffline else { return false }
        return selected.count == 1 || (isGroup && !trimmedName.isEmpty)
    }

    func isSelected(_ id: UserID) -> Bool { selected.contains(id) }

    func toggle(_ id: UserID) {
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
            let people = try await friends.friends().filter { !session.isBlocked($0.id) }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                .map { PersonChoice(id: $0.id, name: $0.displayName, username: "@\($0.username)") }
            state = people.isEmpty ? .empty : .loaded(NewChatContent(friends: people))
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

    // MARK: Create

    /// One friend: a direct message (the repository reuses an existing one). Two or more: a named group.
    func createTapped() async {
        guard canCreate else { return }
        isCreating = true
        defer { isCreating = false }
        do {
            let conversation: Conversation
            if selected.count == 1, let friend = selected.first {
                conversation = try await chat.startChat(with: friend)
            } else {
                conversation = try await chat.createGroup(name: trimmedName, members: selected)
            }
            onExit(.open(conversation.id))
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message   // the picks stay, so the person can try again
        }
    }
}
