import Core
import Foundation
import Models
import Testing
@testable import LiveFeature

@MainActor
struct SummaryViewModelTests {
    private let evening = SampleData.evening                // two Spots: the café, then the park

    /// A real ended run made through the live store (as the app does), inside the live cover, and its screen.
    private func summary(visited: Int, photos: Int = 0) async throws -> (SummaryViewModel, AppDependencies) {
        let deps = AppDependencies.preview()
        let run = try await deps.liveStore.startOrResume(hangoutID: evening.id)
        deps.router.presentCover(.live(evening.id))
        for spot in evening.spots.prefix(visited) { deps.liveStore.markVisited(spotID: spot.id) }
        for index in 0..<photos {
            deps.liveStore.addPhoto(Photo(id: PhotoID("photo-example-\(index)"), path: "EXAMPLE-\(index).jpg",
                                          width: 10, height: 10))
        }
        deps.liveStore.end()
        deps.router.open(.liveSummary(run.id))
        let viewModel = SummaryViewModel(runID: run.id, library: deps.libraryStore, places: deps.places,
                                         photos: deps.photos, router: deps.router)
        await viewModel.load()
        return (viewModel, deps)
    }

    // MARK: The disabled reason (task SC-H3)

    @Test func oneVisitedSpotCannotBePostedAndSaysWhy() async throws {
        let (viewModel, deps) = try await summary(visited: 1)
        #expect(!viewModel.canPost)
        #expect(viewModel.postBlockedReason == "Visit at least 2 Spots to post")
        viewModel.postTapped()
        #expect(deps.router.path(for: .live).last != .composePost(viewModel.runID))
    }

    @Test func twoVisitedSpotsCanBePostedOnTheLiveStack() async throws {
        let (viewModel, deps) = try await summary(visited: 2)
        #expect(viewModel.canPost)
        #expect(viewModel.postBlockedReason == nil)
        viewModel.postTapped()
        #expect(deps.router.path(for: .live).last == .composePost(viewModel.runID))
    }

    // MARK: Where Not now goes (task SC-H3)

    @Test func notNowClosesTheCoverOntoDiscoverAndKeepsTheRunDone() async throws {
        let (viewModel, deps) = try await summary(visited: 1)
        viewModel.notNowTapped()
        #expect(deps.router.cover == nil)
        #expect(deps.router.selectedTab == .discover)
        #expect(deps.router.path(for: .tab(.discover)).isEmpty)
        #expect(viewModel.run?.state == .done)
        #expect(deps.libraryStore.finishedRuns.contains { $0.id == viewModel.runID })   // in Ready to post
    }

    // MARK: Numbers and photos

    @Test func theNumbersAreRoundedAndApproximate() async throws {
        let (viewModel, _) = try await summary(visited: 2)
        #expect(viewModel.visitedText == "You visited 2 of 2 Spots")
        #expect(viewModel.durationText?.hasPrefix("about") == true)          // never an exact time
        #expect(viewModel.distanceMeters > 200 && viewModel.distanceMeters < 300)   // café to park, straight line
        #expect(viewModel.distanceText.hasPrefix("about"))
    }

    @Test func removingAPhotoTakesItOutOfTheRun() async throws {
        let (viewModel, deps) = try await summary(visited: 2, photos: 3)
        #expect(viewModel.photoURLs.count == 3)
        viewModel.removePhoto("photo-example-1")
        #expect(viewModel.photoURLs.map(\.id) == ["photo-example-0", "photo-example-2"])
        #expect(deps.libraryStore.library.runs.first { $0.id == viewModel.runID }?.photos.count == 2)
    }

    @Test func aMissingRunShowsTheError() async {
        let deps = AppDependencies.preview()
        let viewModel = SummaryViewModel(runID: "run-missing-0000", library: deps.libraryStore, places: deps.places,
                                         photos: deps.photos, router: deps.router)
        await viewModel.load()
        #expect(viewModel.state == .failed(.notFound))
    }
}
