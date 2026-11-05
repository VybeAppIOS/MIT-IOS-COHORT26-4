import Core
import Foundation
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct BlockedViewModelTests {
    private func make(
        _ mode: StubMode = .loaded, blocking: [UserID] = []
    ) async -> (BlockedViewModel, AppDependencies) {
        let deps = AppDependencies.preview(mode)
        for id in blocking {
            try? await deps.safety.block(id)
            deps.session.block(id)
        }
        let viewModel = BlockedViewModel(safety: deps.safety, session: deps.session, photos: deps.photos,
                                         network: deps.network)
        await viewModel.load()
        return (viewModel, deps)
    }

    @Test func listsTheBlockedPeople() async {
        let (viewModel, _) = await make(blocking: [SampleSocialData.kabir.id])
        guard case .loaded(let rows, _) = viewModel.state else { Issue.record("not loaded"); return }
        #expect(rows.map(\.id).contains(SampleSocialData.kabir.id))
    }

    @Test func unblockTellsTheServerThenTheSession() async throws {
        let kabir = SampleSocialData.kabir.id
        let (viewModel, deps) = await make(blocking: [kabir])
        #expect(deps.session.isBlocked(kabir))
        await viewModel.unblockTapped(kabir)
        #expect(!deps.session.isBlocked(kabir))
        let stillBlocked = try await deps.safety.blocked().map(\.id)
        #expect(!stillBlocked.contains(kabir))
        if case .loaded(let rows, _) = viewModel.state { #expect(!rows.contains { $0.id == kabir }) }
    }

    @Test func offlineTurnsUnblockOff() async {
        let kabir = SampleSocialData.kabir.id
        let (viewModel, deps) = await make(blocking: [kabir])
        deps.network.forceOffline(true)
        #expect(!viewModel.canUnblock)
        await viewModel.unblockTapped(kabir)
        #expect(deps.session.isBlocked(kabir))
    }

    @Test func failedLoadShowsTheError() async {
        let (viewModel, _) = await make(.failing)
        if case .failed = viewModel.state {} else { Issue.record("expected failed") }
    }
}
