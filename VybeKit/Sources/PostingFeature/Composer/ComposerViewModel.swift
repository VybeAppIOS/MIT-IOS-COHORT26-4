import Components
import Core
import Design
import Foundation
import Models

/// One photo row in the composer: in the post, or set aside.
struct ComposerPhotoRow: Identifiable, Equatable {
    let id: PhotoID
    let url: URL?
    let isCover: Bool
    /// "Photo 2" (the photo itself has no words, so the label says where it is).
    let label: String
}

/// One choice in a row of chips or a picker.
struct ComposerOption<Value: Hashable>: Identifiable, Equatable {
    let value: Value
    let title: String

    var id: Value { value }
}

/// PO1, Post composer. Opened from Ready to post with a finished run. Title (prefilled), caption (up to 280), photos
/// (up to 2 per visited Spot; reorder, remove, cover), tags, audience (Friends by default; Public asks first) and
/// when (30 minutes by default). Posting schedules the run and shows Profile › Ready to post.
/// Exact visit times are never put on a post: the run has none, and `RunTimes` stays the owner's.
@MainActor @Observable
final class ComposerViewModel {
    static let captionLimit = 280
    static let titleLimit = 60
    static let tagIDs = ["good-for-groups", "budget-friendly", "rainy-day", "date-idea", "solo-friendly"]

    private(set) var state: LoadState<RunID> = .loading
    var title = ""
    var caption = ""
    private(set) var included: [Photo] = []
    private(set) var setAside: [Photo] = []
    private(set) var coverID: PhotoID?
    private(set) var tags: Set<String> = []
    private(set) var visibility: Visibility = .friends
    var delay: PostDelay = .thirtyMinutes
    /// "Post publicly?" is up.
    var isConfirmingPublic = false
    private(set) var isPosting = false

