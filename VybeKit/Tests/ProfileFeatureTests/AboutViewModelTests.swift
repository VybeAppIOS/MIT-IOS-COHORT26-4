import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct AboutViewModelTests {
    private func make(_ mode: StubMode) -> AboutViewModel {
        let deps = AppDependencies.preview(mode)
        return AboutViewModel(hangouts: deps.hangouts, places: deps.places, version: "1.0 (7)")
    }

    /// The credits list reads `Photo.credit` from the sample content (the task's "Done when").
    @Test func creditsComeFromThePhotosOfTheContent() async {
        let viewModel = make(.loaded)
        await viewModel.load()
        guard case .loaded(let rows, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        let credited = SampleData.places.filter { $0.photos.contains { $0.credit != nil } }
        #expect(rows.map(\.placeName) == credited.map(\.name).sorted())
        #expect(rows.first?.credit == SampleData.cafe.photos.first?.credit)
    }

    @Test func theVersionIsShownAsGiven() {
        #expect(make(.loaded).version == "1.0 (7)")
    }

    @Test func noContentMeansNoCredits() async {
        let viewModel = make(.empty)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedLoadShowsTheError() async {
        let viewModel = make(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }
}
