import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct SavedViewModelTests {
    private func make(
        _ mode: StubMode = .loaded, hangouts: [Hangout] = SampleData.hangouts
    ) -> (viewModel: SavedViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(mode)
        let viewModel = SavedViewModel(hangouts: StubHangoutRepository(mode: mode, hangouts: hangouts),
                                       places: deps.places, photos: deps.photos, libraryStore: deps.libraryStore,
                                       router: deps.router)
        return (viewModel, deps)
    }

    @Test func showsTheSavedHangoutsAsCards() async {
        let (viewModel, _) = make()
        await viewModel.load()
        guard case .loaded(let items, _) = viewModel.state, case .available(let card) = items.first else {
            Issue.record("expected one card, got \(viewModel.state)")
            return
        }
        #expect(items.count == 1 && card.id == SampleData.evening.id && card.isSaved)
    }

    @Test func aHangoutThatIsGoneShowsAsUnavailable() async {
        let (viewModel, _) = make(hangouts: [SampleData.morning])   // the saved evening Hangout no longer exists
        await viewModel.load()
        #expect(viewModel.state == .loaded([.unavailable(SampleData.evening.id)]))
    }

    @Test func unsaveRemovesTheRowAndOffersUndo() async {
        let (viewModel, deps) = make()
        await viewModel.load()
        await viewModel.remove(SampleData.evening.id)
        #expect(viewModel.state == .empty)
        #expect(viewModel.lastRemoved == SampleData.evening.id)
        #expect(!deps.libraryStore.isSaved(SampleData.evening.id))
    }

    @Test func undoPutsItBack() async {
        let (viewModel, deps) = make()
        await viewModel.load()
        await viewModel.remove(SampleData.evening.id)
        await viewModel.undo()
        #expect(deps.libraryStore.isSaved(SampleData.evening.id))
        #expect(viewModel.lastRemoved == nil)
        guard case .loaded(let items, _) = viewModel.state else {
            Issue.record("expected loaded")
            return
        }
        #expect(items.map(\.id) == [SampleData.evening.id])
    }

    @Test func anUnavailableHangoutCanBeRemoved() async {
        let (viewModel, deps) = make(hangouts: [])
        await viewModel.load()
        await viewModel.remove(SampleData.evening.id)
        #expect(!deps.libraryStore.isSaved(SampleData.evening.id) && viewModel.state == .empty)
    }

    @Test func nothingSavedIsEmpty() async {
        let (viewModel, _) = make(.empty)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func tappingACardOpensTheHangout() {
        let (viewModel, deps) = make()
        deps.router.selectedTab = .profile
        viewModel.open(SampleData.evening.id)
        #expect(deps.router.path(for: .tab(.profile)) == [.hangout(SampleData.evening.id)])
    }
}
