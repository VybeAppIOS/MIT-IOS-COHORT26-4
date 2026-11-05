#if DEBUG
import Core
import SwiftUI

extension TrendingViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode) -> TrendingViewModel {
        let deps = AppDependencies.preview(mode)
        return TrendingViewModel(
            feed: deps.feed, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            libraryStore: deps.libraryStore, router: deps.router, makeComments: CommentsViewModel.previewFactory(deps))
    }
}

#Preview("Loaded") { NavigationStack { TrendingView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { TrendingView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { TrendingView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { TrendingView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { TrendingView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
