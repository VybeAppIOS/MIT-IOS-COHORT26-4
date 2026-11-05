import Core
import Foundation
import Models
import Testing
@testable import FriendsFeature

@MainActor
struct HubViewModelTests {
    private func makeViewModel(
        _ friends: FakeFriends = .standard(), deps: AppDependencies = .preview(.loaded)
    ) -> HubViewModel {
        HubViewModel(
            friends: friends, profiles: deps.profiles, session: deps.session, router: deps.router,
            now: { SampleData.day })
    }

    private func content(_ viewModel: HubViewModel) -> HubContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func everySectionLoads() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let loaded = content(viewModel)
        #expect(loaded?.requests.count == 1 && loaded?.otherRequests.count == 1 && loaded?.sent.count == 1)
        #expect(loaded?.suggestions.count == 1 && loaded?.friends.count == 3)
    }

    @Test func friendsAreAToZ() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let names = content(viewModel)?.friends.map(\.name) ?? []
        #expect(names == names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
    }

    @Test func aSuggestionNeedsAMutualFriendAndSaysHowMany() async {
        let friends = FakeFriends.standard()
        friends.state.withLock { $0.suggestions.append(SampleSocialData.meera) }   // no mutual friends: left out
        let viewModel = makeViewModel(friends)
        await viewModel.load()
        let suggestions = content(viewModel)?.suggestions ?? []
        #expect(suggestions.map(\.id) == [SampleSocialData.vihaan.id])
        #expect(suggestions.first?.subtitle?.contains("2") == true)
    }

    @Test func acceptingMovesTheRequestToFriends() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(friends)
        await viewModel.load()
        await viewModel.acceptTapped(SampleSocialData.sanya.id)
        #expect(content(viewModel)?.requests.isEmpty == true)
        #expect(content(viewModel)?.friends.count == 4)
    }

    @Test func ignoringHidesTheRequestAndNeverTouchesTheRepository() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(friends)
        await viewModel.load()
        viewModel.ignoreTapped(SampleSocialData.sanya.id)
        #expect(content(viewModel)?.requests.isEmpty == true)
        #expect(friends.calls.withLock { $0.isEmpty })
    }

    @Test func cancellingASentRequestRemovesIt() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        await viewModel.cancelRequestTapped(SampleSocialData.neel.id)
        #expect(content(viewModel)?.sent.isEmpty == true)
    }

    @Test func addingASuggestionMovesItToSent() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        await viewModel.addTapped(SampleSocialData.vihaan.id)
        #expect(content(viewModel)?.sent.count == 2)
        #expect(content(viewModel)?.suggestions.isEmpty == true)
    }

    @Test func removingAFriendAsksFirst() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(friends)
        await viewModel.load()
        viewModel.removeTapped(SampleSocialData.aarav.id)
        #expect(viewModel.removingID == SampleSocialData.aarav.id)
        #expect(content(viewModel)?.friends.count == 3)
        viewModel.cancelRemove()
        await viewModel.confirmRemove()
        #expect(content(viewModel)?.friends.count == 3)

        viewModel.removeTapped(SampleSocialData.aarav.id)
        await viewModel.confirmRemove()
        #expect(content(viewModel)?.friends.count == 2)
    }

    @Test func aFailedChangeShowsAMessageAndKeepsTheLists() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(friends)
        await viewModel.load()
        friends.failChanges.withLock { $0 = true }
        await viewModel.acceptTapped(SampleSocialData.sanya.id)
        #expect(viewModel.notice != nil)
        #expect(content(viewModel)?.requests.count == 1)
    }

    @Test func limitsAreReachedAtTheNumbersInTheRules() {
        #expect(FriendLimits.reached(friendCount: 499, pendingCount: 99, sentToday: 29) == nil)
        #expect(FriendLimits.reached(friendCount: 500, pendingCount: 0, sentToday: 0) == .friends)
        #expect(FriendLimits.reached(friendCount: 10, pendingCount: 100, sentToday: 0) == .pending)
        #expect(FriendLimits.reached(friendCount: 10, pendingCount: 5, sentToday: 30) == .today)
    }

    @Test func reachingTheDailyLimitStopsNewRequestsAndShowsWhy() async {
        let friends = FakeFriends.standard()
        let myID = SampleData.signedInUser.id
        friends.state.withLock { state in
            state.sent = (0..<30).map {
                FriendRequest(fromID: myID, toID: UserID("user-x-\($0)"), createdAt: SampleData.day)
            }
        }
        let viewModel = makeViewModel(friends)
        await viewModel.load()
        #expect(content(viewModel)?.limit == .today)
        await viewModel.addTapped(SampleSocialData.vihaan.id)
        #expect(friends.calls.withLock { $0.isEmpty })
        #expect(!viewModel.limitText(.today).isEmpty)
    }

    @Test func otherRequestsHaveTheirOwnList() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.otherRequestsTapped()
        #expect(viewModel.showsOtherRequests)
        #expect(content(viewModel)?.otherRequests.count == 1)
    }

    @Test func tapsGoThroughTheRouter() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        let friendID = SampleSocialData.aarav.id
        viewModel.personTapped(friendID)
        #expect(deps.router.path(for: deps.router.currentStack).last == .profile(friendID))
        viewModel.messageTapped(friendID)
        let chat = ConversationID.dm(SampleData.signedInUser.id, friendID)
        #expect(deps.router.path(for: deps.router.currentStack).last == .conversation(chat))
        viewModel.blockTapped(friendID)
        #expect(deps.router.sheet == .blockConfirm(friendID))
    }

    @Test func noFriendsAtAllIsTheEmptyState() async {
        let viewModel = makeViewModel(FakeFriends(.init()))
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = HubViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    // MARK: Search

    private func shownFriends(_ viewModel: HubViewModel) -> [UserID] {
        guard let loaded = content(viewModel) else { return [] }
        return viewModel.matchingFriends(in: loaded).map(\.id)
    }

    @Test func noSearchShowsAllFriends() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(!viewModel.isSearching && shownFriends(viewModel).count == 3)
    }

    @Test func searchMatchesFriendsIgnoringCaseAndAccents() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.searchText = SampleSocialData.aarav.displayName.uppercased()
        #expect(viewModel.isSearching && shownFriends(viewModel) == [SampleSocialData.aarav.id])
        viewModel.searchText = SampleSocialData.aarav.displayName.uppercased().replacingOccurrences(of: "A", with: "Á")
        #expect(shownFriends(viewModel) == [SampleSocialData.aarav.id])
    }

    @Test func searchMatchesTheUsernameToo() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.searchText = SampleSocialData.isha.username
        #expect(shownFriends(viewModel) == [SampleSocialData.isha.id])
    }

    @Test func searchOnlyLooksAtFriendsNotRequestsOrSuggestions() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.searchText = SampleSocialData.vihaan.displayName   // a suggestion, not a friend
        #expect(viewModel.isSearching && shownFriends(viewModel).isEmpty)
        viewModel.searchText = SampleSocialData.sanya.displayName   // a request, not a friend
        #expect(shownFriends(viewModel).isEmpty)
    }

    @Test func searchDoesNotChangeTheLoadedSectionsAndAsksNobody() async {
        let friends = FakeFriends.standard()
        let viewModel = makeViewModel(friends)
        await viewModel.load()
        let before = content(viewModel)
        viewModel.searchText = SampleSocialData.rohan.displayName
        viewModel.searchText = "zzzzqx"
        #expect(content(viewModel) == before)   // the sections are only hidden by the View, never removed
        #expect(friends.calls.withLock { $0.isEmpty })
    }

    @Test func clearingTheSearchBringsEverythingBack() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.searchText = SampleSocialData.rohan.displayName
        #expect(shownFriends(viewModel).count == 1)
        viewModel.searchText = "   "   // only spaces is the same as empty
        #expect(!viewModel.isSearching && shownFriends(viewModel).count == 3)
        #expect(content(viewModel)?.requests.count == 1 && content(viewModel)?.suggestions.count == 1)
    }
}
