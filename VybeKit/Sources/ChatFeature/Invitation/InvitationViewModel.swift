import Components
import Core
import Foundation
import Models
import Observation

/// The view-ready values of the invitation (never a raw model).
struct InvitationContent: Equatable {
    /// "Alex added you to Kothrud Crew"
    let headline: String
    let memberNames: [String]
    let adderID: UserID?
}

/// Group invitation (SC-CH7): shown when a person who is not your friend adds you to a group. Join, or Leave and
/// block the person who added you. Opened with `Sheet.groupInvitation(id)`.
@MainActor @Observable
final class InvitationViewModel {
    private(set) var state: LoadState<InvitationContent> = .loading
    private(set) var isWorking = false
    /// A short message to show once. The View clears it.
    var notice: String?

    private let conversationID: ConversationID
    private let chat: any ChatRepository
    private let profiles: any ProfileRepository
    private let session: SessionStore
    private let network: NetworkMonitor
    private let router: Router
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        conversationID: ConversationID, chat: any ChatRepository, profiles: any ProfileRepository,
        session: SessionStore, network: NetworkMonitor, router: Router
    ) {
        self.conversationID = conversationID
        self.chat = chat
        self.profiles = profiles
        self.session = session
        self.network = network
        self.router = router
    }

    // MARK: Words

    var title: String { String(localized: "chat.invite.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "chat.invite.empty", bundle: #bundle) }
    var joinLabel: String { String(localized: "chat.invite.join", bundle: #bundle) }
    var leaveAndBlockLabel: String { String(localized: "chat.invite.leaveAndBlock", bundle: #bundle) }
    var hint: String { String(localized: "chat.invite.hint", bundle: #bundle) }
    var okLabel: String { String(localized: "chat.invite.ok", bundle: #bundle) }
    var canAnswer: Bool { !isWorking && !network.isOffline }

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
            guard let group = try await chat.pendingInvitations().first(where: { $0.id == conversationID }) else {
                state = .empty   // the invitation was withdrawn, or already answered
                hasLoaded = true
                return
            }
            // The person who added me is named in my own membership, not guessed from the admin.
            let myID = session.currentUser?.id
            let memberships = try await chat.memberships(in: conversationID)
            let adderID = memberships.first { $0.userID == myID }?.addedByID
            var people = ChatPeople()
            await people.load(group.memberIDs + (adderID.map { [$0] } ?? []), from: profiles)
            let adder = adderID.map(people.name) ?? ""
            let name = group.name ?? ""
            state = .loaded(InvitationContent(
                headline: adder.isEmpty
                    ? String(localized: "chat.invite.headlineUnknown \(name)", bundle: #bundle)
                    : String(localized: "chat.invite.headline \(adder) \(name)", bundle: #bundle),
                memberNames: group.memberIDs.map(people.name), adderID: adderID))
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

    // MARK: Answers

    /// Join: you become a member, the sheet closes and the group opens.
    func joinTapped() async {
        guard canAnswer else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await chat.respondToInvitation(to: conversationID, accept: true)
            router.dismissSheet()
            router.open(.conversation(conversationID))
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    /// Leave and block: the invitation goes away, then the shared Block question opens for the person who added you.
    func leaveAndBlockTapped() async {
        guard canAnswer, case .loaded(let content, _) = state else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await chat.respondToInvitation(to: conversationID, accept: false)
            if let adder = content.adderID {
                router.present(.blockConfirm(adder))   // replaces this sheet
            } else {
                router.dismissSheet()
            }
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }
}
