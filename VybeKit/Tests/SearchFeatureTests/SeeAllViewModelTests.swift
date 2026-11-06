import Core
import Foundation
import Models
import Synchronization
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

/// A friends list with exactly the given people.
private struct SelfIncludingFriends: FriendsRepository {
    let people: [UserProfile]

    func friends() async throws -> [UserProfile] { people }
    func requests() async throws -> FriendRequests { FriendRequests() }
    func suggestions() async throws -> [UserProfile] { [] }
    func mutualFriends(with user: UserID) async throws -> [UserProfile] { [] }
    func sendRequest(to user: UserID) async throws -> FriendRequest { throw AppError.unknown }
    func acceptRequest(from user: UserID) async throws {}
    func cancelRequest(to user: UserID) async throws {}
    func removeFriend(_ user: UserID) async throws {}
}

/// A search repository with fixed results that remembers what it was asked.
private final class RecordingSearch: SearchRepository {
    let results: SearchResults
    let asked = Mutex<[(text: String, scope: Set<SearchKind>)]>([])

    init(_ results: SearchResults) { self.results = results }

    func search(text: String, scope: Set<SearchKind>) async throws -> SearchResults {
        asked.withLock { $0.append((text, scope)) }
        return results
    }
}

@MainActor
struct SeeAllViewModelTests {
    private func makeViewModel(
        _ kind: SearchKind, friends: (any FriendsRepository)? = nil, search: (any SearchRepository)? = nil,
        deps: AppDependencies = .preview(.loaded)
    ) -> SeeAllViewModel {
        SeeAllViewModel(
            kind: kind, hangouts: deps.hangouts, places: deps.places, friends: friends ?? deps.friends,
            search: search ?? deps.search, session: deps.session, router: deps.router)
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
            search: deps.search, session: blocking, router: deps.router)
        await viewModel.load()
        #expect(content(viewModel)?.rows.map(\.id) == ["user-many-1", "user-many-2"])
    }

    @Test func withTypedWordsItShowsOnlyTheMatchesInThatGroup() async {
        let deps = AppDependencies.preview(.loaded)
        let search = RecordingSearch(SearchResults(
            hangouts: Array(SampleData.hangouts.prefix(1)), places: Array(SampleData.places.prefix(1)),
            people: [SampleSocialData.aarav]))
        deps.session.lastSearchQuery = "  ca  "
        let viewModel = makeViewModel(.places, search: search, deps: deps)
        await viewModel.load()
        #expect(content(viewModel)?.rows.map(\.id) == SampleData.places.prefix(1).map(\.id.rawValue))
        #expect(search.asked.withLock { $0.map(\.text) } == ["ca"])
        #expect(search.asked.withLock { $0.map(\.scope) } == [[.places]])
        // The whole group has more places than the matches.
        let everything = makeViewModel(.places, deps: .preview(.loaded))
        await everything.load()
        #expect((content(everything)?.rows.count ?? 0) > 1)
    }

    @Test func withoutTypedWordsItShowsTheWholeGroupAndNeverSearches() async {
        let deps = AppDependencies.preview(.loaded)
        let search = RecordingSearch(SearchResults())
        deps.session.lastSearchQuery = "   "
        let viewModel = makeViewModel(.hangouts, search: search, deps: deps)
        await viewModel.load()
        #expect(search.asked.withLock { $0.isEmpty })
        #expect(content(viewModel)?.rows.isEmpty == false)
    }

    @Test func matchesStillKeepBlockedPeopleOut() async {
        let deps = AppDependencies.preview(.loaded)
        let blocking = SessionStore(
            settings: AppSettings(suiteName: "test.\(UUID().uuidString)"), currentUser: SampleData.signedInUser,
            blockedIDs: [SampleSocialData.aarav.id])
        blocking.lastSearchQuery = "a"
        let search = RecordingSearch(SearchResults(people: [SampleSocialData.aarav, SampleSocialData.isha]))
        let viewModel = SeeAllViewModel(
            kind: .people, hangouts: deps.hangouts, places: deps.places, friends: deps.friends, search: search,
            session: blocking, router: deps.router)
        await viewModel.load()
        #expect(content(viewModel)?.rows.map(\.id) == [SampleSocialData.isha.id.rawValue])
    }

    @Test func youNeverAppearInYourOwnPeopleList() async {
        let deps = AppDependencies.preview(.loaded)
        #expect(deps.session.currentUser?.id == SampleSocialData.currentUser.id)
        let others = [SampleSocialData.aarav, SampleSocialData.isha]
        // In the matches ...
        deps.session.lastSearchQuery = "sample"
        let search = RecordingSearch(SearchResults(people: [SampleSocialData.currentUser] + others))
        let matches = makeViewModel(.people, search: search, deps: deps)
        await matches.load()
        #expect(content(matches)?.rows.map(\.id) == others.map(\.id.rawValue))
        // ... and in the whole group (a friends list that wrongly includes you).
        deps.session.lastSearchQuery = ""
        let wrongList = SelfIncludingFriends(people: [SampleSocialData.currentUser] + others)
        let everyone = makeViewModel(.people, friends: wrongList, deps: deps)
        await everyone.load()
        #expect(content(everyone)?.rows.map(\.id).contains(SampleSocialData.currentUser.id.rawValue) == false)
        #expect(content(everyone)?.rows.count == others.count)
    }

    @Test func matchesArePagedToo() async {
        let deps = AppDependencies.preview(.loaded)
        let many = (0..<45).map { UserProfile(
            id: UserID("user-many-\($0)"), username: "many.\($0)", displayName: "Person \($0)",
            createdAt: SampleData.day) }
        deps.session.lastSearchQuery = "person"
        let viewModel = makeViewModel(.people, search: RecordingSearch(SearchResults(people: many)), deps: deps)
        await viewModel.load()
        #expect(content(viewModel)?.rows.count == SeeAllViewModel.pageSize && content(viewModel)?.hasMore == true)
        viewModel.loadMoreIfNeeded(after: content(viewModel)!.rows.last!)
        #expect(content(viewModel)?.rows.count == SeeAllViewModel.pageSize * 2)
    }

    @Test func noMatchesIsTheEmptyState() async {
        let deps = AppDependencies.preview(.loaded)
        deps.session.lastSearchQuery = "zzzz"
        let viewModel = makeViewModel(.places, search: RecordingSearch(SearchResults()), deps: deps)
        await viewModel.load()
        #expect(viewModel.state == .empty)
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
