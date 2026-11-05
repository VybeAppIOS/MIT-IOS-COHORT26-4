import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct MySuggestionsViewModelTests {
    @Test func showsOnlyMyOwnSuggestions() async {
        let deps = AppDependencies.preview(.loaded)
        deps.session.setCurrentUser(SampleData.friend)
        let viewModel = MySuggestionsViewModel(admin: deps.admin, session: deps.session)
        await viewModel.load()
        guard case .loaded(let rows, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        let mine = SampleSocialData.placeSuggestions.filter { $0.submitterID == SampleData.friend.id }
        #expect(rows.map(\.id) == mine.sorted { $0.createdAt > $1.createdAt }.map(\.id.rawValue))
    }

    @Test func nobodyElsesSuggestionsMeansEmpty() async {
        let deps = AppDependencies.preview(.loaded)   // the sample "me" has suggested nothing
        let viewModel = MySuggestionsViewModel(admin: deps.admin, session: deps.session)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let deps = AppDependencies.preview(.failing)
        let viewModel = MySuggestionsViewModel(admin: deps.admin, session: deps.session)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test(arguments: [PlaceSuggestionStatus.pending, .approved, .rejected])
    func everyStatusHasWordsAndItsOwnSymbol(status: PlaceSuggestionStatus) {
        let suggestion = PlaceSuggestion(id: "s1", submitterID: "u1", name: "EXAMPLE",
                                         coordinate: Coordinate(latitude: 18.5, longitude: 73.8), category: .cafe,
                                         status: status, reviewNote: "EXAMPLE note", createdAt: SampleData.day)
        let row = MySuggestionsViewModel.row(suggestion)
        #expect(!row.statusText.isEmpty && !row.statusText.hasPrefix("profile."))
        #expect(row.note == "EXAMPLE note")
    }
}
