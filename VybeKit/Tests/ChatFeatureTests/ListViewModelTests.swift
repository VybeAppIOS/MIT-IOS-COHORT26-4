import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct ListViewModelTests {
    private final class Exits { var onExit: (@MainActor (NewChatExit) -> Void)? }

    private func makeViewModel(
        chat: (any ChatRepository)? = nil, deps: AppDependencies = .preview(.loaded), exits: Exits = Exits()
    ) -> ListViewModel {
        ListViewModel(
            chat: chat ?? deps.chat, profiles: deps.profiles, session: deps.session, badges: deps.badges,
            network: deps.network, router: deps.router, now: { SampleData.day },
            makeNewChat: { onExit in
                exits.onExit = onExit
                return NewChatViewModel(
                    friends: deps.friends, chat: deps.chat, session: deps.session, network: deps.network,
                    onExit: onExit)
            })
    }

    private func rows(_ viewModel: ListViewModel) -> [ChatRowData] {
        if case .loaded(let content, _) = viewModel.state { content.rows } else { [] }
    }

    private func invitations(_ viewModel: ListViewModel) -> [InvitationRowData] {
        if case .loaded(let content, _) = viewModel.state { content.invitations } else { [] }
    }

    @Test func everyChatIsARowWithItsUnreadCount() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        let conversations = try await deps.chat.conversations()
        let unread = try await deps.chat.unreadCounts()
        #expect(rows(viewModel).count == conversations.count)
        for row in rows(viewModel) { #expect(row.unreadCount == (unread[row.id] ?? 0)) }
    }

    @Test func aDirectMessageIsTitledWithTheOtherPersonAndAGroupWithItsName() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        for row in rows(viewModel) {
            #expect(!row.title.isEmpty)
            #expect(row.isGroup ? row.memberNames.count >= 1 : row.memberNames.count == 1)
        }
    }

    @Test func thePreviewSaysWhoSpokeAndShowsEachKindOfMessage() async {
        let myID = SampleData.signedInUser.id
        let other = SampleSocialData.isha.id
        let viewModel = makeViewModel()
        await viewModel.load()
        func conversation(_ kind: ConversationKind, text: String?, from sender: UserID) -> Conversation {
            Conversation(
                id: "c", kind: kind, name: "Crew", memberIDs: [myID, other], lastMessage: text.map {
                    LastMessagePreview(senderID: sender, text: $0, sentAt: SampleData.day)
                }, createdAt: SampleData.day)
        }
        #expect(viewModel.preview(of: conversation(.directMessage, text: "Photo", from: other), myID: myID) == "Photo")
        let mine = conversation(.directMessage, text: "Hello", from: myID)
        #expect(viewModel.preview(of: mine, myID: myID) == "You: Hello")
        #expect(viewModel.preview(of: conversation(.directMessage, text: nil, from: myID), myID: myID).isEmpty == false)
        let group = viewModel.preview(of: conversation(.group, text: "Voice note", from: other), myID: myID)
        #expect(group.hasSuffix(": Voice note") || group == "Voice note")
    }

    @Test func timesShowTheClockToday() {
        let now = SampleData.day
        #expect(ChatTime.text(for: now.addingTimeInterval(-600), now: now).contains(":"))
        #expect(!ChatTime.text(for: now.addingTimeInterval(-3 * 86_400), now: now).contains(":"))
        #expect(!ChatTime.text(for: now.addingTimeInterval(-86_400), now: now).isEmpty)
    }

    @Test func tappingARowOpensTheConversation() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        let first = rows(viewModel)[0]
        viewModel.rowTapped(first.id)
        #expect(deps.router.path(for: deps.router.currentStack).last == .conversation(first.id))
    }

    @Test func aNewChatOpensItsConversationAfterTheSheetCloses() async {
        let deps = AppDependencies.preview(.loaded)
        let exits = Exits()
        let viewModel = makeViewModel(deps: deps, exits: exits)
        await viewModel.load()
        viewModel.newChatTapped()
        #expect(viewModel.isShowingNewChat)
        _ = viewModel.makeNewChatViewModel()
        exits.onExit?(.open("conversation-new"))
        #expect(!viewModel.isShowingNewChat)
        await viewModel.newChatDismissed()
        #expect(deps.router.path(for: deps.router.currentStack).last == .conversation("conversation-new"))
    }

    @Test func pendingInvitationsAreRowsAboveTheChatsAndNotChatRows() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        let pending = try await deps.chat.pendingInvitations()
        #expect(!pending.isEmpty)
        #expect(invitations(viewModel).map(\.id) == pending.map(\.id))
        #expect(rows(viewModel).allSatisfy { row in !pending.contains { $0.id == row.id } })
        for invitation in invitations(viewModel) {
            #expect(!invitation.title.isEmpty && !invitation.memberNames.isEmpty)
            #expect(!invitation.memberNames.contains(SampleData.signedInUser.displayName))
        }
    }

    @Test func tappingAnInvitationOpensTheInvitationSheet() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        let first = try #require(invitations(viewModel).first)
        viewModel.invitationTapped(first.id)
        #expect(deps.router.sheet == .groupInvitation(first.id))
        #expect(viewModel.isRouterSheetOpen)
    }

    @Test func answeringAnInvitationMovesItIntoTheChatsOnReload() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        let first = try #require(invitations(viewModel).first)
        try await deps.chat.respondToInvitation(to: first.id, accept: true)
        await viewModel.reload()
        #expect(invitations(viewModel).isEmpty)
        #expect(rows(viewModel).contains { $0.id == first.id })
    }

    @Test func leavingAnInvitationRemovesItFromTheListWithoutAChat() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        let first = try #require(invitations(viewModel).first)
        try await deps.chat.respondToInvitation(to: first.id, accept: false)
        await viewModel.reload()
        #expect(invitations(viewModel).isEmpty)
        #expect(!rows(viewModel).contains { $0.id == first.id })
    }

    @Test func noChatsIsTheEmptyState() async {
        let viewModel = ListViewModel.preview(.empty)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = ListViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
