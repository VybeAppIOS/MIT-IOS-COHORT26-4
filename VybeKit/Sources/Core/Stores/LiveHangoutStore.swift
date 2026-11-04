import Foundation
import Models
import Observation

/// The Hangout being done right now. One store for the whole app, so the live screen, the mini-bar and every tab
/// agree, and so the run survives tab switches and the app being closed (ADR 005).
///
/// Memory changes immediately; the run is saved write-behind through `LibraryStore` (the single owner of the library
/// file). Exact times live only in `RunTimes`; the run and its `Visit`s carry order, never a time.
@MainActor @Observable
public final class LiveHangoutStore {
    public private(set) var run: HangoutRun?
    /// Owner-only exact times (ADR 004 and 006).
    public private(set) var times: RunTimes?
    /// The live screen is closed but the run goes on (the mini-bar shows).
    public private(set) var isMinimised = false

    private let libraryStore: LibraryStore
    private let hangouts: any HangoutRepository
    private let session: SessionStore
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> String
    /// The Spots of the run's Hangout, kept so a visit can copy its Place.
    private var spots: [Spot] = []

    public init(
        libraryStore: LibraryStore, hangouts: any HangoutRepository, session: SessionStore,
        now: @escaping @Sendable () -> Date = { Date() },
        makeID: @escaping @Sendable () -> String = { UUID().uuidString.lowercased() }
    ) {
        self.libraryStore = libraryStore
        self.hangouts = hangouts
        self.session = session
        self.now = now
        self.makeID = makeID
    }

    public var isLive: Bool { run != nil }

    /// A write-behind save that failed. The run is still live in memory; the next change tries again.
    public var persistenceError: AppError? { libraryStore.persistenceError }

    /// How long the run has been going, computed from `startedAt` (never a running timer).
    public func elapsed(at date: Date) -> TimeInterval? {
        times.map { max(0, date.timeIntervalSince($0.startedAt)) }
    }

    public var visitedCount: Int { run?.visits.count ?? 0 }

    // MARK: Start, resume, restore

    /// Brings back a run that was live when the app closed. Call it after `LibraryStore.load()`. It comes back
    /// minimised, because no live screen is open yet.
    public func restore() async {
        guard run == nil, let saved = libraryStore.liveRun else { return }
        run = saved
        times = libraryStore.library.runTimes[saved.id]
        isMinimised = true
        spots = (try? await hangouts.hangout(id: saved.hangoutID).spots) ?? []
    }

    /// Starts a run of this Hangout, or returns the one already live (starting twice never makes two runs).
    @discardableResult
    public func startOrResume(hangoutID: HangoutID) async throws -> HangoutRun {
        if let run { isMinimised = false; return run }
        let hangout = try await hangouts.hangout(id: hangoutID)
        if let run { isMinimised = false; return run }   // another call finished first while this one was loading
        guard let user = session.currentUser else { throw AppError.invalid("Sign in to start a Hangout.") }

        let audience: Visibility = user.isPrivate ? .friends : user.settings.defaultAudience
        let started = HangoutRun(
            id: RunID(makeID()), hangoutID: hangout.id, runnerID: user.id, state: .live,
            visibility: user.settings.defaultAudience, audience: audience,
            card: RunCardCopy(
                hangoutTitle: hangout.title, totalSpots: hangout.spots.count,
                budgetPerPerson: hangout.budgetPerPerson, runnerUsername: user.username,
                runnerDisplayName: user.displayName, runnerPhoto: user.photo))
        let startedTimes = RunTimes(startedAt: now())
        run = started
        times = startedTimes
        spots = hangout.spots
        isMinimised = false
        libraryStore.updateRun(started, times: startedTimes)
        return started
    }

    public func minimise() { if isLive { isMinimised = true } }

    public func expand() { isMinimised = false }

    // MARK: During the run

    /// Marks a Spot as visited. Visiting the same Spot twice changes nothing. Returns false when there is no live run
    /// or the Spot is not in this Hangout.
    @discardableResult
    public func markVisited(spotID: SpotID) -> Bool {
        guard var current = run, var currentTimes = times,
              let spot = spots.first(where: { $0.id == spotID }) else { return false }
        guard !current.visits.contains(where: { $0.spotID == spotID }) else { return true }
        current.visits.append(Visit(spotID: spotID, placeID: spot.placeID, order: current.visits.count + 1))
        currentTimes.visitedAt[spotID] = now()
        commit(current, currentTimes)
        return true
    }

    /// Adds a photo to the run. Adding the same photo twice changes nothing.
    public func addPhoto(_ photo: Photo) {
        guard var current = run, !current.photos.contains(where: { $0.id == photo.id }) else { return }
        current.photos.append(photo)
        commit(current, times)
    }

    /// Ends the run: it becomes `done` ("Ready to post") and is no longer live.
    public func end() {
        guard var finished = run, var finishedTimes = times else { return }
        let endedAt = now()
        finishedTimes.endedAt = endedAt
        finished.state = .done
        finished.durationMinutes = Self.roundedMinutes(from: finishedTimes.startedAt, to: endedAt)
        libraryStore.updateRun(finished, times: finishedTimes)
        clear()
    }

    /// Throws the run away.
    public func discard() {
        guard let current = run else { return }
        libraryStore.removeRun(current.id)
        clear()
    }

    /// Waits for the write-behind save (call when the app goes to the background).
    public func flush() async { await libraryStore.flush() }

    // MARK: Private

    private func commit(_ changed: HangoutRun, _ changedTimes: RunTimes?) {
        run = changed
        times = changedTimes
        libraryStore.updateRun(changed, times: changedTimes)
    }

    private func clear() {
        run = nil
        times = nil
        spots = []
        isMinimised = false
    }

    /// A post shows a rounded length, never exact times: whole minutes to the nearest 5, at least 5.
    static func roundedMinutes(from start: Date, to end: Date) -> Int {
        let minutes = max(0, end.timeIntervalSince(start)) / 60
        return max(5, Int((minutes / 5).rounded()) * 5)
    }
}
