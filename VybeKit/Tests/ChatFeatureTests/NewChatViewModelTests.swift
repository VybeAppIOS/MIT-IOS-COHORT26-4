import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct NewChatViewModelTests {
    private final class Exits { var last: NewChatExit? }

    private func makeViewModel(
        exits: Exits = Exits(), offline: Bool = false, chat: (any ChatRepository)? = nil
    ) -> NewChatViewModel {
        let deps = AppDependencies.preview(.loaded)
        return NewChatViewModel(
            friends: deps.friends, chat: chat ?? deps.chat, session: deps.session,
            network: NetworkMonitor(isOffline: offline), onExit: { exits.last = $0 })
    }

    @Test func friendsAreListedAToZ() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        guard case .loaded(let content, _) = viewModel.state else { Issue.record("not loaded"); return }
        let names = content.friends.map(\.name)
        #expect(names == names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
    }

    @Test func oneFriendIsADirectMessageAndNeedsNoName() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.toggle(SampleSocialData.friend.id)
        #expect(!viewModel.isGroup && viewModel.canCreate)
    }

    @Test func twoOrMoreFriendsMakeAGroupThatNeedsAName() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.toggle(SampleSocialData.friend.id)
        viewModel.toggle(SampleSocialData.aarav.id)
        #expect(viewModel.isGroup && !viewModel.canCreate && viewModel.hint != nil)
        viewModel.groupName = "  "
        #expect(!viewModel.canCreate)
        viewModel.groupName = "Saturday crew"
        #expect(viewModel.canCreate && viewModel.hint == nil)
    }

    @Test func nobodyPickedCannotCreate() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(!viewModel.canCreate)
    }

    @Test func aDirectMessageReusesTheExistingConversation() async {
        let exits = Exits()
        let viewModel = makeViewModel(exits: exits)
        await viewModel.load()
        viewModel.toggle(SampleSocialData.friend.id)
        await viewModel.createTapped()
        #expect(exits.last == .open(.dm(SampleData.signedInUser.id, SampleSocialData.friend.id)))
    }

    @Test func aGroupHasAtLeastThreePeopleCountingYou() async throws {
        let deps = AppDependencies.preview(.loaded)
        let exits = Exits()
        let viewModel = makeViewModel(exits: exits, chat: deps.chat)
        await viewModel.load()
        viewModel.toggle(SampleSocialData.friend.id)
        viewModel.toggle(SampleSocialData.aarav.id)
        viewModel.groupName = "Saturday crew"
        await viewModel.createTapped()
        guard case .open(let id)? = exits.last else { Issue.record("no exit"); return }
        let group = try await deps.chat.conversations().first { $0.id == id }
        #expect((group?.memberIDs.count ?? 0) >= NewChatViewModel.minimumGroupSize)
    }

    @Test func offlineStopsCreating() async {
        let viewModel = makeViewModel(offline: true)
        await viewModel.load()
        viewModel.toggle(SampleSocialData.friend.id)
        #expect(!viewModel.canCreate)
    }

    @Test func aFailedCreateKeepsThePicksAndSaysWhy() async {
        let deps = AppDependencies.preview(.loaded)
        let controlled = ControlledChat(base: deps.chat)
        controlled.failChanges.withLock { $0 = true }
        let exits = Exits()
        let viewModel = makeViewModel(exits: exits, chat: controlled)
        await viewModel.load()
        viewModel.toggle(SampleSocialData.friend.id)
        viewModel.toggle(SampleSocialData.aarav.id)
        viewModel.groupName = "Crew two"
        await viewModel.createTapped()
        #expect(exits.last == nil && viewModel.notice != nil && viewModel.selected.count == 2)
    }

    @Test func noFriendsIsTheEmptyState() async {
        let deps = AppDependencies.preview(.empty)
        let viewModel = NewChatViewModel(
            friends: deps.friends, chat: deps.chat, session: deps.session, network: deps.network, onExit: { _ in })
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    // MARK: Search

    private func shown(_ viewModel: NewChatViewModel) -> [UserID] {
        guard case .loaded(let content, _) = viewModel.state else { return [] }
        return viewModel.visibleFriends(in: content).map(\.id)
    }

    @Test func noSearchShowsEveryFriend() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        guard case .loaded(let content, _) = viewModel.state else { Issue.record("not loaded"); return }
        #expect(!viewModel.isSearching && shown(viewModel) == content.friends.map(\.id))
    }

    @Test func searchMatchesTheNameIgnoringCase() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.searchText = SampleSocialData.aarav.displayName.uppercased()
        #expect(shown(viewModel) == [SampleSocialData.aarav.id])
    }

    @Test func searchIgnoresAccents() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.searchText = SampleSocialData.aarav.displayName.uppercased().replacingOccurrences(of: "A", with: "Á")
        #expect(shown(viewModel) == [SampleSocialData.aarav.id])
    }

    @Test func searchMatchesTheUsernameToo() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.searchText = " \(SampleSocialData.isha.username) "   // spaces around it are ignored
        #expect(shown(viewModel) == [SampleSocialData.isha.id])
    }

    @Test func nothingMatchingShowsNobodyButStillSearching() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.searchText = "zzzzqx"
        #expect(viewModel.isSearching && shown(viewModel).isEmpty)
    }

    @Test func pickedPeopleStayPickedWhileFilteringAndAfterClearing() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.toggle(SampleSocialData.friend.id)
        viewModel.toggle(SampleSocialData.aarav.id)
        viewModel.groupName = "Saturday crew"
        viewModel.searchText = SampleSocialData.isha.displayName   // hides both picked people
        #expect(!shown(viewModel).contains(SampleSocialData.aarav.id))
        #expect(viewModel.isSelected(SampleSocialData.aarav.id) && viewModel.isSelected(SampleSocialData.friend.id))
        #expect(viewModel.isGroup && viewModel.canCreate)
        viewModel.toggle(SampleSocialData.isha.id)   // picking from the filtered list adds to the picks
        viewModel.searchText = ""
        #expect(viewModel.selected.count == 3 && !viewModel.isSearching)
    }

    @Test func clearingTheSearchShowsEveryoneAgain() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let everyone = shown(viewModel)
        viewModel.searchText = SampleSocialData.aarav.displayName
        #expect(shown(viewModel).count < everyone.count)
        viewModel.searchText = ""
        #expect(shown(viewModel) == everyone)
    }
}
