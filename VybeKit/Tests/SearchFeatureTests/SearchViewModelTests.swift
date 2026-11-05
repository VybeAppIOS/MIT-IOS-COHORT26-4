import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import SearchFeature

/// A search repository with fixed results that counts how often it is really asked.
private final class FixedSearch: SearchRepository {
    let results: SearchResults
    let queries = Mutex<[String]>([])
    let fails = Mutex(false)

    init(_ results: SearchResults) { self.results = results }

    func search(text: String, scope: Set<SearchKind>) async throws -> SearchResults {
        queries.withLock { $0.append(text) }
        if fails.withLock({ $0 }) { throw AppError.offline }
        return results
    }
}

@MainActor
struct SearchViewModelTests {
    private let everything = SearchResults(
        hangouts: SampleData.hangouts, places: SampleData.places, people: [SampleSocialData.aarav])

    private func makeViewModel(
        _ search: (any SearchRepository)? = nil, deps: AppDependencies = .preview(.loaded), session: SessionStore? = nil
    ) -> SearchViewModel {
        SearchViewModel(
            search: search ?? deps.search, hangouts: deps.hangouts, libraryStore: deps.libraryStore,
            session: session ?? deps.session, router: deps.router, debounce: .milliseconds(5))
    }

    private func groups(_ viewModel: SearchViewModel) -> [SearchGroup] {
        if case .loaded(.results(let groups), _) = viewModel.state { groups } else { [] }
    }

