import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct InvitationViewModelTests {
    private let invitation = SampleSocialData.invitation

    private func makeViewModel(
        deps: AppDependencies = .preview(.loaded), offline: Bool = false
    ) -> InvitationViewModel {
        InvitationViewModel(
            conversationID: invitation.id, chat: deps.chat, profiles: deps.profiles, session: deps.session,
            network: NetworkMonitor(isOffline: offline), router: deps.router)
    }

    private func content(_ viewModel: InvitationViewModel) -> InvitationContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func theHeadlineNamesWhoAddedYouAndTheGroup() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        let loaded = content(viewModel)
        let adder = try await deps.profiles.profile(id: #require(loaded?.adderID))
        #expect(loaded?.headline.contains(invitation.name ?? "?") == true)
        #expect(loaded?.headline.contains(adder.displayName) == true)
        #expect(loaded?.memberNames.count == invitation.memberIDs.count)
    }

    @Test func theAdderComesFromMyMembershipNotFromTheAdmin() async throws {
        let deps = AppDependencies.preview(.loaded)
        let memberships = try await deps.chat.memberships(in: invitation.id)
        let addedBy = memberships.first { $0.userID == SampleData.signedInUser.id }?.addedByID
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        #expect(addedBy != nil)
        #expect(content(viewModel)?.adderID == addedBy)
    }

    @Test func joiningMakesYouAMemberClosesTheSheetAndOpensTheGroup() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        deps.router.present(.groupInvitation(invitation.id))
        await viewModel.joinTapped()
        #expect(deps.router.sheet == nil)
        #expect(deps.router.path(for: deps.router.currentStack).last == .conversation(invitation.id))
        #expect(try await deps.chat.conversations().contains { $0.id == invitation.id })
        #expect(try await deps.chat.pendingInvitations().isEmpty)
    }

    @Test func leaveAndBlockLeavesThenAsksToBlockTheAdder() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        let adder = try #require(content(viewModel)?.adderID)
        await viewModel.leaveAndBlockTapped()
        #expect(deps.router.sheet == .blockConfirm(adder))
        #expect(try await deps.chat.pendingInvitations().isEmpty)
        #expect(try await deps.chat.conversations().contains { $0.id == invitation.id } == false)
    }

    @Test func aFailedAnswerShowsAMessageAndKeepsTheInvitation() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = InvitationViewModel(
            conversationID: invitation.id, chat: deps.chat, profiles: deps.profiles, session: deps.session,
            network: deps.network, router: deps.router)
        await viewModel.load()
        try await deps.chat.respondToInvitation(to: invitation.id, accept: false)   // answered somewhere else
        await viewModel.joinTapped()
        #expect(viewModel.notice != nil)
        #expect(deps.router.path(for: deps.router.currentStack).isEmpty)
    }

    @Test func offlineCannotAnswer() async {
        let viewModel = makeViewModel(offline: true)
        await viewModel.load()
        #expect(!viewModel.canAnswer)
    }

    @Test func aGroupYouAlreadyJoinedIsNotAnInvitationAnyMore() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = InvitationViewModel(
            conversationID: SampleSocialData.crew.id, chat: deps.chat, profiles: deps.profiles, session: deps.session,
            network: deps.network, router: deps.router)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aMissingInvitationIsTheEmptyState() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = InvitationViewModel(
            conversationID: "conversation-gone", chat: deps.chat, profiles: deps.profiles, session: deps.session,
            network: deps.network, router: deps.router)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = InvitationViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
