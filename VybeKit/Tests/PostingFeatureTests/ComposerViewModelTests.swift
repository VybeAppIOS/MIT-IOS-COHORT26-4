import Core
import Foundation
import Models
import Testing
@testable import PostingFeature

@MainActor
struct ComposerViewModelTests {
    private let utc = TimeZone(identifier: "UTC") ?? .current

    /// A finished run of the EXAMPLE evening Hangout with `visited` Spots, made by the real live store, with `photos`
    /// photos added. The stub clock is `SampleData.day`, so the run ends then.
    private func make(visited: Int, photos: Int = 0) async throws -> (ComposerViewModel, AppDependencies) {
        let deps = AppDependencies.preview(.loaded)
        _ = try await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
        for spot in SampleData.evening.spots.prefix(visited) { deps.liveStore.markVisited(spotID: spot.id) }
        deps.liveStore.end()
        var run = try #require(deps.libraryStore.finishedRuns.first)
        run.photos = (0..<photos).map { index in
            Photo(id: PhotoID("photo-\(index + 1)"), path: "photo-\(index + 1).jpg", width: 1600, height: 1200)
        }
        deps.libraryStore.updateRun(run, times: deps.libraryStore.library.runTimes[run.id])
        let viewModel = ComposerViewModel(
            runID: run.id, libraryStore: deps.libraryStore, session: deps.session, photos: deps.photos,
            router: deps.router, now: { SampleData.day }, timeZone: utc)
        await viewModel.load()
        return (viewModel, deps)
    }

    @Test func postIsOffWithTheReasonBelowTwoVisited() async throws {
        let (viewModel, _) = try await make(visited: 1)
        #expect(!viewModel.canPost)
        #expect(viewModel.postBlockedReason?.contains("2") == true)
    }

    @Test func friendsAndThirtyMinutesAreTheDefaults() async throws {
        let (viewModel, _) = try await make(visited: 2)
        #expect(viewModel.visibility == .friends && viewModel.delay == .thirtyMinutes)
        #expect(viewModel.title == SampleData.evening.title && viewModel.canPost)
    }

    @Test func publicAsksFirst() async throws {
        let (viewModel, _) = try await make(visited: 2)
        viewModel.audienceTapped(.public)
        #expect(viewModel.isConfirmingPublic && viewModel.visibility == .friends)
        viewModel.publicConfirmed()
        #expect(viewModel.visibility == .public)
        viewModel.audienceTapped(.friends)
        #expect(viewModel.visibility == .friends)
    }

    @Test func photosAreLimitedToTwoPerVisitedSpot() async throws {
        let (viewModel, _) = try await make(visited: 2, photos: 6)
        #expect(viewModel.maxPhotos == 4)
        #expect(viewModel.includedRows.count == 4 && viewModel.setAsideRows.count == 2)
        #expect(!viewModel.canAddPhoto)
        viewModel.addBackPhoto("photo-5")
        #expect(viewModel.includedRows.count == 4)
        viewModel.removePhoto("photo-1")
        #expect(viewModel.includedRows.first?.isCover == true && viewModel.includedRows.first?.id == "photo-2")
        viewModel.addBackPhoto("photo-5")
        #expect(viewModel.includedRows.map(\.id) == ["photo-2", "photo-3", "photo-4", "photo-5"])
        viewModel.movePhotos(from: IndexSet(integer: 3), to: 0)
        #expect(viewModel.includedRows.first?.id == "photo-5")
    }

    @Test func aLongCaptionBlocksPosting() async throws {
        let (viewModel, _) = try await make(visited: 2)
        viewModel.caption = String(repeating: "a", count: 281)
        #expect(viewModel.captionError != nil && !viewModel.canPost)
    }

    @Test(arguments: [(PostDelay.thirtyMinutes, 30 * 60.0), (.twoHours, 2 * 60 * 60.0)])
    func postingSchedulesTheRun(delay: PostDelay, after seconds: TimeInterval) async throws {
        let (viewModel, deps) = try await make(visited: 2)
        viewModel.delay = delay
        await viewModel.postTapped()
        let run = try #require(deps.libraryStore.finishedRuns.first)
        let ended = try #require(deps.libraryStore.library.runTimes[run.id]?.endedAt)
        #expect(run.state == .scheduled && run.audience == .friends)
        #expect(run.postAt == max(ended, SampleData.day).addingTimeInterval(seconds))
        #expect(deps.router.selectedTab == .profile && deps.router.path(for: .tab(.profile)) == [.readyToPost])
    }

    @Test func tomorrowMeansNineTheNextMorning() async throws {
        let (viewModel, deps) = try await make(visited: 2)
        viewModel.delay = .nextDay
        await viewModel.postTapped()
        let postAt = try #require(deps.libraryStore.finishedRuns.first?.postAt)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        #expect(calendar.component(.hour, from: postAt) == 9 && postAt > SampleData.day)
    }

    @Test func aMissingRunIsNotFound() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = ComposerViewModel(runID: "missing", libraryStore: deps.libraryStore, session: deps.session,
                                          photos: deps.photos, router: deps.router, now: { SampleData.day })
        await viewModel.load()
        #expect(viewModel.state == .failed(.notFound))
    }
}