    @Test func beforeTypingItSuggestsPicks() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        guard case .loaded(.idle(let suggestions, let recents), _) = viewModel.state else {
            Issue.record("expected the idle screen, got \(viewModel.state)")
            return
        }
        #expect(!suggestions.isEmpty && suggestions.count <= SearchViewModel.rowsPerGroup && recents.isEmpty)
    }

    @Test func resultsAreGroupedHangoutsPlacesPeopleFromDiscover() async {
        let viewModel = makeViewModel(FixedSearch(everything))
        viewModel.query = "a"
        await viewModel.queryChanged()
        #expect(groups(viewModel).map(\.kind) == [.hangouts, .places, .people])
    }

    @Test func theOrderFollowsTheTabYouCameFrom() {
        let viewModel = makeViewModel()
        #expect(viewModel.makeGroups(from: everything, previousTab: .discover).map(\.kind)
            == [.hangouts, .places, .people])
        #expect(viewModel.makeGroups(from: everything, previousTab: .community).map(\.kind)
            == [.people, .hangouts, .places])
    }

    @Test func fromProfileYourSavedHangoutsComeFirst() async {
        let deps = AppDependencies.preview(.loaded)
        await deps.libraryStore.ensureLoaded()
        let evening = SampleData.evening.id
        if !deps.libraryStore.isSaved(evening) { await deps.libraryStore.toggleSave(evening) }
        let viewModel = makeViewModel(deps: deps)
        let kinds = viewModel.makeGroups(from: everything, previousTab: .profile).map(\.kind)
        #expect(kinds.first == .saved)
        #expect(kinds.contains(.places) && kinds.contains(.people))
    }

    @Test func theTabIsReadWhenTheQueryRuns() async {
        let deps = AppDependencies.preview(.loaded)
        deps.router.selectedTab = .community
        deps.router.selectedTab = .search   // the router remembers Community as the last tab that was not Search
        let viewModel = makeViewModel(FixedSearch(everything), deps: deps)
        viewModel.query = "a"
        await viewModel.queryChanged()
        #expect(groups(viewModel).first?.kind == .people)
    }

    @Test func onlyTheLastLetterReallySearches() async {
        let search = FixedSearch(everything)
        let viewModel = makeViewModel(search)
        viewModel.query = "k"
        let first = Task { await viewModel.queryChanged() }
        first.cancel()
        viewModel.query = "ko"
        await viewModel.queryChanged()
        await first.value
        #expect(search.queries.withLock { $0 } == ["ko"])
    }

    @Test func blockedPeopleNeverAppear() async {
        let deps = AppDependencies.preview(.loaded)
        let blocking = SessionStore(
            settings: AppSettings(suiteName: "test.\(UUID().uuidString)"), currentUser: SampleData.signedInUser,
            blockedIDs: [SampleSocialData.aarav.id])
        let viewModel = makeViewModel(FixedSearch(everything), deps: deps, session: blocking)
        viewModel.query = "a"
        await viewModel.queryChanged()
        #expect(!groups(viewModel).contains { $0.kind == .people })
    }

    @Test func aLongGroupShowsThreeRowsAndOffersSeeAll() async {
        let many = SearchResults(people: Array(SampleSocialData.people.prefix(8)))
        let viewModel = makeViewModel(FixedSearch(many))
        viewModel.query = "s"
        await viewModel.queryChanged()
        let people = groups(viewModel).first { $0.kind == .people }
        #expect(people?.rows.count == SearchViewModel.rowsPerGroup && people?.hasMore == true)
    }

    @Test func nothingFoundIsTheEmptyStateWithAWayToSuggestAPlace() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(FixedSearch(SearchResults()), deps: deps)
        viewModel.query = "zzz"
        await viewModel.queryChanged()
        #expect(viewModel.state == .empty)
        viewModel.suggestPlaceTapped()
        #expect(deps.router.sheet == .suggestPlace)
    }

    @Test func aFailedSearchShowsTheErrorAndRetryWorks() async {
        let search = FixedSearch(everything)
        search.fails.withLock { $0 = true }
        let viewModel = makeViewModel(search)
        viewModel.query = "a"
        await viewModel.queryChanged()
        #expect(viewModel.state == .failed(.offline))
        search.fails.withLock { $0 = false }
        await viewModel.retry()
        #expect(!groups(viewModel).isEmpty)
    }

    @Test func recentSearchesAreKeptNewestFirstAndLimited() async {
        let viewModel = makeViewModel(FixedSearch(everything))
        for word in ["one", "two", "three", "four", "five", "six"] {
            viewModel.query = word
            await viewModel.queryChanged()
        }
        viewModel.query = ""
        await viewModel.queryChanged()
        guard case .loaded(.idle(_, let recents), _) = viewModel.state else {
            Issue.record("expected idle, got \(viewModel.state)")
            return
        }
        #expect(recents == ["six", "five", "four", "three", "two"])
        viewModel.recentTapped("four")
        #expect(viewModel.query == "four")
        viewModel.clearRecents()
        if case .loaded(.idle(_, let after), _) = viewModel.state { #expect(after.isEmpty) }
    }

    @Test func recentSearchesComeBackAfterTheAppRestarts() async {
        let settings = AppSettings(suiteName: "vybe.test.\(UUID().uuidString)")
        let deps = AppDependencies.preview(.loaded)
        let first = SessionStore(settings: settings, currentUser: SampleData.signedInUser)
        let viewModel = makeViewModel(FixedSearch(everything), deps: deps, session: first)
        for word in ["one", "two"] {
            viewModel.query = word
            await viewModel.queryChanged()
        }
        // A new session and a new view model on the same settings: the app was closed and opened again.
        let second = SessionStore(settings: settings, currentUser: SampleData.signedInUser)
        let reopened = makeViewModel(FixedSearch(everything), deps: deps, session: second)
        await reopened.load()
        guard case .loaded(.idle(_, let recents), _) = reopened.state else {
            Issue.record("expected idle, got \(reopened.state)")
            return
        }
        #expect(recents == ["two", "one"])
        reopened.clearRecents()
        #expect(second.recentSearches.isEmpty && settings.recentSearches.isEmpty)
        let third = makeViewModel(deps: deps, session: SessionStore(settings: settings))
        await third.load()
        if case .loaded(.idle(_, let after), _) = third.state { #expect(after.isEmpty) }
    }

    @Test func tapsGoThroughTheRouter() {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        viewModel.rowTapped(SearchRowData(id: "h1", title: "", subtitle: ""), in: .hangouts)
        #expect(deps.router.path(for: deps.router.currentStack).last == .hangout("h1"))
        viewModel.rowTapped(SearchRowData(id: "p1", title: "", subtitle: ""), in: .places)
        #expect(deps.router.sheet == .spot("p1"))
        viewModel.rowTapped(SearchRowData(id: "u1", title: "", subtitle: ""), in: .people)
        #expect(deps.router.path(for: deps.router.currentStack).last == .profile("u1"))
        viewModel.seeAllTapped(.people)
        #expect(deps.router.path(for: deps.router.currentStack).last == .searchSeeAll(.people))
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = SearchViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
