import Core
import Foundation
import Models
import Testing
@testable import EditorFeature

@MainActor
struct EditorViewModelTests {
    private func make(
        _ start: EditorStart = .new, deps: AppDependencies? = nil
    ) -> (EditorViewModel, AppDependencies) {
        let deps = deps ?? AppDependencies.preview(.loaded)
        let viewModel = EditorViewModel(start: start, hangouts: deps.hangouts, places: deps.places,
                                        profiles: deps.profiles, photos: deps.photos, libraryStore: deps.libraryStore,
                                        session: deps.session, router: deps.router, now: { SampleData.day },
                                        makeID: { "id1" })
        return (viewModel, deps)
    }

    @Test func aNewHangoutStartsEmptyAndShowsWhatIsMissing() async {
        let (viewModel, _) = make()
        await viewModel.load()
        #expect(viewModel.state == .loaded("hangout-draft-id1"))
        #expect(viewModel.titleError != nil && viewModel.spotCountError != nil && !viewModel.canFinish)
    }

    @Test func validationMessagesFollowTheRules() async {
        let (viewModel, _) = make()
        await viewModel.load()
        viewModel.title = "Hi"
        #expect(viewModel.titleError != nil)
        viewModel.title = "Kothrud chai walk"
        #expect(viewModel.titleError == nil)
        viewModel.summary = String(repeating: "a", count: 201)
        #expect(viewModel.summaryError != nil)
        viewModel.budgetLower = 400
        viewModel.budgetUpper = 150
        #expect(viewModel.budgetError != nil)
    }

    @Test func twoSpotsAreNeededAndTheSamePlaceTwiceIsAWarningOnly() async {
        let (viewModel, _) = make()
        await viewModel.load()
        viewModel.title = "Kothrud chai walk"
        viewModel.addSpot(Spot(id: "a", placeID: SampleData.cafe.id), place: SampleData.cafe)
        #expect(viewModel.spotCountError != nil)
        viewModel.addSpot(Spot(id: "b", placeID: SampleData.cafe.id), place: SampleData.cafe)
        #expect(viewModel.spotCountError == nil)
        #expect(viewModel.duplicateWarning != nil)
        #expect(viewModel.spotRows.allSatisfy { $0.hasDuplicateWarning })
        #expect(viewModel.canFinish)
    }

    @Test func reorderAndDeleteKeepTheSpotsStraight() async {
        let (viewModel, _) = make()
        await viewModel.load()
        viewModel.addSpot(Spot(id: "a", placeID: SampleData.cafe.id), place: SampleData.cafe)
        viewModel.addSpot(Spot(id: "b", placeID: SampleData.park.id), place: SampleData.park)
        viewModel.addSpot(Spot(id: "c", placeID: SampleData.cafe.id), place: SampleData.cafe)
        viewModel.moveSpots(from: IndexSet(integer: 0), to: 3)
        #expect(viewModel.spots.map(\.id) == ["b", "c", "a"])
        viewModel.moveSpots(from: IndexSet(integer: 2), to: 0)
        #expect(viewModel.spots.map(\.id) == ["a", "b", "c"])
        viewModel.removeSpots(at: IndexSet(integer: 1))
        #expect(viewModel.spots.map(\.id) == ["a", "c"])
    }

    @Test func theEstimateIsTheSumUntilOverridden() async {
        let (viewModel, _) = make()
        await viewModel.load()
        viewModel.addSpot(Spot(id: "a", placeID: SampleData.cafe.id), place: SampleData.cafe)
        viewModel.addSpot(Spot(id: "b", placeID: SampleData.park.id), place: SampleData.park)
        viewModel.setMinutes(45, for: "a")
        viewModel.setMinutes(30, for: "b")
        #expect(viewModel.estimatedMinutes == 75)
        viewModel.setEstimate(120)
        #expect(viewModel.estimatedMinutes == 120)
    }

    @Test func aRemixCreditsTheOriginalAndCountsKeptPlaces() async {
        let (viewModel, deps) = make(.remix(SampleData.evening.id))
        await viewModel.load()
        #expect(viewModel.remixedFromID == SampleData.evening.id)
        #expect(viewModel.keptCount == 2 && viewModel.keepsCredit)
        #expect(viewModel.remixBanner?.contains("2") == true)
        #expect(deps.libraryStore.drafts.contains { $0.remixedFromID == SampleData.evening.id })
        viewModel.removeSpots(at: IndexSet(integer: 0))
        #expect(viewModel.keptCount == 1 && !viewModel.keepsCredit)   // 1 of 2 Places is below 70%
    }

    @Test func autosaveRestoresInANewEditor() async {
        let deps = AppDependencies.preview(.loaded)
        let (first, _) = make(deps: deps)
        await first.load()
        first.title = "Kothrud chai walk"
        first.addSpot(Spot(id: "a", placeID: SampleData.cafe.id), place: SampleData.cafe)
        first.addSpot(Spot(id: "b", placeID: SampleData.park.id), place: SampleData.park)
        first.toggleTag(first.tagOptions[0])
        await first.autosave()

        let (second, _) = make(.draft("hangout-draft-id1"), deps: deps)
        await second.load()
        #expect(second.title == "Kothrud chai walk")
        #expect(second.spots.map(\.id) == ["a", "b"])
        #expect(second.tags == [first.tagOptions[0].id])
    }

    @Test func doneSavesAndShowsDraftsOnProfile() async {
        let (viewModel, deps) = make()
        await viewModel.load()
        viewModel.title = "Kothrud chai walk"
        viewModel.addSpot(Spot(id: "a", placeID: SampleData.cafe.id), place: SampleData.cafe)
        viewModel.addSpot(Spot(id: "b", placeID: SampleData.park.id), place: SampleData.park)
        deps.router.presentCover(.editor(.new))
        await viewModel.doneTapped()
        #expect(deps.router.cover == nil && deps.router.selectedTab == .profile)
        #expect(deps.router.path(for: .tab(.profile)) == [.drafts])
        #expect(deps.libraryStore.drafts.first?.status == .draft)
    }

    @Test func closingAnUntouchedEditorLeavesNothingBehind() async {
        let (viewModel, deps) = make()
        await viewModel.load()
        deps.router.presentCover(.editor(.new))
        viewModel.closeTapped()
        #expect(!viewModel.isConfirmingClose && deps.router.cover == nil && deps.libraryStore.drafts.isEmpty)
    }

    @Test func discardingANewHangoutDeletesItsDraft() async {
        let (viewModel, deps) = make()
        await viewModel.load()
        viewModel.title = "Kothrud chai walk"
        viewModel.edited()   // what the view does on every change
        await viewModel.autosave()
        viewModel.closeTapped()
        #expect(viewModel.isConfirmingClose)
        await viewModel.discardAndClose()
        #expect(deps.libraryStore.drafts.isEmpty)
    }

    @Test func aMissingDraftIsNotFound() async {
        let (viewModel, _) = make(.draft("missing"))
        await viewModel.load()
        #expect(viewModel.state == .failed(.notFound))
    }
}
