#if DEBUG
import Core
import SwiftUI

extension SavedViewModel {
    /// The real ViewModel on the stubs (the loaded stub library starts with one saved Hangout).
    static func preview(_ mode: StubMode = .loaded) -> SavedViewModel {
        let deps = AppDependencies.preview(mode)
        return SavedViewModel(hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
                              libraryStore: deps.libraryStore, router: deps.router)
    }
}

#Preview("Loaded") { NavigationStack { SavedView(viewModel: .preview()) } }
#Preview("Empty") { NavigationStack { SavedView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { SavedView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { SavedView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { SavedView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
