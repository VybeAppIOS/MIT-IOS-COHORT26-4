import Models
import Testing
@testable import Core

/// The stubs keep the same promises LocalData and Remote will be held to.
struct ContractTests {
    @Test(arguments: [StubMode.loaded, .empty])
    func hangoutStubKeepsTheContract(mode: StubMode) async throws {
        try await HangoutRepositoryContract.verify(StubHangoutRepository(mode: mode))
    }

    @Test(arguments: [StubMode.loaded, .empty])
    func placeStubKeepsTheContract(mode: StubMode) async throws {
        try await PlaceRepositoryContract.verify(StubPlaceRepository(mode: mode), area: "Kothrud",
                                                 hangouts: SampleData.hangouts)
    }

    @Test(arguments: [StubMode.loaded, .empty])
    func libraryStubKeepsTheContract(mode: StubMode) async throws {
        try await LibraryRepositoryContract.verify(StubLibraryRepository(mode: mode))
    }

    @Test func profileStubKeepsTheContract() async throws {
        try await ProfileRepositoryContract.verify(StubProfileRepository())
    }

    @Test func searchStubKeepsTheContract() async throws {
        try await SearchRepositoryContract.verify(StubSearchRepository(), knownWord: "Garden")
    }

    /// A contract really fails when an implementation breaks a promise.
    @Test func aBrokenRepositoryFailsTheContract() async {
        let broken = StubHangoutRepository(hangouts: [SampleData.evening].map {
            var draft = $0
            draft.status = .draft
            return draft
        } + SampleData.hangouts)
        await #expect(throws: ContractFailure.self) {
            try await HangoutRepositoryContract.verify(BrokenPublishedFilter(base: broken))
        }
    }
}

/// Returns drafts from `hangouts(...)`, which the contract forbids.
private struct BrokenPublishedFilter: HangoutRepository {
    let base: StubHangoutRepository
    func hangout(id: HangoutID) async throws -> Hangout { try await base.hangout(id: id) }
    func hangouts(near center: Coordinate?, filters: HangoutFilters) async throws -> [Hangout] { base.hangouts }
    func picks() async throws -> [Hangout] { [] }
    func remixes(of id: HangoutID) async throws -> [Hangout] { [] }
    func stats(for id: HangoutID) async throws -> HangoutStats { HangoutStats(doneCount: 0, remixCount: 0) }
}
