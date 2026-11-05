import Core
import Models
import Testing
@testable import EditorFeature

@MainActor
struct AddSpotViewModelTests {
    /// Collects what the sheet hands back to the editor.
    private final class Picked {
        var spots: [(Spot, Place)] = []
        var suggested = false
    }

    private func make(_ mode: StubMode = .loaded, picked: Picked) -> AddSpotViewModel {
        let deps = AppDependencies.preview(mode)
        return AddSpotViewModel(places: deps.places, photos: deps.photos, area: "Kothrud", makeID: { "abc" },
                                onAdd: { picked.spots.append(($0, $1)) }, onSuggest: { picked.suggested = true })
    }

    @Test func listsThePlacesWithAChipPerCategory() async {
        let viewModel = make(picked: Picked())
        await viewModel.load()
        #expect(viewModel.visibleRows.count == SampleData.places.count)
        #expect(viewModel.chips.first?.category == nil)
        #expect(Set(viewModel.chips.compactMap(\.category)) == Set(SampleData.places.map(\.category)))
    }

    @Test func aChipFiltersTheList() async {
        let viewModel = make(picked: Picked())
        await viewModel.load()
        let cafes = viewModel.chips.first { $0.category == .cafe }
        viewModel.select(cafes ?? viewModel.chips[0])
        #expect(viewModel.visibleRows.map(\.place.id) == [SampleData.cafe.id])
        viewModel.select(viewModel.chips[0])
        #expect(viewModel.visibleRows.count == SampleData.places.count)
    }

    @Test func addingAPlaceGivesANewSpotWithAStableID() async {
        let picked = Picked()
        let viewModel = make(picked: picked)
        await viewModel.load()
        viewModel.add(SampleData.park)
        #expect(picked.spots.count == 1)
        #expect(picked.spots.first?.0.id == "spot-abc")
        #expect(picked.spots.first?.0.placeID == SampleData.park.id && picked.spots.first?.1 == SampleData.park)
    }

    @Test func cantFindItAsksForASuggestion() {
        let picked = Picked()
        make(picked: picked).suggestTapped()
        #expect(picked.suggested)
    }

    @Test func noPlacesIsEmptyAndAFailureIsAnError() async {
        let empty = make(.empty, picked: Picked())
        await empty.load()
        #expect(empty.state == .empty)
        let failing = make(.failing, picked: Picked())
        await failing.load()
        #expect(failing.state == .failed(.offline))
    }
}
