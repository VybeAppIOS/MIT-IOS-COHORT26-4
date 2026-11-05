import Components
import Core
import Foundation
import Models

/// One Spot of the live Hangout and its Place.
struct LiveSpot: Equatable, Sendable, Identifiable {
    let spot: Spot
    let place: Place
    var id: SpotID { spot.id }
}

/// H1: the Hangout being done right now. Big glanceable text for the current Spot, the distance to it, the next Spots,
/// Mark visited (opens H2), Minimise (the run goes on for the mini-bar) and End Hangout.
///
/// The run itself lives in `LiveHangoutStore`, so the current Spot always follows its visits. Location comes from
/// `LocationService` (the simulated walk in previews and desk demos); without it, the distance line is simply hidden
/// and the person taps Mark visited when they arrive. The live run is never visible to anyone else (RISKS 3).
@MainActor @Observable
final class LiveViewModel {
    /// A relaxed walk, as in `SimulatedLocationService`.
    static let walkingSpeed = 1.4

    private(set) var state: LoadState<[LiveSpot]> = .loading
    private(set) var hangoutTitle = ""
    /// The phone's last known position; nil without location.
    private(set) var position: Coordinate?
    /// Opens H2 (a small local sheet).
    var isShowingMarkVisited = false
    /// The Mark visited sheet's ViewModel, made when the sheet opens.
    private(set) var markVisited: MarkVisitedViewModel?
    /// "End Hangout?" while Spots remain.
    var isConfirmingEnd = false
    /// Goes up when the run ends; the View plays the `.stop` haptic.
    private(set) var endCount = 0

    let id: HangoutID
    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let liveStore: LiveHangoutStore
    private let location: any LocationService
    private let router: Router
    private let processor: PhotoProcessor
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005).
    init(
        id: HangoutID, hangouts: any HangoutRepository, places: any PlaceRepository, photos: any PhotoStore,
        liveStore: LiveHangoutStore, location: any LocationService, router: Router,
        processor: PhotoProcessor = PhotoProcessor()
    ) {
        self.id = id
        self.hangouts = hangouts
        self.places = places
        self.photos = photos
        self.liveStore = liveStore
        self.location = location
        self.router = router
        self.processor = processor
    }

    // MARK: Loading and location

    func load() async {
        guard !hasLoaded else { return }
        do {
            let hangout = try await hangouts.hangout(id: id)
            let found = try await places.spots(for: hangout)
            let byID = Dictionary(found.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let spots = hangout.spots.compactMap { spot in
                byID[spot.placeID].map { LiveSpot(spot: spot, place: $0) }
            }
            hangoutTitle = hangout.title
            state = spots.isEmpty ? .empty : .loaded(spots)
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            state = .failed(AppError(error))
        }
    }

    /// Follows the phone's position until the screen goes away. Without permission it does nothing: the distance
    /// line stays hidden and Mark visited still works.
    func followLocation() async {
        guard location.authorization != .denied, location.authorization != .restricted else { return }
        for await sample in location.updates() {
            positionChanged(sample.coordinate)
        }
    }

    func positionChanged(_ coordinate: Coordinate) { position = coordinate }

    // MARK: What the screen shows

    var spots: [LiveSpot] {
        guard case .loaded(let spots, _) = state else { return [] }
        return spots
    }

    private var visitedIDs: Set<SpotID> { Set(liveStore.run?.visits.map(\.spotID) ?? []) }

    /// The first Spot not visited yet; nil when every Spot is visited.
    var currentSpot: LiveSpot? { spots.first { !visitedIDs.contains($0.id) } }

    var remainingCount: Int { spots.count - visitedIDs.intersection(spots.map(\.id)).count }

    /// "1 of 3 visited"
    var progressText: String { LiveText.progress(spots.count - remainingCount, of: spots.count) }

    /// When the run started, for `Text(startedAt, style: .timer)` (no running timer here).
    var startedAt: Date? { liveStore.times?.startedAt }

    /// Straight-line metres from the phone to the current Spot; nil without location.
    var distanceToCurrentSpot: Double? {
        guard let position, let current = currentSpot else { return nil }
        return LiveGeometry.meters(from: position, to: current.place.coordinate)
    }

    /// "250 m · 4 min walk"; nil without location.
    var distanceText: String? {
        guard let meters = distanceToCurrentSpot else { return nil }
        let minutes = max(1, Int((meters / Self.walkingSpeed / 60).rounded(.up)))
        let walk = Duration.seconds(minutes * 60).formatted(.units(allowed: [.minutes], width: .abbreviated))
        return LiveText.distance(DisplayFormat.distance(meters: meters), walk: walk)
    }

    /// Every Spot as a row: visited ones ticked, the current one highlighted.
    var rows: [SpotRowData] {
        let currentID = currentSpot?.id
        return spots.enumerated().map { index, item in
            let rowState: SpotRowData.State = visitedIDs.contains(item.id) ? .visited
                : item.id == currentID ? .current : .normal
            return SpotRowData(spot: item.spot, place: item.place, order: index + 1, total: spots.count,
                               state: rowState, thumbnailURL: item.place.photos.first.flatMap(photos.url(for:)))
        }
    }

    // MARK: Actions

    func markVisitedTapped() {
        guard let current = currentSpot else { return }
        markVisited = MarkVisitedViewModel(
            spotID: current.id, spotName: current.place.name, isLastSpot: remainingCount == 1,
            liveStore: liveStore, processor: processor) { [weak self] in self?.isShowingMarkVisited = false }
        isShowingMarkVisited = true
    }

    /// What the Mark visited sheet (H2) calls when the person confirms: the next Spot becomes current.
    func markCurrentVisited() {
        if let current = currentSpot { liveStore.markVisited(spotID: current.id) }
        isShowingMarkVisited = false
    }

    /// Closes the live screen; the run goes on and the mini-bar (H4) brings it back.
    func minimiseTapped() {
        liveStore.minimise()
        router.dismissCover()
    }

    /// Asks first while Spots remain; otherwise ends straight away.
    func endTapped() {
        if remainingCount > 0 {
            isConfirmingEnd = true
        } else {
            endConfirmed()
        }
    }

    func endConfirmed() {
        isConfirmingEnd = false
        guard let runID = liveStore.run?.id else { return }
        liveStore.end()
        endCount += 1
        router.open(.liveSummary(runID))        // H3, pushed inside the live cover
    }
}

