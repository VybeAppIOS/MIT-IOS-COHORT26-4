import Core
import Foundation
import Models
import Testing
@testable import PostingFeature

@MainActor
struct EditPostViewModelTests {
    /// A scheduled post of the EXAMPLE evening Hangout with two photos, made by the real live store.
    private struct Setup {
        let viewModel: EditPostViewModel
        let deps: AppDependencies
        let run: HangoutRun
    }

    private func make() async throws -> Setup {
        let deps = AppDependencies.preview(.loaded)
        _ = try await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
        for spot in SampleData.evening.spots { deps.liveStore.markVisited(spotID: spot.id) }
        deps.liveStore.end()
        var run = try #require(deps.libraryStore.finishedRuns.first)
        run.state = .scheduled
        run.photos = [Photo(id: "photo-1", path: "photo-1.jpg", width: 1600, height: 1200),
                      Photo(id: "photo-2", path: "photo-2.jpg", width: 1600, height: 1200)]
        deps.libraryStore.updateRun(run, times: deps.libraryStore.library.runTimes[run.id])
        let viewModel = EditPostViewModel(runID: run.id, libraryStore: deps.libraryStore, places: deps.places,
                                          photos: deps.photos, session: deps.session, router: deps.router)
        await viewModel.load()
        return Setup(viewModel: viewModel, deps: deps, run: run)
    }

    @Test func theSpotsAreShownAndNeverChange() async throws {
        let setup = try await make()
        let (viewModel, deps, run) = (setup.viewModel, setup.deps, setup.run)
        #expect(viewModel.spotRows.count == run.visits.count)
        viewModel.title = "Kothrud evening, again"
        viewModel.removePhoto("photo-1")
        deps.router.present(.editPost(run.id))
        await viewModel.saveTapped()
        let saved = try #require(deps.libraryStore.library.runs.first { $0.id == run.id })
        #expect(saved.visits == run.visits)
        #expect(saved.title == "Kothrud evening, again" && saved.photos.map(\.id) == ["photo-2"])
        #expect(saved.coverPhotoID == "photo-2" && deps.router.sheet == nil)
    }

    @Test func deleteAsksFirstThenRemovesThePost() async throws {
        let setup = try await make()
        let (viewModel, deps, run) = (setup.viewModel, setup.deps, setup.run)
        viewModel.deleteTapped()
        #expect(viewModel.isConfirmingDelete)
        #expect(deps.libraryStore.library.runs.contains { $0.id == run.id })
        deps.router.present(.editPost(run.id))
        await viewModel.deleteConfirmed()
        #expect(!deps.libraryStore.library.runs.contains { $0.id == run.id })
        #expect(deps.router.sheet == nil)
    }

    @Test func publicAsksFirst() async throws {
        let viewModel = try await make().viewModel
        viewModel.audienceTapped(.public)
        #expect(viewModel.isConfirmingPublic && viewModel.visibility == .friends)
        viewModel.publicConfirmed()
        #expect(viewModel.visibility == .public)
    }

    @Test func anEmptyTitleCannotBeSaved() async throws {
        let viewModel = try await make().viewModel
        viewModel.title = "   "
        #expect(viewModel.titleError != nil && !viewModel.canSave)
    }

    @Test func aRunThatIsOnlyFinishedIsNotAPost() async throws {
        let deps = AppDependencies.preview(.loaded)
        _ = try await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
        deps.liveStore.end()
        let run = try #require(deps.libraryStore.finishedRuns.first)
        let viewModel = EditPostViewModel(runID: run.id, libraryStore: deps.libraryStore, places: deps.places,
                                          photos: deps.photos, session: deps.session, router: deps.router)
        await viewModel.load()
        #expect(viewModel.state == .failed(.notFound))
    }
}
