#if DEBUG
import Core
import Models
import SwiftUI

extension PostDetailViewModel {
    /// The real ViewModel on the stub repositories, in one state, for one of the sample posts.
    static func preview(_ mode: StubMode, run: RunID = SampleSocialData.posts[2].id) -> PostDetailViewModel {
        let deps = AppDependencies.preview(mode)
        return PostDetailViewModel(
            runID: run, feed: deps.feed, hangouts: deps.hangouts, places: deps.places, profiles: deps.profiles,
            friends: deps.friends, photos: deps.photos, libraryStore: deps.libraryStore, session: deps.session,
            router: deps.router, now: deps.now)
    }
}

#Preview("Friend's post") { NavigationStack { PostDetailView(viewModel: .preview(.loaded)) } }
#Preview("A Pick") {
    NavigationStack { PostDetailView(viewModel: .preview(.loaded, run: SampleSocialData.posts[0].id)) }
}
#Preview("Unavailable") { NavigationStack { PostDetailView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { PostDetailView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { PostDetailView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { PostDetailView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
