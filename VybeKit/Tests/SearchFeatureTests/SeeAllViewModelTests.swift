import Core
import Foundation
import Models
import Testing
@testable import SearchFeature

/// A friends list with many people, so paging has something to page.
private struct ManyFriends: FriendsRepository {
    let count: Int

    func friends() async throws -> [UserProfile] {
        (0..<count).map { UserProfile(
            id: UserID("user-many-\($0)"), username: "many.\($0)", displayName: "Person \(String(format: "%03d", $0))",
            createdAt: SampleData.day) }
    }
    func requests() async throws -> FriendRequests { FriendRequests() }
    func suggestions() async throws -> [UserProfile] { [] }
    func mutualFriends(with user: UserID) async throws -> [UserProfile] { [] }
    func sendRequest(to user: UserID) async throws -> FriendRequest { throw AppError.unknown }
    func acceptRequest(from user: UserID) async throws {}
    func cancelRequest(to user: UserID) async throws {}
    func removeFriend(_ user: UserID) async throws {}
}

@MainActor
struct SeeAllViewModelTests {
    private func makeViewModel(
        _ kind: SearchKind, friends: (any FriendsRepository)? = nil, deps: AppDependencies = .preview(.loaded)
    ) -> SeeAllViewModel {
        SeeAllViewModel(
            kind: kind, hangouts: deps.hangouts, places: deps.places, friends: friends ?? deps.friends,
            session: deps.session, router: deps.router)
    }

    private func content(_ viewModel: SeeAllViewModel) -> SeeAllContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func eachGroupHasItsOwnTitleAndList() async {
        for kind in SearchKind.allCases {
            let viewModel = makeViewModel(kind)
            await viewModel.load()
            #expect(!viewModel.title.isEmpty)
            #expect(content(viewModel)?.rows.isEmpty == false)
        }
    }

    @Test func aLongListIsPagedAsTheLastRowAppears() async {
        let viewModel = makeViewModel(.people, friends: ManyFriends(count: 45))
        await viewModel.load()
        #expect(content(viewModel)?.rows.count == SeeAllViewModel.pageSize && content(viewModel)?.hasMore == true)
        viewModel.loadMoreIfNeeded(after: content(viewModel)!.rows[0])   // not the last row: nothing happens
        #expect(content(viewModel)?.rows.count == SeeAllViewModel.pageSize)
        viewModel.loadMoreIfNeeded(after: content(viewModel)!.rows.last!)
        #expect(content(viewModel)?.rows.count == SeeAllViewModel.pageSize * 2)
        viewModel.loadMoreIfNeeded(after: content(viewModel)!.rows.last!)
        #expect(content(viewModel)?.rows.count == 45 && content(viewModel)?.hasMore == false)
    }

    @Test func peopleAreAToZAndBlockedPeopleAreLeftOut() async {
        let deps = AppDependencies.preview(.loaded)
        let blocking = SessionStore(
            settings: AppSettings(suiteName: "test.\(UUID().uuidString)"), currentUser: SampleData.signedInUser,
            blockedIDs: ["user-many-0"])
        let viewModel = SeeAllViewModel(
            kind: .people, hangouts: deps.hangouts, places: deps.places, friends: ManyFriends(count: 3),
            session: blocking, router: deps.router)
        await viewModel.load()
        #expect(content(viewModel)?.rows.map(\.id) == ["user-many-1", "user-many-2"])
    }

    @Test func tappingARowGoesThroughTheRouter() async {
        let deps = AppDependencies.preview(.loaded)
        let row = SearchRowData(id: "x1", title: "", subtitle: "")
        makeViewModel(.hangouts, deps: deps).rowTapped(row)
        #expect(deps.router.path(for: deps.router.currentStack).last == .hangout("x1"))
        makeViewModel(.places, deps: deps).rowTapped(row)
        #expect(deps.router.sheet == .spot("x1"))
        makeViewModel(.people, deps: deps).rowTapped(row)
        #expect(deps.router.path(for: deps.router.currentStack).last == .profile("x1"))
    }

    @Test func nothingToShowIsTheEmptyState() async {
        let viewModel = SeeAllViewModel.preview(.empty)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = SeeAllViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
