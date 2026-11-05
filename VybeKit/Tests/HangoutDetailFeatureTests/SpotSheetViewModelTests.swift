import Core
import Foundation
import Models
import Testing
@testable import HangoutDetailFeature

/// A Place repository that counts loads and can start failing, to check "load once" and "a failed refresh keeps
/// the content". An actor, so it is safe to share across concurrency domains.
private actor ScriptedPlaces: PlaceRepository {
    private let base: StubPlaceRepository
    private(set) var loads = 0
    private var failing = false

    init(places: [Place]) { base = StubPlaceRepository(places: places) }

    func startFailing() { failing = true }

    func place(id: PlaceID) async throws -> Place {
        loads += 1
        if failing { throw AppError.offline }
        return try await base.place(id: id)
    }

    func places(in area: String) async throws -> [Place] { try await base.places(in: area) }
    func spots(for hangout: Hangout) async throws -> [Place] { try await base.spots(for: hangout) }
}

@MainActor
struct SpotSheetViewModelTests {
    private let cafe = Place.previewOpen

    private func makeViewModel(
        _ deps: AppDependencies = .preview(), place: Place = .previewOpen, id: PlaceID? = nil,
        places: (any PlaceRepository)? = nil, hangouts: (any HangoutRepository)? = nil
    ) -> SpotSheetViewModel {
        SpotSheetViewModel(
            id: id ?? place.id, places: places ?? StubPlaceRepository(places: [place, SampleData.park]),
            hangouts: hangouts ?? deps.hangouts, photos: deps.photos, library: deps.libraryStore,
            router: deps.router, now: deps.now)
    }

    private func content(_ viewModel: SpotSheetViewModel) throws -> SpotSheetContent {
        guard case .loaded(let content, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            throw AppError.unknown
        }
        return content
    }

    /// A published Hangout over the given Places (titles are EXAMPLE text).
    private func hangout(_ suffix: String, places: [Place], isPick: Bool = false) -> Hangout {
        Hangout(
            id: HangoutID("hangout-example-\(suffix)"), title: "EXAMPLE \(suffix)", summary: "EXAMPLE",
            spots: places.enumerated().map { Spot(id: SpotID("s\($0.offset)"), placeID: $0.element.id) },
            budgetPerPerson: RupeeRange(lower: 100, upper: 200), estimatedMinutes: 60, bestTimes: [], tags: [],
            vibeTags: [], authorID: SampleData.friend.id, isPick: isPick, createdAt: SampleData.day,
            updatedAt: SampleData.day)
    }

    // MARK: Loading

    @Test func loadShowsThePlace() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        let content = try content(viewModel)
        #expect(content.name == cafe.name)
        #expect(content.address == cafe.address)
        #expect(content.costText == cafe.costPerPerson.formattedPerPerson)
        #expect(content.photos.map(\.credit) == cafe.photos.map(\.credit))
        #expect(content.applePlaceID == cafe.applePlaceID)
        #expect(!content.isClosedByAuthorities)
        #expect(content.trekNote == nil)
        #expect(content.hoursText.hasPrefix("Open until"))      // the preview clock is a Tuesday afternoon
    }

    @Test func loadRunsOnlyOnce() async {
        let places = ScriptedPlaces(places: [cafe, SampleData.park])
        let viewModel = makeViewModel(places: places)
        await viewModel.load()
        let afterFirst = await places.loads
        await viewModel.load()
        #expect(await places.loads == afterFirst)
    }

    @Test func aMissingPlaceShowsNotFound() async {
        let viewModel = makeViewModel(id: "place-missing-0000")
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = makeViewModel(places: StubPlaceRepository(mode: .failing))
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func aFailedRefreshKeepsTheContentAsStale() async throws {
        let places = ScriptedPlaces(places: [cafe, SampleData.park])
        let viewModel = makeViewModel(places: places)
        await viewModel.load()
        let before = try content(viewModel)
        await places.startFailing()
        await viewModel.reload()
        #expect(viewModel.state == .loaded(before, isStale: true))
    }

    // MARK: Content rules

    @Test func noAppleIDHidesTheButton() async throws {
        let viewModel = makeViewModel(place: .previewNoAppleID)
        await viewModel.load()
        #expect(try content(viewModel).applePlaceID == nil)
    }

    @Test func closedByAuthoritiesIsShown() async throws {
        let viewModel = makeViewModel(place: .previewClosedByAuthorities)
        await viewModel.load()
        #expect(try content(viewModel).isClosedByAuthorities)
    }

    @Test func aTrekShowsItsOwnSafetyNote() async throws {
        let viewModel = makeViewModel(place: .previewTrek)
        await viewModel.load()
        #expect(try content(viewModel).trekNote == Place.previewTrek.trekInfo?.safetyNote)
    }

    @Test func aTrekWithoutTrekInfoShowsTheStandardNote() async throws {
        var trek = cafe
        trek.category = .trek
        let viewModel = makeViewModel(place: trek)
        await viewModel.load()
        #expect(try content(viewModel).trekNote == SpotSheetText.trekSafety)
    }

    @Test func noHoursShowsTheHoursNote() async throws {
        let viewModel = makeViewModel(place: SampleData.park)
        await viewModel.load()
        #expect(try content(viewModel).hoursText == SampleData.park.hoursNote)
    }

    @Test func atMostThreeHangoutsWithThisPlacePicksFirst() async throws {
        let all = [hangout("a", places: [cafe, SampleData.park]), hangout("b", places: [SampleData.park, cafe]),
                   hangout("c", places: [cafe, SampleData.park]), hangout("pick", places: [SampleData.park, cafe],
                                                                          isPick: true),
                   hangout("other", places: [SampleData.park])]
        let viewModel = makeViewModel(hangouts: StubHangoutRepository(hangouts: all))
        await viewModel.load()
        let cards = try content(viewModel).hangouts
        #expect(cards.count == SpotSheetViewModel.maxHangouts)
        #expect(cards.first?.id == "hangout-example-pick")
        #expect(!cards.map(\.id).contains("hangout-example-other"))
    }

    @Test func aFailedHangoutListStillShowsThePlace() async throws {
        let viewModel = makeViewModel(hangouts: StubHangoutRepository(mode: .failing))
        await viewModel.load()
        #expect(try content(viewModel).hangouts.isEmpty)
    }

    // MARK: Navigation

    @Test func tappingAHangoutClosesTheSheetThenOpensIt() {
        let deps = AppDependencies.preview()
        deps.router.present(.spot(cafe.id))
        makeViewModel(deps).hangoutTapped(SampleData.evening.id)
        #expect(deps.router.sheet == nil)
        #expect(deps.router.path(for: deps.router.currentStack) == [.hangout(SampleData.evening.id)])
    }

    @Test func reportIsPushedInsideTheSheet() {
        let deps = AppDependencies.preview()
        deps.router.present(.spot(cafe.id))
        makeViewModel(deps).reportTapped()
        #expect(deps.router.sheet == .spot(cafe.id))
        #expect(deps.router.path(for: .sheet) == [.report(.place(cafe.id))])
    }

    @Test func textsResolveToRealText() {
        #expect(SpotSheetText.notFound == "This Spot is no longer available.")
        #expect(SpotSheetText.closedToday == "Closed today")
        #expect(SpotSheetText.openUntil("10:00 PM") == "Open until 10:00 PM")
        #expect(SpotSheetText.opensAt("9:00 AM") == "Opens at 9:00 AM")
    }
}
