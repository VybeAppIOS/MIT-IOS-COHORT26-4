import Components
import Core
import Foundation
import Models

/// Everything Hangout detail shows, already as display text (never a raw model).
struct HangoutDetailContent: Equatable, Sendable {
    /// One Spot row and the Place it opens when tapped.
    struct SpotItem: Equatable, Sendable, Identifiable {
        let row: SpotRowData
        let placeID: PlaceID
        var id: SpotID { row.id }
    }

    let title: String
    let summary: String
    let isPick: Bool
    let photos: [GalleryPhoto]
    /// "₹150–400"
    let budgetText: String
    /// "about 2 hr"
    let durationText: String
    /// "Evening", nil when the Hangout gives no best time.
    let bestTimeText: String?
    let tags: [String]
    let spots: [SpotItem]
    /// "Remixed from @x", nil when this is not a Remix or the original's author cannot be found.
    let remixCredit: String?
    /// True when any Spot is a trek: the screen then shows the trek safety note.
    let hasTrek: Bool
    /// What Share sends: the title and "Find it on Vybe".
    let shareText: String
}

/// HD1: one Hangout, its Spots and its actions. This is the golden example the other screens copy.
@MainActor @Observable
final class HangoutDetailViewModel {
    /// What the main button says and whether it works.
    enum StartButton: Equatable {
        case start
        /// A run of this Hangout is live.
        case resume
        /// A run of another Hangout is live: finish that one first.
        case otherHangoutLive
        /// Starting needs a connection.
        case offline
    }

    private(set) var state: LoadState<HangoutDetailContent> = .loading
    private(set) var isStarting = false
    /// Why the last Start failed, shown under the button.
    private(set) var startError: String?
    /// Goes up each time Start succeeds; the View plays the Start haptic when it changes.
    private(set) var startCount = 0
    let id: HangoutID

    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let profiles: any ProfileRepository
    private let photos: any PhotoStore
    private let library: LibraryStore
    private let liveStore: LiveHangoutStore
    private let network: NetworkMonitor
    private let router: Router
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Take only what the screen needs, never `AppDependencies`.
    init(
        id: HangoutID, hangouts: any HangoutRepository, places: any PlaceRepository, profiles: any ProfileRepository,
        photos: any PhotoStore, library: LibraryStore, liveStore: LiveHangoutStore, network: NetworkMonitor,
        router: Router
    ) {
        self.id = id
        self.hangouts = hangouts
        self.places = places
        self.profiles = profiles
        self.photos = photos
        self.library = library
        self.liveStore = liveStore
        self.network = network
        self.router = router
    }

    var isSaved: Bool { library.isSaved(id) }

    var startButton: StartButton {
        if let run = liveStore.run { return run.hangoutID == id ? .resume : .otherHangoutLive }
        return network.isOffline ? .offline : .start
    }

    func load() async {
        guard !hasLoaded else { return }        // .task runs again whenever the screen reappears
        await fetch()
    }

    func reload() async { await fetch() }       // pull to refresh and the Retry button

    private func fetch() async {
        do {
            let hangout = try await hangouts.hangout(id: id)
            let spotPlaces = try await places.spots(for: hangout)
            await library.ensureLoaded()        // so the Save button shows the right state
            let credit = await remixCredit(for: hangout)
            state = .loaded(content(hangout, places: spotPlaces, remixCredit: credit))
            hasLoaded = true
        } catch is CancellationError {
            return                              // leaving the screen is not an error (ADR 005)
        } catch {
            let appError = AppError(error)
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else if appError == .notFound {
                state = .empty                            // "This Hangout is no longer available"
            } else {
                state = .failed(appError)                 // only a first load can fail
            }
        }
    }

    // MARK: Actions

    func startTapped() async {
        guard startButton == .start || startButton == .resume, !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        do {
            try await liveStore.startOrResume(hangoutID: id)   // creates the run, or resumes the live one
            startError = nil
            startCount += 1
            router.presentCover(.live(id))
        } catch is CancellationError {
            return
        } catch {
            startError = AppError(error).message
        }
    }

    func saveTapped() async { await library.toggleSave(id) }

