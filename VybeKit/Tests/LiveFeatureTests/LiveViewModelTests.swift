import Core
import Foundation
import Models
import Testing
@testable import LiveFeature

/// A location service with no permission.
private struct NoLocation: LocationService {
    var authorization: LocationAuthorization { .denied }
    func updates() -> AsyncStream<LocationSample> { AsyncStream { $0.finish() } }
    func requestWhenInUse() {}
}

@MainActor
struct LiveViewModelTests {
    private let evening = SampleData.evening          // café first, then the park

    /// A live run of the Evening Hangout inside the live cover, and the screen's ViewModel.
    private func liveScreen(location: (any LocationService)? = nil) async throws -> (LiveViewModel, AppDependencies) {
        let deps = AppDependencies.preview()
        try await deps.liveStore.startOrResume(hangoutID: evening.id)
        deps.router.presentCover(.live(evening.id))
        let walk = SimulatedLocationService(
            route: [Coordinate(latitude: 18.4960, longitude: 73.7960), SampleData.cafe.coordinate],
            interval: .seconds(10), now: { SampleData.day }, sleep: { _ in })
        let viewModel = LiveViewModel(
            id: evening.id, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            liveStore: deps.liveStore, location: location ?? walk, router: deps.router)
        await viewModel.load()
        return (viewModel, deps)
    }

    // MARK: The task's tests

    @Test func theDistanceUpdatesAsThePersonWalks() async throws {
        let (viewModel, _) = try await liveScreen()
        #expect(viewModel.distanceToCurrentSpot == nil)        // no position yet
        viewModel.positionChanged(Coordinate(latitude: 18.4960, longitude: 73.7960))
        let farther = try #require(viewModel.distanceToCurrentSpot)
        viewModel.positionChanged(Coordinate(latitude: 18.4990, longitude: 73.7990))
        let nearer = try #require(viewModel.distanceToCurrentSpot)
        #expect(nearer < farther)
        await viewModel.followLocation()                        // the simulated walk ends at the café
        #expect((viewModel.distanceToCurrentSpot ?? .infinity) < 1)
        #expect(viewModel.distanceText != nil)
    }

    @Test func theNextSpotBecomesCurrentAfterMarkVisited() async throws {
        let (viewModel, _) = try await liveScreen()
        #expect(viewModel.currentSpot?.place.id == SampleData.cafe.id)
        viewModel.markVisitedTapped()
        #expect(viewModel.isShowingMarkVisited)
        viewModel.markCurrentVisited()
        #expect(viewModel.currentSpot?.place.id == SampleData.park.id)
        #expect(!viewModel.isShowingMarkVisited)
        #expect(viewModel.progressText == "1 of 2 visited")
    }

    @Test func endingWithSpotsLeftAsksFirst() async throws {
        let (viewModel, deps) = try await liveScreen()
        viewModel.endTapped()
        #expect(viewModel.isConfirmingEnd)
        #expect(deps.liveStore.isLive)                          // nothing ended yet
        let runID = try #require(deps.liveStore.run?.id)
        viewModel.endConfirmed()
        #expect(!deps.liveStore.isLive)
        #expect(deps.router.path(for: .live) == [.liveSummary(runID)])
        #expect(viewModel.endCount == 1)
    }

    @Test func endingWithEverySpotVisitedEndsStraightAway() async throws {
        let (viewModel, deps) = try await liveScreen()
        viewModel.markCurrentVisited()
        viewModel.markCurrentVisited()
        #expect(viewModel.currentSpot == nil)
        viewModel.endTapped()
        #expect(!viewModel.isConfirmingEnd)
        #expect(!deps.liveStore.isLive)
    }

    // MARK: Without location, minimise, offline

    @Test func withoutLocationThereIsNoDistanceButMarkVisitedWorks() async throws {
        let (viewModel, _) = try await liveScreen(location: NoLocation())
        await viewModel.followLocation()
        #expect(viewModel.distanceText == nil)
        viewModel.markCurrentVisited()
        #expect(viewModel.currentSpot?.place.id == SampleData.park.id)
    }

    @Test func minimiseClosesTheScreenAndKeepsTheRun() async throws {
        let (viewModel, deps) = try await liveScreen()
        viewModel.minimiseTapped()
        #expect(deps.router.cover == nil)
        #expect(deps.liveStore.isLive)
        #expect(deps.liveStore.isMinimised)
    }

    @Test func itWorksOfflineOnTheLocalData() async throws {
        let deps = AppDependencies.preview()
        deps.network.forceOffline(true)
        try await deps.liveStore.startOrResume(hangoutID: evening.id)
        let viewModel = LiveViewModel(
            id: evening.id, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            liveStore: deps.liveStore, location: NoLocation(), router: deps.router)
        await viewModel.load()
        #expect(viewModel.spots.count == 2)
        #expect(viewModel.currentSpot != nil)
    }

    @Test func distancesAndText() {
        let meters = LiveGeometry.meters(from: SampleData.cafe.coordinate, to: SampleData.park.coordinate)
        #expect(meters > 200 && meters < 300)                   // about 240 m between the two EXAMPLE places
        #expect(LiveText.markVisited == "Mark visited")
        #expect(LiveText.progress(1, of: 3) == "1 of 3 visited")
    }
}
