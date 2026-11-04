import Foundation
import Models
import Synchronization
import Testing
@testable import Core

/// Remembers every library it was asked to save, so tests can see what reached the "disk".
private actor RecordingLibrary: LibraryRepository {
    private var stored = Library()
    private(set) var saves: [Library] = []
    var failSaves = false

    func load() async throws -> Library { stored }

    func save(_ library: Library) async throws {
        if failSaves { throw AppError.offline }
        // A slow disk, so quick changes pile up behind a running save.
        try await Task.sleep(for: .milliseconds(5))
        stored = library
        saves.append(library)
    }

    func setFailSaves(_ value: Bool) { failSaves = value }
    var saveCount: Int { saves.count }
}

/// A clock the tests move by hand. A `Mutex` makes it safe to share with the store's `@Sendable` closure.
private final class Clock: Sendable {
    private let current = Mutex(SampleData.day)
    var now: Date { current.withLock { $0 } }
    func advance(minutes: Double) { current.withLock { $0 = $0.addingTimeInterval(minutes * 60) } }
}

/// Hands out run-1, run-2, ... so tests know every ID.
private final class Counter: Sendable {
    private let count = Mutex(0)
    func next() -> String { count.withLock { $0 += 1; return "run-\($0)" } }
}

@MainActor
struct LiveHangoutStoreTests {
    private let evening = SampleData.evening.id

    @MainActor
    private struct Setup {
        let repository = RecordingLibrary()
        let libraryStore: LibraryStore
        let store: LiveHangoutStore
        let session: SessionStore
        let clock = Clock()

        init(hangouts: [Hangout] = SampleData.hangouts, repository shared: RecordingLibrary? = nil) {
            let repository = shared ?? self.repository
            let session = SessionStore(settings: AppSettings(suiteName: "vybe.test.\(UUID().uuidString)"),
                                       currentUser: SampleData.signedInUser)
            let clock = self.clock
            let library = LibraryStore(repository: repository, now: { clock.now })
            self.session = session
            libraryStore = library
            let counter = Counter()
            store = LiveHangoutStore(
                libraryStore: library, hangouts: StubHangoutRepository(hangouts: hangouts), session: session,
                now: { clock.now }, makeID: { counter.next() })
        }
    }

    private func tenSpotHangout() -> Hangout {
        var hangout = SampleData.evening
        hangout.spots = (1...10).map { Spot(id: SpotID("s\($0)"), placeID: PlaceID("p\($0)"), minutes: 10) }
        return hangout
    }

    @Test func startCreatesALiveRunWithCardCopyAndStartTime() async throws {
        let setup = Setup()
        let run = try await setup.store.startOrResume(hangoutID: evening)
        #expect(run.state == .live && run.hangoutID == evening && run.id == "run-1")
        #expect(run.card.hangoutTitle == SampleData.evening.title && run.card.totalSpots == 2)
        #expect(run.card.runnerUsername == SampleData.signedInUser.username)
        #expect(run.audience == .friends && run.visits.isEmpty)
        #expect(setup.store.times?.startedAt == SampleData.day)
        #expect(setup.store.isLive && !setup.store.isMinimised)
    }

    @Test func startingTwiceReturnsTheSameRun() async throws {
        let setup = Setup()
        let first = try await setup.store.startOrResume(hangoutID: evening)
        let second = try await setup.store.startOrResume(hangoutID: evening)
        #expect(first == second)
        #expect(setup.libraryStore.library.runs.count == 1)
    }

    @Test func twoStartsAtTheSameTimeMakeOneRun() async throws {
        let setup = Setup()
        async let first = setup.store.startOrResume(hangoutID: evening)
        async let second = setup.store.startOrResume(hangoutID: evening)
        let runs = try await [first, second]
        #expect(runs[0].id == runs[1].id)
        #expect(setup.libraryStore.library.runs.count == 1)
    }

    @Test func resumingBringsAMinimisedRunBack() async throws {
        let setup = Setup()
        try await setup.store.startOrResume(hangoutID: evening)
        setup.store.minimise()
        #expect(setup.store.isMinimised)
        try await setup.store.startOrResume(hangoutID: evening)
        #expect(!setup.store.isMinimised)
    }

