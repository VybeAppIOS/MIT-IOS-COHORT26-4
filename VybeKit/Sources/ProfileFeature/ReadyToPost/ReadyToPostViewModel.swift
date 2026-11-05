import Core
import Foundation
import Models

/// One finished or scheduled Hangout of mine, ready to draw. My own screen, so it may show my own day and time.
struct ReadyRow: Identifiable, Equatable {
    let id: RunID
    let title: String
    /// "5 Nov" for a finished one; "Scheduled for Thu 8:30 pm" for a scheduled one.
    let whenText: String
    let spotsText: String
    let photosText: String
    let canPost: Bool
    /// Why Post is off, shown under the button ("Visit at least 2 Spots to post").
    let postBlockedReason: String?
}

/// The two sections of Ready to post.
struct ReadyContent: Equatable {
    var finished: [ReadyRow]
    var scheduled: [ReadyRow]
}

/// PR8, Ready to post. Finished Hangouts not posted yet (Post or Delete) and scheduled ones (Cancel returns them to
/// finished). The posting rule (at least 2 visited Spots) comes from `HangoutRules`.
@MainActor @Observable
final class ReadyToPostViewModel {
    private(set) var state: LoadState<ReadyContent> = .loading
    /// The run waiting for "Delete?" to be confirmed.
    var pendingDelete: RunID?

    private let libraryStore: LibraryStore
    private let router: Router
    private let timeZone: TimeZone
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005). Times are shown in Pune time unless a test injects another zone.
    init(
        libraryStore: LibraryStore, router: Router,
        timeZone: TimeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
    ) {
        self.libraryStore = libraryStore
        self.router = router
        self.timeZone = timeZone
    }

    var title: String { String(localized: "profile.ready.title", bundle: #bundle) }
    var finishedHeader: String { String(localized: "profile.ready.finished", bundle: #bundle) }
    var scheduledHeader: String { String(localized: "profile.ready.scheduled", bundle: #bundle) }
    var emptyMessage: String { String(localized: "profile.ready.empty", bundle: #bundle) }
    var noFinished: String { String(localized: "profile.ready.finished.none", bundle: #bundle) }
    var noScheduled: String { String(localized: "profile.ready.scheduled.none", bundle: #bundle) }
    var postTitle: String { String(localized: "profile.ready.post", bundle: #bundle) }
    var deleteTitle: String { String(localized: "profile.ready.delete", bundle: #bundle) }
    var cancelTitle: String { String(localized: "profile.ready.cancel", bundle: #bundle) }
    var deleteConfirmTitle: String { String(localized: "profile.ready.delete.confirm", bundle: #bundle) }
    var deleteConfirmMessage: String { String(localized: "profile.ready.delete.message", bundle: #bundle) }

    var isConfirmingDelete: Bool {
        get { pendingDelete != nil }
        set { if !newValue { pendingDelete = nil } }
    }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        await libraryStore.ensureLoaded()
        if let error = libraryStore.lastError, !libraryStore.hasLoaded {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)
            } else {
                state = .failed(error)
            }
            return
        }
        refresh()
        hasLoaded = true
    }

    /// Rebuilds both sections from the shared library (after a load, a delete or a cancel).
    private func refresh() {
        let runs = libraryStore.finishedRuns
        let finished = runs.filter { $0.state == .done }.map { row($0, scheduled: false) }
        let scheduled = runs.filter { $0.state == .scheduled }.map { row($0, scheduled: true) }
        state = finished.isEmpty && scheduled.isEmpty ? .empty : .loaded(ReadyContent(finished: finished,
                                                                                         scheduled: scheduled))
    }

    private func row(_ run: HangoutRun, scheduled: Bool) -> ReadyRow {
        let visited = run.visits.count
        let canPost = HangoutRules.canPost(visitedCount: visited)
        let spots = String(format: String(localized: "profile.ready.spots", bundle: #bundle), visited,
                           run.card.totalSpots)
        let photos = String(format: String(localized: "profile.ready.photos", bundle: #bundle), run.photos.count)
        let reason = String(format: String(localized: "profile.ready.needSpots", bundle: #bundle),
                            HangoutRules.minimumVisitedToPost)
        return ReadyRow(
            id: run.id, title: run.title ?? run.card.hangoutTitle,
            whenText: scheduled ? scheduledText(run.postAt) : finishedText(libraryStore.library.runTimes[run.id]),
            spotsText: spots, photosText: photos, canPost: canPost, postBlockedReason: canPost ? nil : reason)
    }

    private func finishedText(_ times: RunTimes?) -> String {
        guard let ended = times?.endedAt else { return "" }
        var style = Date.FormatStyle.dateTime.day().month(.abbreviated)
        style.timeZone = timeZone
        return ended.formatted(style)
    }

    private func scheduledText(_ postAt: Date?) -> String {
        guard let postAt else { return "" }
        var style = Date.FormatStyle.dateTime.weekday(.abbreviated).hour().minute()
        style.timeZone = timeZone
        return String(format: String(localized: "profile.ready.scheduledFor", bundle: #bundle), postAt.formatted(style))
    }

    // MARK: What the person does

    func postTapped(_ id: RunID) { router.open(.composePost(id)) }
    func deleteTapped(_ id: RunID) { pendingDelete = id }

    func deleteConfirmed() async {
        guard let id = pendingDelete else { return }
        pendingDelete = nil
        libraryStore.removeRun(id)
        await libraryStore.flush()
        refresh()
    }

    /// A scheduled post goes back to finished: it will not appear, and can be posted again later.
    func cancelSchedule(_ id: RunID) async {
        guard var run = libraryStore.library.runs.first(where: { $0.id == id }), run.state == .scheduled else { return }
        run.state = .done
        run.postAt = nil
        libraryStore.updateRun(run, times: libraryStore.library.runTimes[id])
        await libraryStore.flush()
        refresh()
    }
}
