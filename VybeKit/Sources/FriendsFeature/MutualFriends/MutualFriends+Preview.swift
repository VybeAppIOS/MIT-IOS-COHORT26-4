#if DEBUG
import Core
import Models
import SwiftUI

extension MutualFriendsViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode, user: UserID = SampleSocialData.sanya.id) -> MutualFriendsViewModel {
        let deps = AppDependencies.preview(mode)
        return MutualFriendsViewModel(userID: user, friends: deps.friends, session: deps.session, router: deps.router)
    }
}

#Preview("Loaded") { NavigationStack { MutualFriendsView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { MutualFriendsView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { MutualFriendsView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { MutualFriendsView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { MutualFriendsView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
