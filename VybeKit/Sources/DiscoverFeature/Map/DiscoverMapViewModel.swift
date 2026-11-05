import Components
import Core
import Foundation
import Models

/// One Hangout on the map: where its pin goes and what its pin and card show.
struct DiscoverPin: Equatable, Sendable, Identifiable {
    let id: HangoutID
    let title: String
    /// The first Spot's category: the pin's symbol when there is no photo.
    let category: PlaceCategory
    /// The first Spot's position.
    let coordinate: Coordinate
    let photoURL: URL?
    let isPick: Bool
    /// The card shown when the pin is selected.
    let card: HangoutCardData
}

/// Everything the map shows once loaded.
struct DiscoverMapContent: Equatable, Sendable {
    let pins: [DiscoverPin]
    /// The Picks strip at the bottom.
    let picks: [HangoutCardData]
}

/// D1: the Discover map. Pins for each Hangout (clustered by `PinClusterer`), category chips, the Picks strip,
/// and the selection that shows a Hangout's card (SC-D2 replaces that card later).
@MainActor @Observable
final class DiscoverMapViewModel {
    /// The quick category chips above the map. "More filters" (SC-D3) has everything else.
    enum Chip: CaseIterable, Sendable {
        case food
        case outdoors
        case games

        var categories: Set<PlaceCategory> {
            switch self {
            case .food: [.cafe, .streetFood, .chaiTapri, .restaurant, .dessert, .juiceShakes]
            case .outdoors: [.parkGarden, .viewpointHill, .lakeDam, .fort, .trek, .waterfall]
            case .games: [.gamingArcade, .bowling, .goKarting, .trampoline, .escapeRoom, .boardGameCafe]
            }
        }

        var title: String {
            switch self {
            case .food: DiscoverMapText.chipFood
            case .outdoors: DiscoverMapText.chipOutdoors
            case .games: DiscoverMapText.chipGames
            }
        }
    }

    private(set) var state: LoadState<DiscoverMapContent> = .loading
    /// What the map draws right now: pins and clusters for the current zoom.
    private(set) var markers: [MapMarker] = []
    private(set) var selectedHangoutID: HangoutID?
    private(set) var selectedChips: Set<Chip> = []
    /// The filters sent to the repository (the chips' categories, plus SC-D3's filters later).
    private(set) var filters = HangoutFilters()
    /// A cluster the person tapped: the View zooms the camera to it, then calls `zoomHandled()`.
    private(set) var zoomRequest: PinCluster?
    /// Shows the filters sheet (SC-D3). Settable so the sheet can close itself.
    var isShowingFilters = false

    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let library: LibraryStore
    private let network: NetworkMonitor
    private let router: Router
    private let now: @Sendable () -> Date
    private var span: (latitude: Double, longitude: Double)?
    private var hasLoaded = false

