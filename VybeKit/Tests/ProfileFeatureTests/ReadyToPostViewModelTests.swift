import Core
import Foundation
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct ReadyToPostViewModelTests {
    private let utc = TimeZone(identifier: "UTC") ?? .current

    /// A finished run of the EXAMPLE evening Hangout with `visited` Spots marked, made by the real live store.
    private func make(visited: Int) async throws -> (viewModel: ReadyToPostViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(.loaded)
        _ = try await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
        for spot in SampleData.evening.spots.prefix(visited) { deps.liveStore.markVisited(spotID: spot.id) }
        deps.liveStore.end()
        return (ReadyToPostViewModel(libraryStore: deps.libraryStore, router: deps.router, timeZone: utc), deps)
    }

    private func content(_ viewModel: ReadyToPostViewModel) -> ReadyContent? {
        if case .loaded(let content, _) = viewModel.state { return content }
        return nil
    }

    @Test func aFinishedRunWithTwoSpotsCanBePosted() async throws {
        let (viewModel, deps) = try await make(visited: 2)
        await viewModel.load()
        let row = try #require(content(viewModel)?.finished.first)
        #expect(row.canPost && row.postBlockedReason == nil)
        #expect(row.spotsText == "2 of 2 Spots")
        deps.router.selectedTab = .profile
        viewModel.postTapped(row.id)
        #expect(deps.router.path(for: .tab(.profile)) == [.composePost(row.id)])
    }

    @Test func postIsOffWithTheReasonBelowTwoVisited() async throws {
        let (viewModel, _) = try await make(visited: 1)
        await viewModel.load()
        let row = try #require(content(viewModel)?.finished.first)
        #expect(!row.canPost)
        #expect(row.postBlockedReason?.contains("2") == true)
    }

    @Test func cancellingAScheduleReturnsTheRunToFinished() async throws {
        let (viewModel, deps) = try await make(visited: 2)
        var run = try #require(deps.libraryStore.finishedRuns.first)
        run.state = .scheduled
        run.postAt = SampleData.day.addingTimeInterval(30 * 60)
        deps.libraryStore.updateRun(run, times: deps.libraryStore.library.runTimes[run.id])
        await viewModel.load()
        #expect(content(viewModel)?.scheduled.map(\.id) == [run.id])
        #expect(content(viewModel)?.scheduled.first?.whenText.isEmpty == false)

        await viewModel.cancelSchedule(run.id)
        #expect(deps.libraryStore.library.runs.first { $0.id == run.id }?.state == .done)
        #expect(content(viewModel)?.finished.map(\.id) == [run.id] && content(viewModel)?.scheduled.isEmpty == true)
    }

    @Test func deleteAsksThenRemovesTheRun() async throws {
        let (viewModel, deps) = try await make(visited: 2)
        await viewModel.load()
        let id = try #require(content(viewModel)?.finished.first?.id)
        viewModel.deleteTapped(id)
        #expect(viewModel.isConfirmingDelete && deps.libraryStore.finishedRuns.count == 1)
        await viewModel.deleteConfirmed()
        #expect(deps.libraryStore.finishedRuns.isEmpty && viewModel.state == .empty)
    }

    @Test func nothingFinishedIsEmpty() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = ReadyToPostViewModel(libraryStore: deps.libraryStore, router: deps.router)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }
}
