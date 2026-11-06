import Core
import Foundation
import Models
import Observation

/// One member of the group, ready to draw.
struct MemberRowData: Identifiable, Equatable {
    let id: UserID
    let name: String
    let username: String
    let isAdmin: Bool
    let isMe: Bool
    /// The admin can remove everyone but themselves.
    let canRemove: Bool
    /// The admin can mute everyone but themselves.
    let canMute: Bool
    /// Muted: the person stays and can read, but cannot send.
    let isMuted: Bool
    /// "Muted" is shown to the admin and to the muted person only. Nobody else sees it.
    let showsMutedLabel: Bool
    /// "Unmute" for a muted person, otherwise "Mute".
    let muteLabel: String
    /// Spoken name of the ••• menu: "Actions for Sample Isha".
    let menuLabel: String

    /// The ••• menu is for the admin, on every other member.
    var hasMenu: Bool { canRemove || canMute }
}

/// The view-ready values of the Group info screen (never a raw model).
struct GroupInfoContent: Equatable {
    var name: String
    var members: [MemberRowData]
    var isAdmin: Bool
    /// Below 3 members a group becomes read-only: nobody can add or send.
    var isReadOnly: Bool
    /// My friends who are not in the group yet.
    var addable: [PersonChoice]
}

/// Group info (SC-CH4): the name, the members and their roles. The admin renames the group, removes and mutes
/// members; every member can add their own friends; anyone can leave. A group of fewer than 3 people becomes read-only.
@MainActor @Observable
final class GroupInfoViewModel {
    static let minimumMembers = 3

    private(set) var state: LoadState<GroupInfoContent> = .loading
    /// The member waiting for a "Remove?" answer.
    private(set) var removingID: UserID?
    var isConfirmingLeave = false
    var isAddingMembers = false
    var draftName = ""
    /// Who is picked in the Add members list.
    private(set) var picked: [UserID] = []
    /// A short message to show once. The View clears it.
    var notice: String?

