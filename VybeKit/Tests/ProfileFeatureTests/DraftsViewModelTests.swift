import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct DraftsViewModelTests {
    private func make(_ mode: StubMode = .loaded) async -> (viewModel: DraftsViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(mode)
        await deps.libraryStore.saveDraft(DraftsViewModel.sampleDraft)
        let viewModel = DraftsViewModel(places: deps.places, photos: deps.photos, libraryStore: deps.libraryStore,
                                        router: deps.router)
        return (viewModel, deps)
    }

    @Test func showsMyDrafts() async {
        let (viewModel, _) = await make()
        await viewModel.load()
        guard case .loaded(let cards, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        #expect(cards.map(\.id) == [DraftsViewModel.sampleDraft.id])
    }

    @Test func deleteAsksFirstAndDoesNothingUntilConfirmed() async {
        let (viewModel, deps) = await make()
        await viewModel.load()
        viewModel.deleteTapped(DraftsViewModel.sampleDraft.id)
        #expect(viewModel.isConfirmingDelete)
        #expect(deps.libraryStore.drafts.count == 1)
        viewModel.isConfirmingDelete = false   // Cancel
        #expect(viewModel.pendingDelete == nil && deps.libraryStore.drafts.count == 1)
    }

    @Test func confirmingDeleteRemovesTheDraft() async {
        let (viewModel, deps) = await make()
        await viewModel.load()
        viewModel.deleteTapped(DraftsViewModel.sampleDraft.id)
        await viewModel.deleteConfirmed()
        #expect(deps.libraryStore.drafts.isEmpty)
        #expect(viewModel.state == .empty)
    }

    @Test func newHangoutOpensTheEditorAndADraftOpensItself() async {
        let (viewModel, deps) = await make()
        viewModel.newTapped()
        #expect(deps.router.cover == .editor(.new))
        deps.router.dismissCover()
        viewModel.open(DraftsViewModel.sampleDraft.id)
        #expect(deps.router.cover == .editor(.draft(DraftsViewModel.sampleDraft.id)))
    }

    @Test func noDraftsIsEmpty() async {
        let deps = AppDependencies.preview(.empty)
        let viewModel = DraftsViewModel(places: deps.places, photos: deps.photos, libraryStore: deps.libraryStore,
                                        router: deps.router)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }
}
