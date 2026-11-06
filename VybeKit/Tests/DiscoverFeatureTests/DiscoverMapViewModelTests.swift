import Core
import Foundation
import Models
import Testing
@testable import DiscoverFeature

/// A Hangout repository that filters by category like the real one, remembers the filters it was asked for,
/// counts loads, and can start failing. An actor, so it is safe to share across concurrency domains.
private actor FilteringHangouts: HangoutRepository {
    private let all: [Hangout]
    private let categories: [PlaceID: PlaceCategory]
    private(set) var lastFilters: HangoutFilters?
    private(set) var loads = 0
    private var failing = false

    init(hangouts: [Hangout], places: [Place]) {
        all = hangouts
        categories = Dictionary(places.map { ($0.id, $0.category) }, uniquingKeysWith: { first, _ in first })
    }

    func startFailing() { failing = true }

    func hangouts(near center: Coordinate?, filters: HangoutFilters) async throws -> [Hangout] {
        loads += 1
        lastFilters = filters
        if failing { throw AppError.offline }
        guard !filters.categories.isEmpty else { return all }
        return all.filter { hangout in
            !Set(hangout.spots.compactMap { categories[$0.placeID] }).isDisjoint(with: filters.categories)
        }
    }

    func hangout(id: HangoutID) async throws -> Hangout {
        guard let found = all.first(where: { $0.id == id }) else { throw AppError.notFound }
        return found
    }

    func picks() async throws -> [Hangout] { all.filter(\.isPick) }
    func remixes(of id: HangoutID) async throws -> [Hangout] { [] }
    func stats(for id: HangoutID) async throws -> HangoutStats { HangoutStats(doneCount: 0, remixCount: 0) }
}

@MainActor
struct DiscoverMapViewModelTests {
    private let cafe = SampleData.cafe
    private let park = SampleData.park

    /// An EXAMPLE Hangout whose only Spot is the park: it matches "Outdoors" but not "Cafés & food".
    private var parkOnly: Hangout {
        Hangout(
            id: "hangout-example-park-only", title: "EXAMPLE Park Hangout", summary: "EXAMPLE",
            spots: [Spot(id: "s1", placeID: park.id)], budgetPerPerson: RupeeRange(lower: 0, upper: 0),
            estimatedMinutes: 60, bestTimes: [], tags: [], vibeTags: [], authorID: SampleData.friend.id,
            createdAt: SampleData.day, updatedAt: SampleData.day)
    }

    private func makeViewModel(
        _ deps: AppDependencies = .preview(), hangouts: (any HangoutRepository)? = nil,
        now: (@Sendable () -> Date)? = nil
    ) -> DiscoverMapViewModel {
        DiscoverMapViewModel(
            hangouts: hangouts ?? deps.hangouts, places: deps.places, photos: deps.photos,
            library: deps.libraryStore, friends: deps.friends, network: deps.network, router: deps.router,
            now: now ?? deps.now)
    }

    /// The map opens on Picks; these tests are about every Hangout, so they switch to Public first.
    private func loadPublic(_ viewModel: DiscoverMapViewModel) async {
        await viewModel.load()
        await viewModel.scopeTapped(.publicAll)
    }

    private func filtering() -> FilteringHangouts {
        FilteringHangouts(hangouts: SampleData.hangouts + [parkOnly], places: [cafe, park])
    }

    private func pinIDs(_ viewModel: DiscoverMapViewModel) -> Set<HangoutID> {
        guard case .loaded(let content, _) = viewModel.state else { return [] }
        return Set(content.pins.map(\.id))
    }

    private func pune(month: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar.date(from: DateComponents(year: 2026, month: month, day: 15, hour: 12)) ?? SampleData.day
    }

    // MARK: Loading

