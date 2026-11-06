#if DEBUG
import Core
import SwiftUI

extension AddSpotViewModel {
    /// The real ViewModel on the stubs (the EXAMPLE Places in Kothrud).
    static func preview(_ mode: StubMode = .loaded) -> AddSpotViewModel {
        let deps = AppDependencies.preview(mode)
        return AddSpotViewModel(places: deps.places, photos: deps.photos, area: "Kothrud", makeID: { "preview" },
                                onAdd: { _, _ in }, onSuggest: {})
    }
}

#Preview("Loaded") { AddSpotView(viewModel: .preview()) }
#Preview("Empty") { AddSpotView(viewModel: .preview(.empty)) }
#Preview("Error") { AddSpotView(viewModel: .preview(.failing)) }
#Preview("Loading") { AddSpotView(viewModel: .preview(.neverReturns)) }
#Preview("Large text") { AddSpotView(viewModel: .preview()).dynamicTypeSize(.accessibility3) }
#endif
