import Core
import Foundation
import Models

/// H3: the ended Hangout. "You visited 3 of 5 Spots", a rounded length (never exact times), an approximate distance,
/// the run's photos (remove allowed), then Post (only from 2 visited Spots) or Not now.
///
/// The run is read from `LibraryStore` (after End it is `done`, "Ready to post"). The distance is the straight line
/// between the visited Spots' Places in visit order: no GPS route is ever stored (RISKS 3).
@MainActor @Observable
final class SummaryViewModel {
    private(set) var state: LoadState<Double> = .loading     // the approximate distance in metres, once loaded
    let runID: RunID

    private let library: LibraryStore
    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let router: Router
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005).
    init(runID: RunID, library: LibraryStore, places: any PlaceRepository, photos: any PhotoStore, router: Router) {
        self.runID = runID
        self.library = library
        self.places = places
        self.photos = photos
        self.router = router
    }

    /// The run, read live from the library, so a removed photo disappears at once.
    var run: HangoutRun? { library.library.runs.first { $0.id == runID } }

    func load() async {
        guard !hasLoaded else { return }
        await library.ensureLoaded()
        guard let run else {
            state = .failed(.notFound)
            return
        }
        var stops: [Coordinate] = []
        for visit in run.visits.sorted(by: { $0.order < $1.order }) {
            if let place = try? await places.place(id: visit.placeID) { stops.append(place.coordinate) }
        }
        let meters = zip(stops, stops.dropFirst()).reduce(0) { $0 + LiveGeometry.meters(from: $1.0, to: $1.1) }
        state = .loaded(meters)
        hasLoaded = true
    }

    // MARK: What the screen shows

    var visitedCount: Int { run?.visits.count ?? 0 }
    var totalSpots: Int { run?.card.totalSpots ?? 0 }

    /// "You visited 3 of 5 Spots"
    var visitedText: String { SummaryText.visited(visitedCount, of: totalSpots) }

    /// "about 3 h", never an exact time.
    var durationText: String? { run?.durationMinutes.map(HangoutRules.roundedDuration) }

    var distanceMeters: Double {
        guard case .loaded(let meters, _) = state else { return 0 }
        return meters
    }

    /// "about 1.2 km"
    var distanceText: String { SummaryText.about(DisplayFormat.distance(meters: distanceMeters)) }

    var photoURLs: [(id: PhotoID, url: URL?)] {
        (run?.photos ?? []).map { ($0.id, photos.url(for: $0)) }
    }

    var canPost: Bool { HangoutRules.canPost(visitedCount: visitedCount) }

    /// "Visit at least 2 Spots to post"; nil when posting is allowed.
    var postBlockedReason: String? { canPost ? nil : SummaryText.postBlocked }

    // MARK: Actions

    func removePhoto(_ id: PhotoID) {
        guard var changed = run else { return }
        changed.photos.removeAll { $0.id == id }
        library.updateRun(changed, times: library.library.runTimes[runID])
    }

    /// Opens the post composer (PO1) on the live stack.
    func postTapped() {
        guard canPost else { return }
        router.open(.composePost(runID))
    }

    /// The run stays Done ("Ready to post"); the cover closes onto Discover.
    func notNowTapped() { router.show(nil, in: .discover) }
}

/// H3's text, read from LiveFeature's own catalog (`bundle: #bundle`, task X-3).
enum SummaryText {
    static var title: String { String(localized: "live.summary.title", bundle: #bundle) }
    static var spotsLabel: String { String(localized: "live.summary.spotsLabel", bundle: #bundle) }
    static var distanceLabel: String { String(localized: "live.summary.distanceLabel", bundle: #bundle) }
    static var timeLabel: String { String(localized: "live.summary.timeLabel", bundle: #bundle) }
    static var photosHeader: String { String(localized: "live.summary.photosHeader", bundle: #bundle) }
    static var noPhotos: String { String(localized: "live.summary.noPhotos", bundle: #bundle) }
    static var post: String { String(localized: "live.summary.post", bundle: #bundle) }
    static var notNow: String { String(localized: "live.summary.notNow", bundle: #bundle) }
    static var postBlocked: String { String(localized: "live.summary.postBlocked", bundle: #bundle) }
    static var removePhoto: String { String(localized: "live.summary.removePhoto", bundle: #bundle) }

    /// "You visited 3 of 5 Spots"
    static func visited(_ visited: Int, of total: Int) -> String {
        String(localized: "live.summary.visited \(visited) \(total)", bundle: #bundle)
    }

    /// "about 1.2 km"
    static func about(_ distance: String) -> String {
        String(localized: "live.summary.about \(distance)", bundle: #bundle)
    }
}