    private var run: HangoutRun?
    private let runID: RunID
    private let libraryStore: LibraryStore
    private let session: SessionStore
    private let photos: any PhotoStore
    private let router: Router
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005). Times use Pune's calendar unless a test injects another zone.
    init(
        runID: RunID, libraryStore: LibraryStore, session: SessionStore, photos: any PhotoStore, router: Router,
        now: @escaping @Sendable () -> Date, timeZone: TimeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
    ) {
        self.runID = runID
        self.libraryStore = libraryStore
        self.session = session
        self.photos = photos
        self.router = router
        self.now = now
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar
    }

    // MARK: Words

    var screenTitle: String { String(localized: "posting.composer.title", bundle: #bundle) }
    var postTitle: String { String(localized: "posting.composer.post", bundle: #bundle) }

    let tagOptions: [ComposerOption<String>] = ComposerViewModel.tagIDs.map {
        ComposerOption(value: $0, title: String(localized: String.LocalizationValue(stringLiteral: "posting.tag." + $0),
                                                bundle: #bundle))
    }

    let audienceOptions: [ComposerOption<Visibility>] = [
        ComposerOption(value: .friends, title: String(localized: "posting.audience.friends", bundle: #bundle)),
        ComposerOption(value: .public, title: String(localized: "posting.audience.public", bundle: #bundle))
    ]

    let delayOptions: [ComposerOption<PostDelay>] = [
        ComposerOption(value: .thirtyMinutes, title: String(localized: "posting.when.thirty", bundle: #bundle)),
        ComposerOption(value: .twoHours, title: String(localized: "posting.when.twoHours", bundle: #bundle)),
        ComposerOption(value: .nextDay, title: String(localized: "posting.when.tomorrow", bundle: #bundle))
    ]

    // MARK: Rules

    private var visitedCount: Int { run?.visits.count ?? 0 }
    var maxPhotos: Int { HangoutRules.maxPhotos(visitedCount: visitedCount) }
    var canAddPhoto: Bool { included.count < maxPhotos }

    var photoCountText: String {
        String(format: String(localized: "posting.photos.count", bundle: #bundle), included.count, maxPhotos)
    }

    var titleError: String? {
        let count = title.trimmingCharacters(in: .whitespacesAndNewlines).count
        return (1...Self.titleLimit).contains(count) ? nil : String(localized: "posting.error.title", bundle: #bundle)
    }

    var captionError: String? {
        caption.count > Self.captionLimit ? String(localized: "posting.error.caption", bundle: #bundle) : nil
    }

    var captionCountText: String {
        String(format: String(localized: "posting.caption.count", bundle: #bundle), caption.count, Self.captionLimit)
    }

    /// Why Post is off, shown under the button. Nil when it can post.
    var postBlockedReason: String? {
        if !HangoutRules.canPost(visitedCount: visitedCount) {
            return String(format: String(localized: "posting.blocked.spots", bundle: #bundle),
                          HangoutRules.minimumVisitedToPost)
        }
        return titleError ?? captionError
    }

    var canPost: Bool { run != nil && postBlockedReason == nil && !isPosting }

    /// A private profile's posts are always friends-only, whatever is picked.
    var privateNote: String? {
        session.currentUser?.isPrivate == true ? String(localized: "posting.audience.private", bundle: #bundle) : nil
    }

    var publicWarning: String { String(localized: "posting.audience.warning", bundle: #bundle) }
    var publicConfirmTitle: String { String(localized: "posting.audience.confirm", bundle: #bundle) }
    var publicConfirmButton: String { String(localized: "posting.audience.confirm.yes", bundle: #bundle) }

    // MARK: View-ready values

    var includedRows: [ComposerPhotoRow] { rows(included) }
    var setAsideRows: [ComposerPhotoRow] { rows(setAside) }

    private func rows(_ list: [Photo]) -> [ComposerPhotoRow] {
        list.enumerated().map { index, photo in
            ComposerPhotoRow(
                id: photo.id, url: photos.url(for: photo), isCover: photo.id == coverID,
                label: String(format: String(localized: "posting.photo.label", bundle: #bundle), index + 1))
        }
    }

    /// The live preview: the post as friends will see it. No day and no time until it is really posted.
    var previewCard: PostCardData? {
        guard let run else { return nil }
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let cover = included.first { $0.id == coverID } ?? included.first
        return PostCardData(
            id: run.id, title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            authorName: run.card.runnerDisplayName, username: "@\(run.card.runnerUsername)",
            visitedSummary: ComponentStrings.visitedSpots(run.visits.count, of: run.card.totalSpots),
            budgetText: run.card.budgetPerPerson.formattedPerPerson,
            caption: trimmedCaption.isEmpty ? nil : trimmedCaption, coverURL: cover.flatMap { photos.url(for: $0) },
            durationText: run.durationMinutes.map { DisplayFormat.roundedDuration(minutes: $0) })
    }

    // MARK: Loading

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        await libraryStore.ensureLoaded()
        if let error = libraryStore.lastError, !libraryStore.hasLoaded {
            if case .loaded = state { return }   // a failed refresh keeps what is on screen
            state = .failed(error)
            return
        }
        guard let found = libraryStore.finishedRuns.first(where: { $0.id == runID && $0.state == .done }) else {
            state = .failed(.notFound)
            return
        }
        guard !hasLoaded else { return }   // a refresh never throws away what the person typed
        fill(from: found)
        hasLoaded = true
        state = .loaded(found.id)
    }

    private func fill(from found: HangoutRun) {
        run = found
        title = found.title ?? found.card.hangoutTitle
        caption = found.caption ?? ""
        let limit = HangoutRules.maxPhotos(visitedCount: found.visits.count)
        included = Array(found.photos.prefix(limit))
        setAside = Array(found.photos.dropFirst(limit))
        coverID = included.contains { $0.id == found.coverPhotoID } ? found.coverPhotoID : included.first?.id
        tags = Set(found.tags).intersection(Self.tagIDs)
        visibility = found.visibility
    }

    // MARK: What the person does

    func toggleTag(_ id: String) {
        if tags.contains(id) { tags.remove(id) } else { tags.insert(id) }
    }

    /// Friends is chosen at once; Public asks first (`publicConfirmed`).
    func audienceTapped(_ choice: Visibility) {
        if choice == .public && visibility != .public {
            isConfirmingPublic = true
        } else {
            visibility = choice
        }
    }

    func publicConfirmed() {
        isConfirmingPublic = false
        visibility = .public
    }

    func coverTapped(_ id: PhotoID) {
        guard included.contains(where: { $0.id == id }) else { return }
        coverID = id
    }

    func removePhoto(_ id: PhotoID) {
        guard let index = included.firstIndex(where: { $0.id == id }) else { return }
        setAside.append(included.remove(at: index))
        if coverID == id { coverID = included.first?.id }
    }

    func addBackPhoto(_ id: PhotoID) {
        guard canAddPhoto, let index = setAside.firstIndex(where: { $0.id == id }) else { return }
        included.append(setAside.remove(at: index))
        if coverID == nil { coverID = id }
    }

    /// Same meaning as SwiftUI's `onMove`, written without SwiftUI: `destination` counts the list before the move.
    func movePhotos(from source: IndexSet, to destination: Int) {
        let moving = source.sorted().map { included[$0] }
        let before = source.filter { $0 < destination }.count
        for index in source.sorted(by: >) { included.remove(at: index) }
        included.insert(contentsOf: moving, at: min(max(0, destination - before), included.count))
    }

    /// Schedules the post and shows it under Profile › Ready to post ("Scheduled for 8:30 pm").
    func postTapped() async {
        guard canPost, var updated = run else { return }
        isPosting = true
        defer { isPosting = false }
        let times = libraryStore.library.runTimes[updated.id]
        let ended = max(times?.endedAt ?? now(), now())
        updated.state = .scheduled
        updated.postAt = HangoutRules.earliestPostTime(endedAt: ended, delay: delay, calendar: calendar)
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.caption = trimmedCaption.isEmpty ? nil : trimmedCaption
        updated.photos = included
        updated.coverPhotoID = coverID
        updated.tags = Self.tagIDs.filter(tags.contains)
        updated.visibility = visibility
        updated.audience = session.currentUser?.isPrivate == true ? .friends : visibility
        libraryStore.updateRun(updated, times: times)
        await libraryStore.flush()
        run = updated
        router.show(.readyToPost, in: .profile)
    }
}
