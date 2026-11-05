import Core
import Models
import Testing
@testable import LiveFeature

@MainActor
struct MiniBarViewModelTests {
    private let evening = SampleData.evening              // the café, then the park

    private func makeViewModel(_ deps: AppDependencies) -> MiniBarViewModel {
        MiniBarViewModel(hangouts: deps.hangouts, places: deps.places, liveStore: deps.liveStore, router: deps.router)
    }

    @Test func hiddenWithoutALiveRun() {
        #expect(!makeViewModel(.preview()).isVisible)
    }

    @Test func hiddenWhileTheLiveScreenIsUp() async throws {
        let deps = AppDependencies.preview()
        try await deps.liveStore.startOrResume(hangoutID: evening.id)
        deps.router.presentCover(.live(evening.id))
        #expect(!makeViewModel(deps).isVisible)
    }

    @Test func shownWhenMinimisedNamingTheCurrentSpot() async throws {
        let deps = AppDependencies.preview()
        try await deps.liveStore.startOrResume(hangoutID: evening.id)
        deps.liveStore.minimise()
        let viewModel = makeViewModel(deps)
        await viewModel.loadSpots()
        #expect(viewModel.isVisible)
        #expect(viewModel.currentSpotName == SampleData.cafe.name)
        deps.liveStore.markVisited(spotID: evening.spots[0].id)
        #expect(viewModel.currentSpotName == SampleData.park.name)
    }

    @Test func tappingBringsTheLiveScreenBack() async throws {
        let deps = AppDependencies.preview()
        try await deps.liveStore.startOrResume(hangoutID: evening.id)
        deps.liveStore.minimise()
        let viewModel = makeViewModel(deps)
        viewModel.tapped()
        #expect(deps.router.cover == .live(evening.id))
        #expect(!deps.liveStore.isMinimised)
        #expect(!viewModel.isVisible)
    }

    @Test func goneWhenTheRunEnds() async throws {
        let deps = AppDependencies.preview()
        try await deps.liveStore.startOrResume(hangoutID: evening.id)
        deps.liveStore.minimise()
        let viewModel = makeViewModel(deps)
        deps.liveStore.end()
        #expect(!viewModel.isVisible)
    }

    @Test func theVoiceOverLabelNamesTheCurrentSpot() async throws {
        let deps = AppDependencies.preview()
        try await deps.liveStore.startOrResume(hangoutID: evening.id)
        let viewModel = makeViewModel(deps)
        await viewModel.loadSpots()
        #expect(viewModel.accessibilityLabel == "Live Hangout, \(SampleData.cafe.name), tap to return")
    }
}
