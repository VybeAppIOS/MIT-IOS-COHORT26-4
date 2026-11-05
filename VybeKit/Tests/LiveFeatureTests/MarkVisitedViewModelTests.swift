import Core
import Foundation
import Models
import Testing
import UIKit
@testable import LiveFeature

@MainActor
struct MarkVisitedViewModelTests {
    private let evening = SampleData.evening              // two Spots: the café, then the park

    /// A small JPEG drawn here (no real person's photo in tests).
    private func photoData() throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        }
        return try #require(image.jpegData(compressionQuality: 0.8))
    }

    private func liveStore() async throws -> LiveHangoutStore {
        let deps = AppDependencies.preview()
        try await deps.liveStore.startOrResume(hangoutID: evening.id)
        return deps.liveStore
    }

    private func sheet(for spotIndex: Int, store: LiveHangoutStore, onFinished: @escaping @MainActor () -> Void = {})
        -> MarkVisitedViewModel {
        MarkVisitedViewModel(
            spotID: evening.spots[spotIndex].id, spotName: "EXAMPLE", isLastSpot: spotIndex == evening.spots.count - 1,
            liveStore: store, processor: PhotoProcessor(), sleep: { _ in }, onFinished: onFinished)
    }

    // MARK: The photo limit (task SC-H2)

    @Test func theFirstSpotAllowsTwoPhotos() async throws {
        let viewModel = sheet(for: 0, store: try await liveStore())
        #expect(viewModel.photoLimit == 2)                  // 2 × 1 visited (this Spot)
        #expect(viewModel.photosLeft == 2)
        await viewModel.photoPicked(try photoData())
        await viewModel.photoPicked(try photoData())
        #expect(viewModel.pickedPhotos.count == 2)
        #expect(!viewModel.canAddPhoto)
        await viewModel.photoPicked(try photoData())        // a third is refused
        #expect(viewModel.pickedPhotos.count == 2)
    }

    @Test func photosAlreadyInTheRunCountTowardsTheLimit() async throws {
        let store = try await liveStore()
        store.markVisited(spotID: evening.spots[0].id)
        store.addPhoto(Photo(id: "photo-example-run-1", path: "EXAMPLE.jpg", width: 10, height: 10))
        let viewModel = sheet(for: 1, store: store)
        #expect(viewModel.photoLimit == 4)                  // 2 × 2 visited
        #expect(viewModel.photosLeft == 3)                  // one already in the run
    }

    @Test func aPhotoThatCannotBeProcessedShowsAnErrorAndDoneStillWorks() async throws {
        let store = try await liveStore()
        let viewModel = sheet(for: 0, store: store)
        await viewModel.photoPicked(Data("not a photo".utf8))
        #expect(viewModel.photoError == MarkVisitedText.photoError)
        await viewModel.doneTapped()
        #expect(store.visitedCount == 1)
    }

    // MARK: Done (task SC-H2: marking twice is idempotent)

    @Test func doneMarksTheSpotAndShowsTheSuccess() async throws {
        let store = try await liveStore()
        var finished = 0
        let viewModel = sheet(for: 0, store: store) { finished += 1 }
        await viewModel.doneTapped()
        #expect(viewModel.isDone)
        #expect(store.visitedCount == 1)
        #expect(finished == 1)
    }

    @Test func markingTwiceChangesNothing() async throws {
        let store = try await liveStore()
        var finished = 0
        let viewModel = sheet(for: 0, store: store) { finished += 1 }
        await viewModel.doneTapped()
        await viewModel.doneTapped()
        #expect(store.visitedCount == 1)
        #expect(store.run?.visits.count == 1)
        #expect(finished == 1)
    }

    @Test func confettiOnlyOnTheLastSpotAndNeverWithReduceMotion() async throws {
        let store = try await liveStore()
        let first = sheet(for: 0, store: store)
        await first.doneTapped()
        #expect(!first.showsConfetti(reduceMotion: false))
        let last = sheet(for: 1, store: store)
        await last.doneTapped()
        #expect(last.showsConfetti(reduceMotion: false))
        #expect(!last.showsConfetti(reduceMotion: true))
    }

    @Test func textsResolveToRealText() {
        #expect(MarkVisitedText.question("EXAMPLE Café") == "Mark EXAMPLE Café as visited?")
        #expect(MarkVisitedText.limitReached(4) == "You can add up to 4 photos so far.")
    }
}
