#if DEBUG
import Core
import Models
import SwiftUI

extension OtherProfileViewModel {
    /// The real ViewModel on the stub repositories, for one of the sample people, in one state.
    static func preview(_ mode: StubMode, user: UserID = SampleSocialData.friend.id) -> OtherProfileViewModel {
        let deps = AppDependencies.preview(mode)
        return OtherProfileViewModel(
            userID: user, profiles: deps.profiles, friends: deps.friends, feed: deps.feed, places: deps.places,
            photos: deps.photos, session: deps.session, router: deps.router)
    }
}

#Preview("A friend") { NavigationStack { OtherProfileView(viewModel: .preview(.loaded)) } }
#Preview("Add friend") {
    NavigationStack { OtherProfileView(viewModel: .preview(.loaded, user: SampleSocialData.sanya.id)) }
}
#Preview("Private profile") {
    NavigationStack { OtherProfileView(viewModel: .preview(.loaded, user: SampleSocialData.kabir.id)) }
}
#Preview("Empty") { NavigationStack { OtherProfileView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { OtherProfileView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { OtherProfileView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { OtherProfileView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