    func spotTapped(_ placeID: PlaceID) { router.present(.spot(placeID)) }

    func remixCreditTapped() { router.open(.remixTree(id)) }

    func remixTapped() { router.presentCover(.editor(.remix(id))) }

    func reportTapped() { router.present(.report(.hangout(id))) }

    // MARK: Building the content

    /// "Remixed from @x". A missing original or author only hides the line; it never fails the screen.
    private func remixCredit(for hangout: Hangout) async -> String? {
        guard let originalID = hangout.remixedFromID,
              let original = try? await hangouts.hangout(id: originalID),
              let author = try? await profiles.profile(id: original.authorID) else { return nil }
        return HangoutDetailText.remixedFrom(author.username)
    }

    private func content(_ hangout: Hangout, places: [Place], remixCredit: String?) -> HangoutDetailContent {
        let placesByID = Dictionary(places.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let pairs = hangout.spots.compactMap { spot in placesByID[spot.placeID].map { (spot, $0) } }
        let items = pairs.enumerated().map { index, pair in
            HangoutDetailContent.SpotItem(
                row: SpotRowData(spot: pair.0, place: pair.1, order: index + 1, total: pairs.count,
                                 thumbnailURL: pair.1.photos.first.flatMap(photos.url(for:))),
                placeID: pair.1.id)
        }
        let gallery = pairs.compactMap { _, place in
            place.photos.first.map {
                GalleryPhoto(id: $0.id.rawValue, url: photos.url(for: $0), credit: $0.credit, description: place.name)
            }
        }
        return HangoutDetailContent(
            title: hangout.title, summary: hangout.summary, isPick: hangout.isPick, photos: gallery,
            budgetText: hangout.budgetPerPerson.formattedPerPerson,
            durationText: DisplayFormat.roundedDuration(minutes: hangout.estimatedMinutes),
            bestTimeText: hangout.bestTimes.first.map(Self.displayWord), tags: hangout.tags.map(Self.displayWord),
            spots: items, remixCredit: remixCredit,
            hasTrek: pairs.contains { $0.1.category == .trek || $0.1.trekInfo != nil },
            shareText: HangoutDetailText.share(hangout.title))
    }

    /// Content words are stored as slugs ("good-for-groups"); show them as words ("Good for groups").
    static func displayWord(_ slug: String) -> String {
        let words = slug.replacing("-", with: " ")
        return words.prefix(1).uppercased() + words.dropFirst()
    }
}

/// Hangout detail's text, read from HangoutDetailFeature's own catalog (`bundle: #bundle`, task X-3).
enum HangoutDetailText {
    static var start: String { String(localized: "hangoutDetail.start", bundle: #bundle) }
    static var resume: String { String(localized: "hangoutDetail.resume", bundle: #bundle) }
    static var otherHangoutLive: String { String(localized: "hangoutDetail.otherHangoutLive", bundle: #bundle) }
    static var offline: String { String(localized: "hangoutDetail.offline", bundle: #bundle) }
    static var save: String { String(localized: "hangoutDetail.save", bundle: #bundle) }
    static var saved: String { String(localized: "hangoutDetail.saved", bundle: #bundle) }
    static var share: String { String(localized: "hangoutDetail.shareButton", bundle: #bundle) }
    static var more: String { String(localized: "hangoutDetail.more", bundle: #bundle) }
    static var remix: String { String(localized: "hangoutDetail.remix", bundle: #bundle) }
    static var report: String { String(localized: "hangoutDetail.report", bundle: #bundle) }
    static var spotsHeader: String { String(localized: "hangoutDetail.spotsHeader", bundle: #bundle) }
    static var notFound: String { String(localized: "hangoutDetail.notFound", bundle: #bundle) }
    static var trekSafety: String { String(localized: "hangoutDetail.trekSafety", bundle: #bundle) }

    /// "Remixed from @riya"
    static func remixedFrom(_ username: String) -> String {
        String(localized: "hangoutDetail.remixedFrom \(username)", bundle: #bundle)
    }

    /// The title, then "Find it on Vybe" on the next line.
    static func share(_ title: String) -> String {
        String(localized: "hangoutDetail.shareText \(title)", bundle: #bundle)
    }
}
