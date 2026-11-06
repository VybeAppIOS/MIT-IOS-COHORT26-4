import Core
import Foundation
import Models
import Testing
@testable import DiscoverFeature

/// A Hangout repository that applies categories, vibe tags and the maximum time like the real one does.
/// An actor, so it is safe to share across concurrency domains.
private actor SheetHangouts: HangoutRepository {
    private let all: [Hangout]
    private let categories: [PlaceID: PlaceCategory]

    init(hangouts: [Hangout], places: [Place]) {
        all = hangouts
        categories = Dictionary(places.map { ($0.id, $0.category) }, uniquingKeysWith: { first, _ in first })
    }

    func hangouts(near center: Coordinate?, filters: HangoutFilters) async throws -> [Hangout] {
        all.filter { hangout in
            if let maxMinutes = filters.maxMinutes, hangout.estimatedMinutes > maxMinutes { return false }
            if !filters.vibeTags.isSubset(of: hangout.vibeTags) { return false }
            guard !filters.categories.isEmpty else { return true }
            return !Set(hangout.spots.compactMap { categories[$0.placeID] }).isDisjoint(with: filters.categories)
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

/// The filters sheet (task SC-D3) and its "Find your Vybe" page. Both edit `DiscoverMapViewModel`'s draft.
@MainActor
struct FiltersTests {
    private let park = SampleData.park

    /// An EXAMPLE Hangout at the park only, of the given length.
    private func parkHangout(_ suffix: String, minutes: Int) -> Hangout {
        Hangout(
            id: HangoutID("hangout-example-\(suffix)"), title: "EXAMPLE \(suffix)", summary: "EXAMPLE",
            spots: [Spot(id: "s1", placeID: park.id)], budgetPerPerson: RupeeRange(lower: 0, upper: 0),
            estimatedMinutes: minutes, bestTimes: [], tags: [], vibeTags: [], authorID: SampleData.friend.id,
            createdAt: SampleData.day, updatedAt: SampleData.day)
    }

    /// Evening (café + park, 120 min), Morning (park + café, 90 min), a 60-minute and a 210-minute park Hangout.
    private func makeViewModel() -> DiscoverMapViewModel {
        let deps = AppDependencies.preview()
        let hangouts = SheetHangouts(
            hangouts: SampleData.hangouts + [parkHangout("short", minutes: 60), parkHangout("long", minutes: 210)],
            places: [SampleData.cafe, park])
        return DiscoverMapViewModel(
            hangouts: hangouts, places: deps.places, photos: deps.photos, library: deps.libraryStore,
            friends: deps.friends, network: deps.network, router: deps.router, now: deps.now)
    }

    private func openedSheet() async -> DiscoverMapViewModel {
        let viewModel = makeViewModel()
        await viewModel.load()
        await viewModel.scopeTapped(.publicAll)     // the map opens on Picks; the sheet tests count every Hangout
        viewModel.moreFiltersTapped()
        return viewModel
    }

    private func pinCount(_ viewModel: DiscoverMapViewModel) -> Int {
        guard case .loaded(let content, _) = viewModel.state else { return 0 }
        return content.pins.count
    }

    // MARK: The D3 task

    @Test func resetClearsTheDraft() async {
        let viewModel = await openedSheet()
        viewModel.toggleDraftChip(.food)
        viewModel.setDraftTime(.upToOneHour)
        viewModel.setDraftBudget(lower: 100, upper: 500)
        viewModel.setDraftGoodForGroups(true)
        viewModel.resetDraft()
        #expect(viewModel.draft == HangoutFilters())
        #expect(viewModel.draftTime == .any)
    }

    @Test func theApplyCountUpdatesWithTheDraft() async {
        let viewModel = await openedSheet()
        await viewModel.countDraftResults()
        #expect(viewModel.draftResultCount == 4)
        viewModel.toggleDraftChip(.food)                 // only the two with the café
        await viewModel.countDraftResults()
        #expect(viewModel.draftResultCount == 2)
        viewModel.toggleDraftChip(.food)
        viewModel.setDraftTime(.upToOneHour)             // only the 60-minute one
        await viewModel.countDraftResults()
        #expect(viewModel.draftResultCount == 1)
    }

    @Test func threeHoursOrMoreKeepsOnlyTheLongHangouts() async {
        let viewModel = await openedSheet()
        viewModel.setDraftTime(.threeHoursOrMore)
        #expect(viewModel.draft.maxMinutes == nil)
        await viewModel.countDraftResults()
        #expect(viewModel.draftResultCount == 1)         // the 210-minute one
    }

    @Test func appliedFiltersSurviveClosingTheSheet() async {
        let viewModel = await openedSheet()
        viewModel.toggleDraftChip(.food)
        await viewModel.applyFilters()
        #expect(!viewModel.isShowingFilters)
        #expect(viewModel.filters.categories == DiscoverMapViewModel.Chip.food.categories)
        #expect(pinCount(viewModel) == 2)
        #expect(viewModel.selectedChips == [.food])       // the map chips agree with the sheet
        viewModel.moreFiltersTapped()                     // opening again starts from what was applied
        #expect(viewModel.draft == viewModel.filters)
    }

    @Test func closingWithoutApplyDiscardsTheDraft() async {
        let viewModel = await openedSheet()
        viewModel.toggleDraftChip(.games)
        viewModel.isShowingFilters = false                // swiped away
        #expect(viewModel.filters == HangoutFilters())
        viewModel.moreFiltersTapped()
        #expect(viewModel.draft == HangoutFilters())
        #expect(pinCount(viewModel) == 4)
    }

    // MARK: The "Find your Vybe" page (rule 6)

    @Test func choosingOnTheVybePageChangesTheDraft() async {
        let viewModel = await openedSheet()
        viewModel.toggleInterest(.chai)
        #expect(viewModel.draft.categories == [.chaiTapri])
        #expect(viewModel.isInterestSelected(.chai))
    }

    @Test func goingBackKeepsTheVybeChoices() async {
        let viewModel = await openedSheet()
        viewModel.toggleInterest(.parks)                  // on the Vybe page
        viewModel.setDraftGoodForGroups(true)             // back on the main sheet: same draft
        #expect(viewModel.isInterestSelected(.parks))
        #expect(viewModel.draft.categories == [.parkGarden])
    }

    @Test func resetClearsTheVybeChoices() async {
        let viewModel = await openedSheet()
        viewModel.toggleInterest(.parks)
        viewModel.toggleInterest(.rooftop)
        viewModel.resetDraft()
        #expect(!viewModel.isInterestSelected(.parks))
        #expect(!viewModel.isInterestSelected(.rooftop))
        #expect(viewModel.draft == HangoutFilters())
    }

    @Test func theApplyCountReflectsTheVybeChoices() async {
        let viewModel = await openedSheet()
        viewModel.toggleInterest(.parks)                  // every sample Hangout has the park
        await viewModel.countDraftResults()
        #expect(viewModel.draftResultCount == 4)
        viewModel.toggleInterest(.parks)
        viewModel.toggleInterest(.trek)                   // no trek in the sample data
        await viewModel.countDraftResults()
        #expect(viewModel.draftResultCount == 0)
    }

    // MARK: How the interests map onto HangoutFilters

    @Test func anInterestWithoutAModelsTypeIsAVibeTag() async {
        let viewModel = await openedSheet()
        viewModel.toggleInterest(.rooftop)
        #expect(viewModel.draft.vibeTags == ["rooftop"])
        #expect(viewModel.draft.categories.isEmpty)
    }

    @Test func interestsThatShareACategoryLightUpTogether() async {
        let viewModel = await openedSheet()
        viewModel.toggleInterest(.diner)
        #expect(viewModel.isInterestSelected(.bistros))   // both are restaurants
        viewModel.toggleInterest(.bistros)
        #expect(!viewModel.isInterestSelected(.diner))
    }

    @Test func thereAreThirtyInterestsInFiveSections() {
        #expect(VybeInterest.allCases.count == 30)
        #expect(VybeSection.allCases.flatMap(\.interests).count == 30)
        #expect(Set(VybeSection.allCases.flatMap(\.interests)) == Set(VybeInterest.allCases))
    }

    @Test func theFullBudgetRangeMeansAnyBudget() async {
        let viewModel = await openedSheet()
        viewModel.setDraftBudget(lower: 100, upper: 500)
        #expect(viewModel.draft.budget == RupeeRange(lower: 100, upper: 500))
        viewModel.setDraftBudget(lower: BudgetRange.lowest, upper: BudgetRange.highest)
        #expect(viewModel.draft.budget == nil)
    }

    // MARK: Text

    @Test func textsResolveToRealText() {
        #expect(FiltersText.findYourVybe == "Find your Vybe")
        #expect(FiltersText.apply(1) == "Apply (1 result)")
        #expect(FiltersText.apply(12) == "Apply (12 results)")
        #expect(VybeInterest.streetfood.title == "Streetfood")
        #expect(VybeSection.food.title == "Food, Drinks & Cravings")
        // Every interest has a real name in the catalog, not its key.
        #expect(VybeInterest.allCases.allSatisfy { !$0.title.hasPrefix("discover.") && $0.title != $0.rawValue })
    }
}