    @Test func loadPutsEachHangoutAtItsFirstSpotAndFillsThePicks() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        guard case .loaded(let content, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        let evening = try #require(content.pins.first { $0.id == SampleData.evening.id })
        #expect(evening.coordinate == cafe.coordinate)          // the Evening Hangout starts at the café
        #expect(evening.category == .cafe)
        #expect(evening.isPick)
        #expect(content.picks.map(\.id) == [SampleData.evening.id])
        #expect(!viewModel.markers.isEmpty)
    }

    @Test func loadRunsOnlyOnce() async {
        let hangouts = filtering()
        let viewModel = makeViewModel(hangouts: hangouts)
        await viewModel.load()
        await viewModel.load()
        #expect(await hangouts.loads == 1)
    }

    // MARK: Filtering (task SC-D1)

    @Test func aChipSendsItsCategoriesAndThePinsUpdate() async {
        let hangouts = filtering()
        let viewModel = makeViewModel(hangouts: hangouts)
        await loadPublic(viewModel)
        #expect(pinIDs(viewModel).contains(parkOnly.id))
        await viewModel.chipTapped(.food)
        #expect(await hangouts.lastFilters?.categories == DiscoverMapViewModel.Chip.food.categories)
        #expect(pinIDs(viewModel) == [SampleData.evening.id, SampleData.morning.id])
    }

    @Test func tappingAChipAgainClearsIt() async {
        let hangouts = filtering()
        let viewModel = makeViewModel(hangouts: hangouts)
        await loadPublic(viewModel)
        await viewModel.chipTapped(.food)
        await viewModel.chipTapped(.food)
        #expect(viewModel.selectedChips.isEmpty)
        #expect(await hangouts.lastFilters?.categories.isEmpty == true)
        #expect(pinIDs(viewModel).contains(parkOnly.id))
    }

    @Test func twoChipsAskForBothSetsOfCategories() async {
        let hangouts = filtering()
        let viewModel = makeViewModel(hangouts: hangouts)
        await viewModel.load()
        await viewModel.chipTapped(.food)
        await viewModel.chipTapped(.outdoors)
        let expected = DiscoverMapViewModel.Chip.food.categories.union(DiscoverMapViewModel.Chip.outdoors.categories)
        #expect(await hangouts.lastFilters?.categories == expected)
    }

    @Test func aChipWithNoMatchesShowsTheEmptyMessage() async {
        let viewModel = makeViewModel(hangouts: filtering())
        await viewModel.load()
        await viewModel.chipTapped(.games)
        #expect(pinIDs(viewModel).isEmpty)
        #expect(viewModel.showsEmptyMessage)
        #expect(DiscoverMapText.empty == "No Hangouts here. Try zooming out.")
    }

    // MARK: Picks, Public, Friends

    @Test func theMapOpensOnPicksAndPublicShowsEveryHangout() async {
        let viewModel = makeViewModel(hangouts: filtering())
        await viewModel.load()
        #expect(viewModel.scope == .picks)
        #expect(pinIDs(viewModel) == [SampleData.evening.id])           // only the team's Picks
        await viewModel.scopeTapped(.publicAll)
        #expect(viewModel.scope == .publicAll)
        #expect(pinIDs(viewModel).contains(parkOnly.id))
        #expect(pinIDs(viewModel).count > 1)
    }

    @Test func tappingTheScopeThatIsAlreadyOnDoesNotReload() async {
        let hangouts = filtering()
        let viewModel = makeViewModel(hangouts: hangouts)
        await viewModel.load()
        await viewModel.scopeTapped(.picks)
        #expect(await hangouts.loads == 1)
    }

    @Test func friendsShowsOnlyHangoutsMadeByMyFriends() async throws {
        let deps = AppDependencies.preview()
        let friendIDs = Set(try await deps.friends.friends().map(\.id))
        let all = SampleData.hangouts + [parkOnly]
        let viewModel = makeViewModel(deps, hangouts: filtering())
        await viewModel.load()
        await viewModel.scopeTapped(.friends)
        #expect(pinIDs(viewModel) == Set(all.filter { friendIDs.contains($0.authorID) }.map(\.id)))
        if pinIDs(viewModel).isEmpty {
            #expect(viewModel.emptyMessage == DiscoverMapText.emptyFriends)
        }
    }

