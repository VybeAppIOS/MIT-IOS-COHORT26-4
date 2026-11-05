// xcode: set sdk=iOS

#if DEBUG
import Core
import SwiftUI

extension FeedViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode) -> FeedViewModel {
        let deps = AppDependencies.preview(mode)
        return FeedViewModel(
            feed: deps.feed, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            libraryStore: deps.libraryStore, badges: deps.badges, session: deps.session, router: deps.router,
            makeComments: CommentsViewModel.previewFactory(deps))
    }
}

#Preview("Loaded") { NavigationStack { FeedView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { FeedView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { FeedView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { FeedView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { FeedView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
