import Components
import Core
import Foundation
import Models

/// D1: the Discover map. Pins for each Hangout (clustered by `PinClusterer`), category chips, the Picks strip,
/// and the selection that shows a Hangout's card (SC-D2 replaces that card later).
@MainActor @Observable
final class DiscoverMapViewModel {
    private(set) var state: LoadState<DiscoverMapContent> = .loading
    /// Picks (the team's Hangouts), Public (made by anyone else) and Friends (made by my friends). Any mix can be on;
    /// the map shows Hangouts matching at least one. None on means no filter: every Hangout shows.
    private(set) var scopes: Set<Scope> = [.picks]
    /// What the map draws right now: pins and clusters for the current zoom.
    private(set) var markers: [MapMarker] = []
    private(set) var selectedHangoutID: HangoutID?
    /// The filters sent to the repository: the map chips and the filters sheet (SC-D3) both write here.
    private(set) var filters = HangoutFilters()
    /// The applied time choice. Its minimum ("3 h or more") is applied here, after the repository answers.
    private(set) var appliedTime: TimeChoice = .any
    /// The filters sheet's working copy: edited on both of its pages, copied into `filters` only by Apply.
    private(set) var draft = HangoutFilters()
    private(set) var draftTime: TimeChoice = .any
    /// "Apply (n results)": how many Hangouts the draft matches; nil while counting or if counting failed.
    private(set) var draftResultCount: Int?
    /// A cluster the person tapped: the View zooms the camera to it, then calls `zoomHandled()`.
    private(set) var zoomRequest: PinCluster?
    /// Shows the filters sheet (SC-D3). Settable so the sheet can close itself.
    var isShowingFilters = false

    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let library: LibraryStore
    private let friends: (any FriendsRepository)?
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
        friends: (any FriendsRepository)? = nil, network: NetworkMonitor, router: Router,
        now: @escaping @Sendable () -> Date
    ) {
        self.friends = friends
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
    /// "No Hangouts here. Try zooming out." (or the Friends wording when that choice is on).
    var emptyMessage: String { scopes == [.friends] ? DiscoverMapText.emptyFriends : DiscoverMapText.empty }

    /// True when the filters sheet has changed anything: the filter icon then shows as on.
    var hasActiveFilters: Bool { filters != HangoutFilters() || appliedTime != .any }

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
            let all = Self.longEnough(try await hangouts.hangouts(near: nil, filters: filters), for: appliedTime)
            let found = await inScope(all)
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

    /// Picks, Public or Friends was tapped: it turns on or off, and the map reloads.
    func scopeTapped(_ choice: Scope) async {
        if scopes.contains(choice) { scopes.remove(choice) } else { scopes.insert(choice) }
        await fetch()
    }

    /// Keeps the Hangouts that match at least one chosen scope, in the repository's order. Friends needs the friends
    /// list; if it cannot be loaded, Friends simply matches nothing (the map never fails because of it).
    private func inScope(_ found: [Hangout]) async -> [Hangout] {
        guard !scopes.isEmpty else { return found }
        var friendIDs: Set<UserID> = []
        if scopes.contains(.friends), let list = try? await friends?.friends() {
            friendIDs = Set(list.map(\.id))
        }
        return found.filter { hangout in
            (scopes.contains(.picks) && hangout.isPick)
                || (scopes.contains(.publicAll) && !hangout.isPick)
                || (scopes.contains(.friends) && friendIDs.contains(hangout.authorID))
        }
    }

    /// Turns a category chip on or off, then asks the repository again with the new filters.
    func chipTapped(_ chip: Chip) async {
        if selectedChips.contains(chip) {
            filters.categories.subtract(chip.categories)
        } else {
            filters.categories.formUnion(chip.categories)
        }
        await fetch()
    }

    /// The map chips that are on: worked out from the applied categories, so the chips and the filters sheet
    /// always agree.
    var selectedChips: Set<Chip> { Set(Chip.allCases.filter { $0.categories.isSubset(of: filters.categories) }) }

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
            var route: [Coordinate] = []
            for spot in hangout.spots {
                if let stop = try? await places.place(id: spot.placeID) { route.append(stop.coordinate) }
            }
            pins.append(DiscoverPin(
                id: hangout.id, title: hangout.title, category: place.category, coordinate: place.coordinate,
                route: route.isEmpty ? [place.coordinate] : route, photoURL: photoURL, isPick: hangout.isPick,
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

// MARK: The filters sheet (SC-D3)

/// The sheet edits a draft copy of the filters on both of its pages. Apply copies the draft into `filters` and reloads
/// the map; closing the sheet any other way leaves `filters` as it was (the next opening starts a fresh draft).
extension DiscoverMapViewModel {
    /// What `.task(id:)` watches to recount "Apply (n results)" whenever the draft changes.
    struct DraftID: Hashable {
        let filters: HangoutFilters
        let time: TimeChoice
    }

    var draftID: DraftID { DraftID(filters: draft, time: draftTime) }

    func moreFiltersTapped() {
        draft = filters
        draftTime = appliedTime
        draftResultCount = nil
        isShowingFilters = true
    }

    // Budget

    var draftBudgetLower: Int { draft.budget?.lower ?? BudgetRange.lowest }
    var draftBudgetUpper: Int { draft.budget?.upper ?? BudgetRange.highest }
    /// "₹0–1,000"
    var draftBudgetText: String { DisplayFormat.rupeeRange(lower: draftBudgetLower, upper: draftBudgetUpper) }

    /// The full ₹0–1,000 range means "any budget", so no budget filter is sent.
    func setDraftBudget(lower: Int, upper: Int) {
        let low = max(BudgetRange.lowest, min(lower, upper))
        let high = min(BudgetRange.highest, max(lower, upper))
        let isFullRange = low == BudgetRange.lowest && high == BudgetRange.highest
        draft.budget = isFullRange ? nil : RupeeRange(lower: low, upper: high)
    }

    // Time

    func setDraftTime(_ time: TimeChoice) {
        draftTime = time
        draft.maxMinutes = time.maxMinutes
    }

    // Categories, vibes and interests (the main sheet's short lists and the "Find your Vybe" page)

    func isDraftChipSelected(_ chip: Chip) -> Bool { chip.categories.isSubset(of: draft.categories) }

    func toggleDraftChip(_ chip: Chip) {
        if isDraftChipSelected(chip) {
            draft.categories.subtract(chip.categories)
        } else {
            draft.categories.formUnion(chip.categories)
        }
    }

    func isInterestSelected(_ interest: VybeInterest) -> Bool {
        interest.categories.isSubset(of: draft.categories) && interest.vibeTags.isSubset(of: draft.vibeTags)
    }

    func toggleInterest(_ interest: VybeInterest) {
        if isInterestSelected(interest) {
            draft.categories.subtract(interest.categories)
            draft.vibeTags.subtract(interest.vibeTags)
        } else {
            draft.categories.formUnion(interest.categories)
            draft.vibeTags.formUnion(interest.vibeTags)
        }
    }

    func setDraftGoodForGroups(_ isOn: Bool) { draft.goodForGroups = isOn }

    // Reset, count, Apply

    func resetDraft() {
        draft = HangoutFilters()
        draftTime = .any
    }

    /// Counts the Hangouts the draft matches, the same way the map would show them.
    func countDraftResults() async {
        draftResultCount = nil
        do {
            let found = try await hangouts.hangouts(near: nil, filters: draft)
            draftResultCount = Self.longEnough(found, for: draftTime).count
        } catch {
            draftResultCount = nil          // the button then says "Apply" without a number
        }
    }

    func applyFilters() async {
        filters = draft
        appliedTime = draftTime
        isShowingFilters = false
        await fetch()
    }

    /// "3 h or more": `HangoutFilters` has no minimum yet, so it is applied here (the same rule for the map and the
    /// count).
    static func longEnough(_ hangouts: [Hangout], for time: TimeChoice) -> [Hangout] {
        guard let minimum = time.minMinutes else { return hangouts }
        return hangouts.filter { $0.estimatedMinutes >= minimum }
    }
}
