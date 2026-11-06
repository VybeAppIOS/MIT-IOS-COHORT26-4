#if DEBUG
import Core
import Models
import SwiftUI

extension ShareSheetViewModel {
    /// The real ViewModel on the stub repositories, in one state, sharing the first sample post.
    static func preview(
        _ mode: StubMode, item: ShareItem = .post(SampleSocialData.posts[0].id)
    ) -> ShareSheetViewModel {
        let deps = AppDependencies.preview(mode)
        return ShareSheetViewModel(
            item: item, chat: deps.chat, friends: deps.friends, hangouts: deps.hangouts, feed: deps.feed,
            session: deps.session, network: deps.network, router: deps.router)
    }
}

#Preview("Loaded") { NavigationStack { ShareSheetView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { ShareSheetView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { ShareSheetView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { ShareSheetView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { ShareSheetView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