    @Test func startingAnUnknownHangoutFailsAndStartsNothing() async {
        let setup = Setup()
        await #expect(throws: AppError.notFound) { try await setup.store.startOrResume(hangoutID: "nope") }
        #expect(!setup.store.isLive && setup.libraryStore.library.runs.isEmpty)
    }

    @Test func startingNeedsASignedInPerson() async {
        let setup = Setup()
        setup.session.setCurrentUser(nil)
        await #expect(throws: AppError.invalid("Sign in to start a Hangout.")) {
            try await setup.store.startOrResume(hangoutID: evening)
        }
    }

    // MARK: Visiting

    @Test func markVisitedRecordsOrderAndKeepsTheTimeOnlyInRunTimes() async throws {
        let setup = Setup()
        try await setup.store.startOrResume(hangoutID: evening)
        setup.clock.advance(minutes: 20)
        #expect(setup.store.markVisited(spotID: "s2"))
        setup.clock.advance(minutes: 5)
        #expect(setup.store.markVisited(spotID: "s1"))

        let run = try #require(setup.store.run)
        #expect(run.visits == [Visit(spotID: "s2", placeID: SampleData.park.id, order: 1),
                               Visit(spotID: "s1", placeID: SampleData.cafe.id, order: 2)])
        let times = try #require(setup.store.times)
        #expect(times.visitedAt["s2"] == SampleData.day.addingTimeInterval(20 * 60))
        #expect(times.visitedAt["s1"] == SampleData.day.addingTimeInterval(25 * 60))

        // The run itself carries no time of a visit.
        let json = String(bytes: try JSONCoding.encoder.encode(run), encoding: .utf8) ?? ""
        #expect(!json.contains("visitedAt") && !json.contains("startedAt"))
    }

    @Test func markVisitedTwiceChangesNothing() async throws {
        let setup = Setup()
        try await setup.store.startOrResume(hangoutID: evening)
        setup.store.markVisited(spotID: "s1")
        let before = setup.store.run
        let beforeTimes = setup.store.times
        setup.clock.advance(minutes: 10)
        #expect(setup.store.markVisited(spotID: "s1"))
        #expect(setup.store.run == before && setup.store.times == beforeTimes)
    }

    @Test func aSpotThatIsNotInTheHangoutIsIgnored() async throws {
        let setup = Setup()
        #expect(!setup.store.markVisited(spotID: "s1"))   // no run yet
        try await setup.store.startOrResume(hangoutID: evening)
        #expect(!setup.store.markVisited(spotID: "s99"))
        #expect(setup.store.visitedCount == 0)
    }

    @Test func photosAreAddedOnce() async throws {
        let setup = Setup()
        try await setup.store.startOrResume(hangoutID: evening)
        let photo = Photo(id: "ph1", path: "a.jpg", width: 10, height: 10, spotID: "s1")
        setup.store.addPhoto(photo)
        setup.store.addPhoto(photo)
        #expect(setup.store.run?.photos == [photo])
    }

    // MARK: Saving

    @Test func tenQuickVisitsEndInOneConsistentSavedLibrary() async throws {
        let setup = Setup(hangouts: [tenSpotHangout()])
        try await setup.store.startOrResume(hangoutID: evening)
        for number in 1...10 { setup.store.markVisited(spotID: SpotID("s\(number)")) }
        await setup.store.flush()

        let saved = try await setup.repository.load()
        let run = try #require(saved.runs.first)
        #expect(saved.runs.count == 1 && run.visits.map(\.order) == Array(1...10))
        #expect(saved.runTimes[run.id]?.visitedAt.count == 10)
        #expect(saved == setup.libraryStore.library)
        // Changes that arrived during a save were folded together: far fewer than 11 writes.
        #expect(await setup.repository.saveCount <= 3)
    }

    @Test func restartRestoresTheRunMinimised() async throws {
        let shared = RecordingLibrary()
        let first = Setup(repository: shared)
        try await first.store.startOrResume(hangoutID: evening)
        first.store.markVisited(spotID: "s1")
        await first.store.flush()

        let second = Setup(repository: shared)
        await second.libraryStore.load()
        await second.store.restore()
        #expect(second.store.run == first.store.run && second.store.times == first.store.times)
        #expect(second.store.isMinimised && second.store.visitedCount == 1)
        #expect(second.store.markVisited(spotID: "s2"))   // the Hangout's Spots were reloaded
        #expect(second.store.visitedCount == 2)
    }

    @Test func aFailedSaveSetsPersistenceErrorAndKeepsTheRunInMemory() async throws {
        let setup = Setup()
        await setup.repository.setFailSaves(true)
        try await setup.store.startOrResume(hangoutID: evening)
        setup.store.markVisited(spotID: "s1")
        await setup.store.flush()
        #expect(setup.store.persistenceError == .offline)
        #expect(setup.store.isLive && setup.store.visitedCount == 1)

        await setup.repository.setFailSaves(false)
        setup.store.markVisited(spotID: "s2")
        await setup.store.flush()
        #expect(setup.store.persistenceError == nil)
        #expect(try await setup.repository.load().runs.first?.visits.count == 2)
    }

    // MARK: Ending

    @Test func endMakesTheRunDoneWithARoundedDurationAndAnEndTime() async throws {
        let setup = Setup()
        try await setup.store.startOrResume(hangoutID: evening)
        setup.store.markVisited(spotID: "s1")
        setup.clock.advance(minutes: 172)
        setup.store.end()
        await setup.store.flush()

        #expect(!setup.store.isLive && setup.store.run == nil && setup.store.times == nil)
        let saved = try await setup.repository.load()
        let run = try #require(saved.runs.first)
        #expect(run.state == .done && run.durationMinutes == 170 && saved.runs.count == 1)
        #expect(saved.runTimes[run.id]?.endedAt == SampleData.day.addingTimeInterval(172 * 60))
        #expect(setup.libraryStore.finishedRuns.map(\.id) == [run.id])
        #expect(setup.libraryStore.liveRun == nil)
    }

    @Test func discardRemovesTheRunAndItsTimes() async throws {
        let setup = Setup()
        let run = try await setup.store.startOrResume(hangoutID: evening)
        setup.store.discard()
        await setup.store.flush()
        let saved = try await setup.repository.load()
        #expect(saved.runs.isEmpty && saved.runTimes[run.id] == nil)
        #expect(!setup.store.isLive)
    }

    @Test func aNewRunCanStartAfterOneEnded() async throws {
        let setup = Setup()
        try await setup.store.startOrResume(hangoutID: evening)
        setup.store.end()
        let second = try await setup.store.startOrResume(hangoutID: SampleData.morning.id)
        #expect(second.id == "run-2" && setup.libraryStore.library.runs.count == 2)
    }

    @Test func elapsedIsComputedFromTheStartTime() async throws {
        let setup = Setup()
        #expect(setup.store.elapsed(at: SampleData.day) == nil)
        try await setup.store.startOrResume(hangoutID: evening)
        #expect(setup.store.elapsed(at: SampleData.day.addingTimeInterval(90)) == 90)
        #expect(setup.store.elapsed(at: SampleData.day.addingTimeInterval(-5)) == 0)
    }

    @Test(arguments: [(0.0, 5), (2.0, 5), (3.0, 5), (7.0, 5), (8.0, 10), (172.0, 170), (59.0, 60)])
    func durationsRoundToFiveMinutes(minutes: Double, expected: Int) {
        let start = SampleData.day
        #expect(LiveHangoutStore.roundedMinutes(from: start, to: start.addingTimeInterval(minutes * 60)) == expected)
    }

    @Test func savingOtherLibraryItemsDoesNotEraseTheLiveRun() async throws {
        let setup = Setup()
        await setup.libraryStore.load()
        let run = try await setup.store.startOrResume(hangoutID: evening)
        await setup.libraryStore.toggleSave(SampleData.morning.id)
        await setup.store.flush()
        let saved = try await setup.repository.load()
        #expect(saved.runs.map(\.id) == [run.id] && saved.saves.count == 1)
    }
}