/// Distances on the map (Core's version lives in LocalData, which features may not import).
enum LiveGeometry {
    /// Straight-line metres between two points (haversine).
    static func meters(from start: Coordinate, to end: Coordinate) -> Double {
        let earthRadius = 6_371_000.0
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let dLat = (end.latitude - start.latitude) * .pi / 180
        let dLon = (end.longitude - start.longitude) * .pi / 180
        let half = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return earthRadius * 2 * atan2(sqrt(half), sqrt(1 - half))
    }
}

/// H1's text, read from LiveFeature's own catalog (`bundle: #bundle`, task X-3).
enum LiveText {
    static var nowHeading: String { String(localized: "live.now", bundle: #bundle) }
    static var allVisited: String { String(localized: "live.allVisited", bundle: #bundle) }
    static var markVisited: String { String(localized: "live.markVisited", bundle: #bundle) }
    static var minimise: String { String(localized: "live.minimise", bundle: #bundle) }
    static var end: String { String(localized: "live.end", bundle: #bundle) }
    static var endConfirmTitle: String { String(localized: "live.endConfirmTitle", bundle: #bundle) }
    static var endConfirmMessage: String { String(localized: "live.endConfirmMessage", bundle: #bundle) }
    static var keepGoing: String { String(localized: "live.keepGoing", bundle: #bundle) }
    static var spotsHeader: String { String(localized: "live.spotsHeader", bundle: #bundle) }

    /// "250 m · 4 min walk"
    static func distance(_ distance: String, walk: String) -> String {
        String(localized: "live.distance \(distance) \(walk)", bundle: #bundle)
    }

    /// "1 of 3 visited"
    static func progress(_ visited: Int, of total: Int) -> String {
        String(localized: "live.progress \(visited) \(total)", bundle: #bundle)
    }

}
