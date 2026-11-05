import Core
import Models
import Testing
@testable import HangoutDetailFeature

/// A Hangout repository that counts loads and can start failing, to check "load once" and "a failed refresh
/// keeps the content". An actor, so it is safe to share across concurrency domains.
private actor ScriptedHangouts: HangoutRepository {
    private let base = StubHangoutRepository()
    private(set) var loads = 0
    private var failing = false

    func startFailing() { failing = true }

    func hangout(id: HangoutID) async throws -> Hangout {
        loads += 1
        if failing { throw AppError.offline }
        return try await base.hangout(id: id)
    }

    func hangouts(near center: Coordinate?, filters: HangoutFilters) async throws -> [Hangout] {
        try await base.hangouts(near: center, filters: filters)
    }

    func picks() async throws -> [Hangout] { try await base.picks() }
    func remixes(of id: HangoutID) async throws -> [Hangout] { try await base.remixes(of: id) }
    func stats(for id: HangoutID) async throws -> HangoutStats { try await base.stats(for: id) }
}

@MainActor
struct HangoutDetailViewModelTests {
    private let evening = SampleData.evening

    /// The ViewModel on the preview dependencies, with any repository swapped in.
    private func makeViewModel(
        _ deps: AppDependencies = .preview(), id: HangoutID = SampleData.evening.id,
        hangouts: (any HangoutRepository)? = nil, places: (any PlaceRepository)? = nil
    ) -> HangoutDetailViewModel {
        HangoutDetailViewModel(
            id: id, hangouts: hangouts ?? deps.hangouts, places: places ?? deps.places, profiles: deps.profiles,
            photos: deps.photos, library: deps.libraryStore, liveStore: deps.liveStore, network: deps.network,
            router: deps.router)
    }

    private func content(_ viewModel: HangoutDetailViewModel) throws -> HangoutDetailContent {
        guard case .loaded(let content, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            throw AppError.unknown
        }
        return content
    }

    // MARK: The tests ARCHITECTURE 2.4 asks for

    @Test func loadShowsTheHangout() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        let content = try content(viewModel)
        #expect(content.title == evening.title)
        #expect(content.isPick)
        #expect(content.spots.map(\.placeID) == evening.spots.map(\.placeID))
        #expect(content.spots.map(\.row.order) == [1, 2])
        #expect(content.budgetText == evening.budgetPerPerson.formattedPerPerson)
        #expect(content.bestTimeText == "Evening")
        #expect(content.tags == ["Good for groups"])
        #expect(content.remixCredit == nil)
        #expect(!content.hasTrek)
    }

    @Test func loadRunsOnlyOnce() async {
        let hangouts = ScriptedHangouts()
        let viewModel = makeViewModel(hangouts: hangouts)
        await viewModel.load()
        await viewModel.load()
        #expect(await hangouts.loads == 1)
        await viewModel.reload()
        #expect(await hangouts.loads == 2)
    }

    @Test func startCreatesTheRunAndOpensTheLiveScreen() async {
        let deps = AppDependencies.preview()
        let viewModel = makeViewModel(deps)
        await viewModel.load()
        #expect(viewModel.startButton == .start)
        await viewModel.startTapped()
        #expect(deps.liveStore.run?.hangoutID == evening.id)
        #expect(deps.router.cover == .live(evening.id))
        #expect(viewModel.startButton == .resume)
        #expect(viewModel.startCount == 1)
    }

    @Test func saveToggles() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let savedAtFirst = viewModel.isSaved      // the sample library already saves this Hangout
        await viewModel.saveTapped()
        #expect(viewModel.isSaved == !savedAtFirst)
        await viewModel.saveTapped()
        #expect(viewModel.isSaved == savedAtFirst)
    }

    // MARK: States

    @Test func aMissingHangoutShowsNotFound() async {
        let viewModel = makeViewModel(id: "hangout-missing-0000")
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = makeViewModel(.preview(.failing))
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func aFailedRefreshKeepsTheContentAsStale() async throws {
        let hangouts = ScriptedHangouts()
        let viewModel = makeViewModel(hangouts: hangouts)
        await viewModel.load()
        let before = try content(viewModel)
        await hangouts.startFailing()
        await viewModel.reload()
        #expect(viewModel.state == .loaded(before, isStale: true))
    }

    @Test func offlineDisablesStart() async {
        let deps = AppDependencies.preview()
        deps.network.forceOffline(true)
        let viewModel = makeViewModel(deps)
        await viewModel.load()
        #expect(viewModel.startButton == .offline)
        await viewModel.startTapped()
        #expect(deps.liveStore.run == nil)
        #expect(deps.router.cover == nil)
    }

    @Test func anotherLiveHangoutBlocksStart() async throws {
        let deps = AppDependencies.preview()
        try await deps.liveStore.startOrResume(hangoutID: SampleData.morning.id)
        let viewModel = makeViewModel(deps)
        await viewModel.load()
        #expect(viewModel.startButton == .otherHangoutLive)
        await viewModel.startTapped()
        #expect(deps.router.cover == nil)
    }

    // MARK: Content rules

    @Test func aRemixCreditsTheOriginalsAuthor() async throws {
        var remix = SampleData.morning
        remix.remixedFromID = evening.id
        let viewModel = makeViewModel(id: remix.id, hangouts: StubHangoutRepository(hangouts: [evening, remix]))
        await viewModel.load()
        #expect(try content(viewModel).remixCredit == "Remixed from @\(SampleData.vybeTeam.username)")
    }

    @Test func aTrekSpotShowsTheSafetyNote() async throws {
        var trek = SampleData.cafe
        trek.category = .trek
        let viewModel = makeViewModel(places: StubPlaceRepository(places: [trek, SampleData.park]))
        await viewModel.load()
        #expect(try content(viewModel).hasTrek)
    }

    @Test func shareTextIsTheTitleAndFindItOnVybe() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        #expect(try content(viewModel).shareText == "\(evening.title)\nFind it on Vybe")
    }

    // MARK: Navigation

    @Test func tapsAskTheRouterForTheRightScreen() async {
        let deps = AppDependencies.preview()
        let viewModel = makeViewModel(deps)
        viewModel.spotTapped(SampleData.cafe.id)
        #expect(deps.router.sheet == .spot(SampleData.cafe.id))
        deps.router.dismissSheet()
        viewModel.reportTapped()
        #expect(deps.router.sheet == .report(.hangout(evening.id)))
        viewModel.remixTapped()
        #expect(deps.router.cover == .editor(.remix(evening.id)))
        deps.router.dismissCover()
        viewModel.remixCreditTapped()
        #expect(deps.router.path(for: deps.router.currentStack) == [.remixTree(evening.id)])
    }

    @Test func textsResolveToRealText() {
        #expect(HangoutDetailText.start == "Start Hangout")
        #expect(HangoutDetailText.resume == "Resume Hangout")
        #expect(HangoutDetailText.notFound == "This Hangout is no longer available.")
        #expect(HangoutDetailText.remixedFrom("riya") == "Remixed from @riya")
    }
}