    /// Pune's calendar, for the monsoon months.
    private static let pune: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar
    }()

    /// Cheap: no loading here (ADR 005). `now` is injected, never `Date()`.
    init(
        hangouts: any HangoutRepository, places: any PlaceRepository, photos: any PhotoStore, library: LibraryStore,
        network: NetworkMonitor, router: Router, now: @escaping @Sendable () -> Date
    ) {
        self.hangouts = hangouts
        self.places = places
        self.photos = photos
        self.library = library
        self.network = network
        self.router = router
        self.now = now
    }

    /// The selected Hangout's card (SC-D2); nil when nothing is selected. Its saved state is read live from the
    /// library, so the bookmark changes the moment Save is tapped.
    var selectedCard: HangoutCardData? {
        guard let selectedHangoutID, case .loaded(let content, _) = state,
              var card = content.pins.first(where: { $0.id == selectedHangoutID })?.card else { return nil }
        card.isSaved = library.isSaved(selectedHangoutID)
        return card
    }

    /// The monsoon safety note shows June to September in Pune (PRODUCT, RISKS 7).
    var showsMonsoonNote: Bool { (6...9).contains(Self.pune.component(.month, from: now())) }

    /// The offline banner: the phone is offline, or a refresh failed and the pins are from before.
    var showsOfflineBanner: Bool {
        if network.isOffline { return true }
        if case .loaded(_, let isStale) = state { return isStale }
        return false
    }

    /// "No Hangouts here. Try zooming out.": nothing loaded, or the chips filtered every pin away.
    var showsEmptyMessage: Bool {
        switch state {
        case .empty: true
        case .loaded(let content, _): content.pins.isEmpty
        case .loading, .failed: false
        }
    }

    /// The single pins to draw at this zoom (Hangouts not inside a cluster).
    var visiblePins: [DiscoverPin] {
        markers.compactMap { marker in
            guard case .pin(let point) = marker else { return nil }
            return pin(point.id)
        }
    }

    /// The clusters to draw at this zoom.
    var visibleClusters: [PinCluster] {
        markers.compactMap { marker in
            guard case .cluster(let cluster) = marker else { return nil }
            return cluster
        }
    }

    func pin(_ id: HangoutID) -> DiscoverPin? {
        guard case .loaded(let content, _) = state else { return nil }
        return content.pins.first { $0.id == id }
    }

    // MARK: Loading

    func load() async {
        guard !hasLoaded else { return }        // .task runs again whenever the tab reappears
        await fetch()
    }

    func reload() async { await fetch() }       // the Retry button

    private func fetch() async {
        do {
            let found = try await hangouts.hangouts(near: nil, filters: filters)
            await library.ensureLoaded()        // so cards show the right saved state
            let pins = await pins(for: found)
            let picks = await pickCards()
            state = pins.isEmpty && picks.isEmpty ? .empty : .loaded(DiscoverMapContent(pins: pins, picks: picks))
            if selectedHangoutID.map({ id in !pins.contains { $0.id == id } }) == true { selectedHangoutID = nil }
            hasLoaded = true
            recluster()
        } catch is CancellationError {
            return                              // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps the pins on the map
            } else {
                state = .failed(AppError(error))          // only a first load can fail
            }
        }
    }

    // MARK: Actions

    /// Turns a category chip on or off, then asks the repository again with the new filters.
    func chipTapped(_ chip: Chip) async {
        if selectedChips.contains(chip) { selectedChips.remove(chip) } else { selectedChips.insert(chip) }
        filters.categories = selectedChips.reduce(into: Set<PlaceCategory>()) { $0.formUnion($1.categories) }
        await fetch()
    }

    func moreFiltersTapped() { isShowingFilters = true }

    /// The map's selection changed (`Map(selection:)`): a pin selects its Hangout, a cluster asks to zoom in,
    /// nil (a tap on the map) clears the selection.
    func select(markerID: String?) {
        guard let markerID else {
            selectedHangoutID = nil
            return
        }
        if let marker = markers.first(where: { $0.id == markerID }), case .cluster(let cluster) = marker {
            selectedHangoutID = nil
            zoomRequest = cluster
        } else {
            selectedHangoutID = HangoutID(markerID)
        }
    }

    func zoomHandled() { zoomRequest = nil }

    /// The camera stopped moving: recompute the clusters for the new zoom.
    func cameraChanged(latitudeSpan: Double, longitudeSpan: Double) {
        span = (latitudeSpan, longitudeSpan)
        recluster()
    }

    func cardTapped(_ id: HangoutID) { router.open(.hangout(id)) }

    /// Save on the preview card (SC-D2): saves or unsaves the selected Hangout.
    func saveTapped() async {
        guard let selectedHangoutID else { return }
        await library.toggleSave(selectedHangoutID)
    }

    /// A swipe down or the VoiceOver escape gesture on the preview card (SC-D2).
    func dismissPreview() { selectedHangoutID = nil }

    // MARK: Building the content

    private func recluster() {
        guard case .loaded(let content, _) = state else {
            markers = []
            return
        }
        let points = content.pins.map { MapPoint(id: $0.id, coordinate: $0.coordinate) }
        let visible = span ?? Self.span(around: points)
        markers = PinClusterer.cluster(points, latitudeSpan: visible.latitude, longitudeSpan: visible.longitude)
    }

    /// Before the camera reports its size, assume it frames all the pins (the View starts with `.automatic`).
    private static func span(around points: [MapPoint]) -> (latitude: Double, longitude: Double) {
        let latitudes = points.map(\.coordinate.latitude)
        let longitudes = points.map(\.coordinate.longitude)
        let minimum = 0.01                      // about 1 km, so one pin never makes a zero-size area
        return (max(minimum, (latitudes.max() ?? 0) - (latitudes.min() ?? 0)),
                max(minimum, (longitudes.max() ?? 0) - (longitudes.min() ?? 0)))
    }

    /// One pin per Hangout at its first Spot. A Hangout whose first Place cannot be found is left off the map.
    private func pins(for found: [Hangout]) async -> [DiscoverPin] {
        var pins: [DiscoverPin] = []
        for hangout in found {
            guard let first = hangout.spots.first,
                  let place = try? await places.place(id: first.placeID) else { continue }
            let photoURL = place.photos.first.flatMap(photos.url(for:))
            pins.append(DiscoverPin(
                id: hangout.id, title: hangout.title, category: place.category, coordinate: place.coordinate,
                photoURL: photoURL, isPick: hangout.isPick,
                card: HangoutCardData(hangout, coverURL: photoURL, isSaved: library.isSaved(hangout.id))))
        }
        return pins
    }

    /// The Picks strip. It is extra: if it fails, the map still shows.
    private func pickCards() async -> [HangoutCardData] {
        guard let found = try? await hangouts.picks() else { return [] }
        var cards: [HangoutCardData] = []
        for hangout in found {
            var coverURL: URL?
            if let first = hangout.spots.first, let place = try? await places.place(id: first.placeID) {
                coverURL = place.photos.first.flatMap(photos.url(for:))
            }
            cards.append(HangoutCardData(hangout, coverURL: coverURL, isSaved: library.isSaved(hangout.id)))
        }
        return cards
    }
}

/// The Discover map's text, read from DiscoverFeature's own catalog (`bundle: #bundle`, task X-3).
enum DiscoverMapText {
    static var chipFood: String { String(localized: "discover.map.chip.food", bundle: #bundle) }
    static var chipOutdoors: String { String(localized: "discover.map.chip.outdoors", bundle: #bundle) }
    static var chipGames: String { String(localized: "discover.map.chip.games", bundle: #bundle) }
    static var moreFilters: String { String(localized: "discover.map.moreFilters", bundle: #bundle) }
    static var empty: String { String(localized: "discover.map.empty", bundle: #bundle) }
    static var monsoon: String { String(localized: "discover.map.monsoon", bundle: #bundle) }
    static var picksHeader: String { String(localized: "discover.map.picksHeader", bundle: #bundle) }
}
