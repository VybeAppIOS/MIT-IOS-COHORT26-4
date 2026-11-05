import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct InvitationViewModelTests {
    private func makeViewModel(
        deps: AppDependencies = .preview(.loaded), offline: Bool = false
    ) -> InvitationViewModel {
        InvitationViewModel(
            conversationID: SampleSocialData.crew.id, chat: deps.chat, profiles: deps.profiles,
            network: NetworkMonitor(isOffline: offline), router: deps.router)
    }

    private func content(_ viewModel: InvitationViewModel) -> InvitationContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func theHeadlineNamesWhoAddedYouAndTheGroup() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let loaded = content(viewModel)
        #expect(loaded?.headline.contains(SampleSocialData.crew.name ?? "?") == true)
        #expect(loaded?.memberNames.count == SampleSocialData.crew.memberIDs.count)
        #expect(loaded?.adderID == SampleSocialData.crew.adminID)
    }

    @Test func joiningClosesTheSheetAndOpensTheGroup() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        deps.router.present(.groupInvitation(SampleSocialData.crew.id))
        await viewModel.joinTapped()
        #expect(deps.router.sheet == nil)
        #expect(deps.router.path(for: deps.router.currentStack).last == .conversation(SampleSocialData.crew.id))
    }

    @Test func leaveAndBlockLeavesThenAsksToBlockTheAdder() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        await viewModel.leaveAndBlockTapped()
        #expect(deps.router.sheet == .blockConfirm(SampleSocialData.crew.adminID ?? "x"))
        let stillThere = try await deps.chat.conversations().first { $0.id == SampleSocialData.crew.id }
        #expect(stillThere?.memberIDs.contains(SampleData.signedInUser.id) != true)
    }

    @Test func offlineCannotAnswer() async {
        let viewModel = makeViewModel(offline: true)
        await viewModel.load()
        #expect(!viewModel.canAnswer)
    }

    @Test func aMissingInvitationIsTheEmptyState() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = InvitationViewModel(
            conversationID: "conversation-gone", chat: deps.chat, profiles: deps.profiles, network: deps.network,
            router: deps.router)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = InvitationViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