    private let conversationID: ConversationID
    private let chat: any ChatRepository
    private let friends: any FriendsRepository
    private let profiles: any ProfileRepository
    private let session: SessionStore
    private let network: NetworkMonitor
    private let router: Router
    private var people = ChatPeople()
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        conversationID: ConversationID, chat: any ChatRepository, friends: any FriendsRepository,
        profiles: any ProfileRepository, session: SessionStore, network: NetworkMonitor, router: Router
    ) {
        self.conversationID = conversationID
        self.chat = chat
        self.friends = friends
        self.profiles = profiles
        self.session = session
        self.network = network
        self.router = router
    }

    // MARK: Words

    var title: String { String(localized: "chat.group.title", bundle: #bundle) }
    var nameHeader: String { String(localized: "chat.group.name", bundle: #bundle) }
    var membersHeader: String { String(localized: "chat.group.members", bundle: #bundle) }
    var adminLabel: String { String(localized: "chat.group.admin", bundle: #bundle) }
    var addLabel: String { String(localized: "chat.group.add", bundle: #bundle) }
    var addTitle: String { String(localized: "chat.group.addTitle", bundle: #bundle) }
    var doneLabel: String { String(localized: "chat.group.done", bundle: #bundle) }
    var leaveLabel: String { String(localized: "chat.group.leave", bundle: #bundle) }
    var leaveTitle: String { String(localized: "chat.group.leaveTitle", bundle: #bundle) }
    var removeLabel: String { String(localized: "chat.group.remove", bundle: #bundle) }
    var mutedLabel: String { String(localized: "chat.group.muted", bundle: #bundle) }
    private var muteActionLabel: String { String(localized: "chat.group.mute", bundle: #bundle) }
    private var unmuteActionLabel: String { String(localized: "chat.group.unmute", bundle: #bundle) }
    var cancelLabel: String { String(localized: "chat.group.cancel", bundle: #bundle) }
    var saveLabel: String { String(localized: "chat.group.save", bundle: #bundle) }
    var readOnlyNote: String { String(localized: "chat.group.readOnly", bundle: #bundle) }
    var nothingToAdd: String { String(localized: "chat.group.nothingToAdd", bundle: #bundle) }
    var okLabel: String { String(localized: "chat.group.ok", bundle: #bundle) }
    var removeTitle: String {
        let name = removingID.map(people.name) ?? ""
        return String(localized: "chat.group.removeTitle \(name)", bundle: #bundle)
    }

    var isOffline: Bool { network.isOffline }

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
            guard let group = try await chat.conversations().first(where: { $0.id == conversationID }) else {
                state = .empty
                hasLoaded = true
                return
            }
            await people.load(group.memberIDs, from: profiles)
            let myFriends = (try? await friends.friends()) ?? []
            people.add(myFriends)
            let myID = session.currentUser?.id
            let isAdmin = group.adminID != nil && group.adminID == myID
            let memberships = try await chat.memberships(in: conversationID)
            let mutedIDs = Set(memberships.filter { $0.mutedAt != nil }.map(\.userID))
            let members = group.memberIDs.map { id in
                let isMe = id == myID
                let isMuted = mutedIDs.contains(id)
                let name = people.name(id)
                return MemberRowData(
                    id: id, name: name, username: "@\(people.profiles[id]?.username ?? "")",
                    isAdmin: id == group.adminID, isMe: isMe, canRemove: isAdmin && !isMe,
                    canMute: isAdmin && !isMe && id != group.adminID, isMuted: isMuted,
                    showsMutedLabel: isMuted && (isAdmin || isMe),
                    muteLabel: isMuted ? unmuteActionLabel : muteActionLabel,
                    menuLabel: String(localized: "chat.group.actions \(name)", bundle: #bundle))
            }
            let addable = myFriends.filter { friend in
                !group.memberIDs.contains(friend.id) && !session.isBlocked(friend.id)
            }.map { PersonChoice(id: $0.id, name: $0.displayName, username: "@\($0.username)") }
            let name = group.name ?? ""
            if draftName.isEmpty { draftName = name }
            state = .loaded(GroupInfoContent(
                name: name, members: members, isAdmin: isAdmin,
                isReadOnly: group.memberIDs.count < Self.minimumMembers, addable: addable))
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

    // MARK: Changes

    /// Only the admin renames the group, and the name cannot be empty.
    var canSaveName: Bool {
        guard case .loaded(let content, _) = state, content.isAdmin, !network.isOffline else { return false }
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != content.name
    }

    func saveNameTapped() async {
        guard canSaveName else { return }
        await perform { try await self.chat.rename(self.conversationID, to: self.draftName) }
    }

    /// Every member can add their own friends (docs/PRODUCT.md), but not offline.
    var canAdd: Bool { !network.isOffline }

    func addTapped() {
        guard canAdd else { return }
        isAddingMembers = true
    }
    func togglePick(_ id: UserID) {
        if let index = picked.firstIndex(of: id) { picked.remove(at: index) } else { picked.append(id) }
    }

    func confirmAdd() async {
        let chosen = picked
        picked = []
        isAddingMembers = false
        guard !chosen.isEmpty else { return }
        await perform { try await self.chat.add(chosen, to: self.conversationID) }
    }

    func removeTapped(_ id: UserID) {
        guard canAdminister else { return }
        removingID = id
    }
    func cancelRemove() { removingID = nil }

    /// Mute or unmute. The person stays in the group and can read, but cannot send while muted.
    func muteTapped(_ id: UserID) async {
        guard canAdminister, case .loaded(let content, _) = state,
              let member = content.members.first(where: { $0.id == id }), member.canMute else { return }
        await perform { try await self.chat.setMuted(!member.isMuted, member: id, in: self.conversationID) }
    }

    /// Remove, mute and rename are admin-only and need a connection.
    var canAdminister: Bool {
        guard case .loaded(let content, _) = state else { return false }
        return content.isAdmin && !network.isOffline
    }

    func confirmRemove() async {
        guard canAdminister, let id = removingID else {
            removingID = nil
            return
        }
        removingID = nil
        await perform { try await self.chat.remove(id, from: self.conversationID) }
    }

    /// Leaving passes the admin role to the oldest member (the repository does that). Then the person goes back.
    func confirmLeave() async {
        isConfirmingLeave = false
        do {
            try await chat.leave(conversationID)
            router.popToRoot()
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    func memberTapped(_ id: UserID) {
        if id != session.currentUser?.id { router.open(.profile(id)) }
    }

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
