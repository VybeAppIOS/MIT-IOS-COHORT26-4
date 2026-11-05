#if DEBUG
import Core
import Models
import SwiftUI

extension SpotSheetViewModel {
    /// The real ViewModel on the stub repositories, showing `place`. The preview clock is `SampleData.day`
    /// (a Tuesday afternoon in Pune).
    static func preview(_ place: Place = .previewOpen, mode: StubMode = .loaded) -> SpotSheetViewModel {
        let deps = AppDependencies.preview(mode)
        return SpotSheetViewModel(
            id: place.id, places: StubPlaceRepository(mode: mode, places: [place, SampleData.park]),
            hangouts: deps.hangouts, photos: deps.photos, library: deps.libraryStore, router: deps.router,
            now: deps.now)
    }
}

extension Place {
    /// The EXAMPLE café, open every day 09:00–22:00, with an EXAMPLE Apple ID (the lookup fails in previews).
    static var previewOpen: Place {
        var place = SampleData.cafe
        place.hours = (1...7).map { OpeningPeriod(weekday: $0, open: "09:00", close: "22:00") }
        place.applePlaceID = "EXAMPLE-apple-place-id"
        return place
    }

    static var previewClosedByAuthorities: Place {
        var place = previewOpen
        place.status = .closedByAuthorities
        return place
    }

    static var previewTrek: Place {
        var place = previewOpen
        place.category = .trek
        place.trekInfo = TrekInfo(difficulty: .easy, season: "EXAMPLE season", startPoint: "EXAMPLE start point",
                                  safetyNote: "EXAMPLE trek safety note from the Place's own data.")
        return place
    }

    static var previewNoPhotos: Place {
        var place = previewOpen
        place.photos = []
        return place
    }

    static var previewNoAppleID: Place {
        var place = previewOpen
        place.applePlaceID = nil
        return place
    }
}

private func sheet(_ viewModel: SpotSheetViewModel) -> some View {
    NavigationStack { SpotSheetView(viewModel: viewModel) }
}

#Preview("Open") { sheet(.preview()) }
#Preview("Closed by authorities") { sheet(.preview(.previewClosedByAuthorities)) }
#Preview("Trek") { sheet(.preview(.previewTrek)) }
#Preview("No photos") { sheet(.preview(.previewNoPhotos)) }
#Preview("No Apple ID") { sheet(.preview(.previewNoAppleID)) }
#Preview("Loading") { sheet(.preview(mode: .neverReturns)) }
#Preview("Error") { sheet(.preview(mode: .failing)) }
#Preview("Large text") { sheet(.preview()).dynamicTypeSize(.accessibility3) }
#endif
