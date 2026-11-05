import Core
import Foundation
import Models
import Testing
@testable import HangoutDetailFeature

/// A Hangout repository that counts loads and can start failing, to check "load once" and "a failed refresh
/// keeps the content". An actor, so it is safe to share across concurrency domains.
private actor ScriptedTree: HangoutRepository {
    private let base: StubHangoutRepository
    private(set) var loads = 0
    private var failing = false

    init(hangouts: [Hangout]) { base = StubHangoutRepository(hangouts: hangouts) }

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
struct RemixTreeViewModelTests {
    private let evening = SampleData.evening
    private let remix = Hangout.previewRemix          // by Sample Friend, remixed from the Evening Hangout

    private func makeViewModel(
        _ deps: AppDependencies = .preview(), id: HangoutID = SampleData.evening.id,
        hangouts: (any HangoutRepository)? = nil
    ) -> RemixTreeViewModel {
        RemixTreeViewModel(
            id: id, hangouts: hangouts ?? StubHangoutRepository(hangouts: Hangout.previewTree), places: deps.places,
            profiles: deps.profiles, photos: deps.photos, library: deps.libraryStore, session: deps.session,
            router: deps.router)
    }

    private func content(_ viewModel: RemixTreeViewModel) throws -> RemixTreeContent {
        guard case .loaded(let content, _) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            throw AppError.unknown
        }
        return content
    }

    // MARK: The counter text (task SC-HD3)

    @Test func counterTextShowsBothCounts() {
        #expect(RemixTreeViewModel.counterText(done: 40, remixed: 12) == "Done 40× · Remixed 12×")
    }

    @Test func counterTextLeavesOutAZeroPart() {
        #expect(RemixTreeViewModel.counterText(done: 0, remixed: 3) == "Remixed 3×")
        #expect(RemixTreeViewModel.counterText(done: 5, remixed: 0) == "Done 5×")
    }

    @Test func counterTextIsHiddenWhenBothAreZero() {
        #expect(RemixTreeViewModel.counterText(done: 0, remixed: 0) == nil)
    }

    @Test func counterTextFormatsLargeNumbers() {
        let thousands = 1_200.formatted()                // "1,200" in English; follows the person's settings
        #expect(RemixTreeViewModel.counterText(done: 1_200, remixed: 1) == "Done \(thousands)× · Remixed 1×")
    }

    // MARK: Loading

    @Test func loadShowsTheRemixesWithTheirAuthors() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()
        let content = try content(viewModel)
        #expect(content.remixes.map(\.id) == [remix.id])
        #expect(content.remixes.first?.authorName == SampleData.friend.displayName)
        #expect(content.remixes.first?.authorUsername == "@\(SampleData.friend.username)")
        #expect(content.counterText == "Done 12× · Remixed 3×")      // the stub's counts
        #expect(content.original == nil)                           // the Evening Hangout is not a Remix
    }

    @Test func aRemixShowsItsOriginal() async throws {
        let viewModel = makeViewModel(id: remix.id)
        await viewModel.load()
        let content = try content(viewModel)
        #expect(content.original?.id == evening.id)
        #expect(content.originalCredit == "Remixed from @\(SampleData.vybeTeam.username)")
    }

    @Test func noRemixesGivesAnEmptyList() async throws {
        let viewModel = makeViewModel(hangouts: StubHangoutRepository(hangouts: SampleData.hangouts))
        await viewModel.load()
        #expect(try content(viewModel).remixes.isEmpty)
        #expect(RemixTreeText.empty == "Nobody has remixed this yet. Be the first.")
    }

    @Test func loadRunsOnlyOnce() async {
        let tree = ScriptedTree(hangouts: Hangout.previewTree)
        let viewModel = makeViewModel(hangouts: tree)
        await viewModel.load()
        let afterFirst = await tree.loads
        await viewModel.load()
        #expect(await tree.loads == afterFirst)
    }

    @Test func aMissingHangoutShowsNotFound() async {
        let viewModel = makeViewModel(id: "hangout-missing-0000")
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = makeViewModel(hangouts: StubHangoutRepository(mode: .failing))
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func aFailedRefreshKeepsTheContentAsStale() async throws {
        let tree = ScriptedTree(hangouts: Hangout.previewTree)
        let viewModel = makeViewModel(hangouts: tree)
        await viewModel.load()
        let before = try content(viewModel)
        await tree.startFailing()
        await viewModel.reload()
        #expect(viewModel.state == .loaded(before, isStale: true))
    }

    // MARK: Rules

    @Test func remixesByBlockedPeopleAreHidden() async throws {
        let deps = AppDependencies.preview()
        deps.session.block(SampleData.friend.id)
        let viewModel = makeViewModel(deps)
        await viewModel.load()
        #expect(try content(viewModel).remixes.isEmpty)
    }

    @Test func aRemixerWithoutAProfileStillShowsTheCard() async throws {
        var unknown = remix
        unknown.authorID = "user-missing-0000"
        let viewModel = makeViewModel(hangouts: StubHangoutRepository(hangouts: [evening, unknown]))
        await viewModel.load()
        let item = try #require(try content(viewModel).remixes.first)
        #expect(item.authorName == nil)
        #expect(item.card.id == unknown.id)
    }

    // MARK: Navigation

    @Test func tappingACardOpensThatHangout() {
        let deps = AppDependencies.preview()
        makeViewModel(deps).hangoutTapped(remix.id)
        #expect(deps.router.path(for: deps.router.currentStack) == [.hangout(remix.id)])
    }
}