    @Test func aPinKnowsEverySpotOfItsHangout() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        guard case .loaded(let content, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        let evening = try #require(content.pins.first { $0.id == SampleData.evening.id })
        #expect(evening.route.count == SampleData.evening.spots.count)    // one dot per Spot, in order
        #expect(evening.route.first == evening.coordinate)
    }

    // MARK: States

    @Test func noHangoutsAtAllIsEmpty() async {
        let viewModel = makeViewModel(.preview(.empty))
        await viewModel.load()
        #expect(viewModel.state == .empty)
        #expect(viewModel.showsEmptyMessage)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = makeViewModel(.preview(.failing))
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func aFailedRefreshKeepsThePinsAsStale() async {
        let hangouts = filtering()
        let viewModel = makeViewModel(hangouts: hangouts)
        await viewModel.load()
        let before = pinIDs(viewModel)
        await hangouts.startFailing()
        await viewModel.chipTapped(.food)
        guard case .loaded(_, let isStale) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        #expect(isStale)
        #expect(pinIDs(viewModel) == before)
        #expect(viewModel.showsOfflineBanner)
    }

    @Test func offlineShowsTheBanner() async {
        let deps = AppDependencies.preview()
        deps.network.forceOffline(true)
        let viewModel = makeViewModel(deps)
        await viewModel.load()
        #expect(viewModel.showsOfflineBanner)
    }

    // MARK: Selection and clusters

    @Test func selectingAPinShowsItsCardAndAMapTapClearsIt() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.select(markerID: SampleData.evening.id.rawValue)
        #expect(viewModel.selectedCard?.id == SampleData.evening.id)
        viewModel.select(markerID: nil)
        #expect(viewModel.selectedCard == nil)
    }

    @Test func zoomingInSplitsTheSampleClusterAndTappingAClusterAsksToZoom() async throws {
        let viewModel = makeViewModel()
        await loadPublic(viewModel)
        viewModel.cameraChanged(latitudeSpan: 1, longitudeSpan: 1)            // the café and park merge
        let cluster = try #require(viewModel.visibleClusters.first)
        #expect(viewModel.visiblePins.isEmpty)
        viewModel.select(markerID: cluster.id)
        #expect(viewModel.zoomRequest == cluster)
        #expect(viewModel.selectedHangoutID == nil)
        viewModel.zoomHandled()
        #expect(viewModel.zoomRequest == nil)
        viewModel.cameraChanged(latitudeSpan: 0.001, longitudeSpan: 0.001)    // close up: they separate
        #expect(viewModel.visibleClusters.isEmpty)
        #expect(viewModel.visiblePins.count == 2)
    }

    // MARK: Actions

    @Test func tappingACardOpensTheHangout() {
        let deps = AppDependencies.preview()
        makeViewModel(deps).cardTapped(SampleData.evening.id)
        #expect(deps.router.path(for: deps.router.currentStack) == [.hangout(SampleData.evening.id)])
    }

    @Test func moreFiltersOpensTheFiltersSheet() {
        let viewModel = makeViewModel()
        viewModel.moreFiltersTapped()
        #expect(viewModel.isShowingFilters)
    }

    @Test func theMonsoonNoteShowsJuneToSeptember() {
        let july = pune(month: 7)
        let november = pune(month: 11)
        #expect(makeViewModel(now: { july }).showsMonsoonNote)
        #expect(!makeViewModel(now: { november }).showsMonsoonNote)
    }

    @Test func textsResolveToRealText() {
        #expect(DiscoverMapText.chipFood == "Cafés & food")
        #expect(DiscoverMapText.moreFilters == "More filters")
        #expect(DiscoverMapText.picksHeader == "Picks")
    }
}
