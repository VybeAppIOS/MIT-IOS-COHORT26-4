import Core
import Models
import Testing
@testable import DiscoverFeature

/// The pin preview card (task SC-D2): it shares the Discover map's ViewModel, so these test that ViewModel.
@MainActor
struct PinPreviewTests {
    private let evening = SampleData.evening

    private func loadedViewModel(_ deps: AppDependencies = .preview()) async -> DiscoverMapViewModel {
        let viewModel = DiscoverMapViewModel(
            hangouts: deps.hangouts, places: deps.places, photos: deps.photos, library: deps.libraryStore,
            network: deps.network, router: deps.router, now: deps.now)
        await viewModel.load()
        return viewModel
    }

    @Test func selectingAPinGivesItsCard() async {
        let viewModel = await loadedViewModel()
        viewModel.select(markerID: evening.id.rawValue)
        #expect(viewModel.selectedCard?.id == evening.id)
        #expect(viewModel.selectedCard?.title == evening.title)
    }

    @Test func saveFlipsTheCardsSavedStateAndBack() async throws {
        let viewModel = await loadedViewModel()
        viewModel.select(markerID: evening.id.rawValue)
        let savedAtFirst = try #require(viewModel.selectedCard?.isSaved)   // the sample library saves this one
        await viewModel.saveTapped()
        #expect(viewModel.selectedCard?.isSaved == !savedAtFirst)
        await viewModel.saveTapped()
        #expect(viewModel.selectedCard?.isSaved == savedAtFirst)
    }

    @Test func saveWithNothingSelectedChangesNothing() async {
        let deps = AppDependencies.preview()
        let viewModel = await loadedViewModel(deps)
        let before = deps.libraryStore.savedHangoutIDs
        await viewModel.saveTapped()
        #expect(deps.libraryStore.savedHangoutIDs == before)
    }

    @Test func aSwipeDownClosesTheCard() async {
        let viewModel = await loadedViewModel()
        viewModel.select(markerID: evening.id.rawValue)
        viewModel.dismissPreview()
        #expect(viewModel.selectedCard == nil)
    }

    @Test func aMapTapClosesTheCard() async {
        let viewModel = await loadedViewModel()
        viewModel.select(markerID: evening.id.rawValue)
        viewModel.select(markerID: nil)
        #expect(viewModel.selectedCard == nil)
    }

    /// Task SC-D2 "Done when": tapping the card (or See Hangout, which calls the same action) pushes Hangout detail.
    @Test func tappingTheCardPushesTheHangoutDetailRoute() async {
        let deps = AppDependencies.preview()
        let viewModel = await loadedViewModel(deps)
        viewModel.select(markerID: evening.id.rawValue)
        viewModel.cardTapped(evening.id)
        #expect(deps.router.path(for: deps.router.currentStack) == [.hangout(evening.id)])
    }

    @Test func textsResolveToRealText() {
        #expect(PinPreviewText.seeHangout == "See Hangout")
        #expect(PinPreviewText.save == "Save")
        #expect(PinPreviewText.saved == "Saved")
    }
}
