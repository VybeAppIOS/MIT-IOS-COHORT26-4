import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct ShareSheetViewModelTests {
    private let post = SampleSocialData.posts[0]

    private func makeViewModel(
        item: ShareItem? = nil, chat: (any ChatRepository)? = nil, deps: AppDependencies = .preview(.loaded),
        offline: Bool = false
    ) -> ShareSheetViewModel {
        ShareSheetViewModel(
            item: item ?? .post(post.id), chat: chat ?? deps.chat, friends: deps.friends, hangouts: deps.hangouts,
            feed: deps.feed, session: deps.session, network: NetworkMonitor(isOffline: offline), router: deps.router)
    }

    private func content(_ viewModel: ShareSheetViewModel) -> ShareContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func groupsAndFriendsAreListed() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(content(viewModel)?.groups.isEmpty == false && content(viewModel)?.friends.isEmpty == false)
    }

    @Test func nothingPickedCannotBeSent() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(!viewModel.canSend)
    }

    @Test func sendingToTwoChatsCreatesTwoHangoutMessages() async {
        let deps = AppDependencies.preview(.loaded)
        let controlled = ControlledChat(base: deps.chat)
        let viewModel = makeViewModel(chat: controlled, deps: deps)
        await viewModel.load()
        guard let group = content(viewModel)?.groups.first, let friend = content(viewModel)?.friends.first else {
            Issue.record("nothing to pick"); return
        }
        viewModel.toggle(group.id)
        viewModel.toggle(friend.id)
        deps.router.present(.share(.post(post.id)))
        await viewModel.sendTapped()
        let sent = controlled.sent.withLock { $0 }
        #expect(sent.count == 2)
        #expect(sent.allSatisfy { $0.1 == .hangout(post.hangoutID) })
        #expect(viewModel.sentCount == 2 && viewModel.sentText != nil)
        #expect(deps.router.sheet == nil)
    }

    @Test func aHangoutIsSharedAsItself() async {
        let deps = AppDependencies.preview(.loaded)
        let controlled = ControlledChat(base: deps.chat)
        let viewModel = makeViewModel(item: .hangout(SampleData.morning.id), chat: controlled, deps: deps)
        await viewModel.load()
        viewModel.toggle(content(viewModel)!.groups[0].id)
        await viewModel.sendTapped()
        #expect(controlled.sent.withLock { $0.first?.1 } == .hangout(SampleData.morning.id))
    }

    @Test func moreOffersTheSystemShareWithTheHangoutsTitle() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(viewModel.shareText?.isEmpty == false)
    }

    @Test func aFailedSendKeepsTheSheetOpenAndTheChatsPicked() async {
        let deps = AppDependencies.preview(.loaded)
        let controlled = ControlledChat(base: deps.chat)
        controlled.failSend.withLock { $0 = true }
        let viewModel = makeViewModel(chat: controlled, deps: deps)
        await viewModel.load()
        viewModel.toggle(content(viewModel)!.groups[0].id)
        deps.router.present(.share(.post(post.id)))
        await viewModel.sendTapped()
        #expect(viewModel.notice != nil && deps.router.sheet != nil && viewModel.selected.count == 1)
    }

    @Test func offlineCannotSend() async {
        let viewModel = makeViewModel(offline: true)
        await viewModel.load()
        viewModel.toggle(content(viewModel)!.groups[0].id)
        #expect(!viewModel.canSend)
    }

    @Test func cancelClosesTheSheet() {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        deps.router.present(.share(.post(post.id)))
        viewModel.cancelTapped()
        #expect(deps.router.sheet == nil)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = ShareSheetViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
