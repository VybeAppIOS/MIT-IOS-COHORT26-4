import Foundation
import Core
import Models
import Testing
@testable import FriendsFeature

@MainActor
struct MutualFriendsViewModelTests {
    private func makeViewModel(
        friends: FakeFriends, user: UserID, deps: AppDependencies = .preview(.loaded)
    ) -> MutualFriendsViewModel {
        MutualFriendsViewModel(userID: user, friends: friends, session: deps.session, router: deps.router)
    }

    private func names(_ viewModel: MutualFriendsViewModel) -> [String] {
        if case .loaded(let content, _) = viewModel.state { content.people.map(\.name) } else { [] }
    }

    @Test func mutualFriendsAreListedAToZ() async {
        let viewModel = makeViewModel(friends: .standard(), user: SampleSocialData.vihaan.id)
        await viewModel.load()
        #expect(names(viewModel) == names(viewModel).sorted())
        #expect(names(viewModel).count == 2)
    }

    @Test func nobodyInCommonIsTheEmptyState() async {
        let viewModel = makeViewModel(friends: .standard(), user: SampleSocialData.kabir.id)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aBlockedPersonNeverAppears() async {
        let deps = AppDependencies.preview(.loaded)
        let blocking = SessionStore(
            settings: AppSettings(suiteName: "test.\(UUID().uuidString)"), currentUser: SampleData.signedInUser,
            blockedIDs: [SampleSocialData.aarav.id])
        let viewModel = MutualFriendsViewModel(
            userID: SampleSocialData.vihaan.id, friends: FakeFriends.standard(), session: blocking, router: deps.router)
        await viewModel.load()
        #expect(names(viewModel) == [SampleSocialData.isha.displayName])
    }

    @Test func tappingAPersonOpensTheirProfile() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(friends: .standard(), user: SampleSocialData.vihaan.id, deps: deps)
        viewModel.personTapped(SampleSocialData.isha.id)
        #expect(deps.router.path(for: deps.router.currentStack).last == .profile(SampleSocialData.isha.id))
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = MutualFriendsViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
