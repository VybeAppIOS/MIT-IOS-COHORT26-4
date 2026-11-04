import Foundation
import Models
import Testing
@testable import Core

struct StubTests {
    @Test func loadedReturnsSamplesAndEmptyReturnsNothing() async throws {
        #expect(try await StubHangoutRepository(mode: .loaded).picks() == [SampleData.evening])
        #expect(try await StubHangoutRepository(mode: .empty).picks().isEmpty)
        #expect(try await StubPlaceRepository().spots(for: SampleData.evening) == [SampleData.cafe, SampleData.park])
    }

    @Test func failingThrowsOffline() async {
        await #expect(throws: AppError.offline) { try await StubHangoutRepository(mode: .failing).picks() }
    }

    @Test func unknownIDIsNotFound() async {
        await #expect(throws: AppError.notFound) { try await StubHangoutRepository().hangout(id: "nope") }
        await #expect(throws: AppError.notFound) { try await StubHangoutRepository(mode: .empty).hangout(id: "nope") }
    }

    @Test func neverReturnsStopsWhenCancelled() async {
        let task = Task { try await StubHangoutRepository(mode: .neverReturns).picks() }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func searchRespectsScopeAndBlankText() async throws {
        let search = StubSearchRepository()
        #expect(try await search.search(text: "", scope: Set(SearchKind.allCases)).isEmpty)
        let found = try await search.search(text: "example", scope: [.places])
        #expect(found.places.count == 2 && found.hangouts.isEmpty && found.people.isEmpty)
    }

    @MainActor @Test(arguments: StubMode.allCases)
    func previewDependenciesBuildInEveryMode(mode: StubMode) {
        let deps = AppDependencies.preview(mode)
        #expect(deps.session.onboardingDone)
        #expect(deps.session.currentUser == SampleData.signedInUser)
        #expect(deps.flags == .allOn)
        #expect(deps.now() == SampleData.day)
    }
}
