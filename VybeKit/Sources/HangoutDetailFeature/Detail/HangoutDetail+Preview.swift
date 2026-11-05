#if DEBUG
import Core
import Models
import SwiftUI

extension HangoutDetailViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(
        _ mode: StubMode = .loaded, id: HangoutID = SampleData.evening.id, offline: Bool = false
    ) -> HangoutDetailViewModel {
        let deps = AppDependencies.preview(mode)
        deps.network.forceOffline(offline)
        return HangoutDetailViewModel(
            id: id, hangouts: deps.hangouts, places: deps.places, profiles: deps.profiles, photos: deps.photos,
            library: deps.libraryStore, liveStore: deps.liveStore, network: deps.network, router: deps.router)
    }
}

#Preview("Loaded") { NavigationStack { HangoutDetailView(viewModel: .preview()) } }
#Preview("Loading") { NavigationStack { HangoutDetailView(viewModel: .preview(.neverReturns)) } }
#Preview("Not found") { NavigationStack { HangoutDetailView(viewModel: .preview(id: "hangout-missing-0000")) } }
#Preview("Error") { NavigationStack { HangoutDetailView(viewModel: .preview(.failing)) } }
#Preview("Offline") { NavigationStack { HangoutDetailView(viewModel: .preview(offline: true)) } }
#Preview("Large text") {
    NavigationStack { HangoutDetailView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
