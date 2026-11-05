#if DEBUG
import Core
import Models
import SwiftUI

extension ProfileViewModel {
    /// The real ViewModel on the stubs. `asFriend` signs in as a sample person who has posted, so the posts show
    /// (the sample "mine" has not posted yet).
    static func preview(_ mode: StubMode = .loaded, asFriend: Bool = true) -> ProfileViewModel {
        let deps = AppDependencies.preview(mode)
        let mine = asFriend ? SampleData.friend.id : SampleData.signedInUser.id
        let profiles = StubProfileRepository(mode: mode, people: SampleSocialData.people, currentID: mine)
        return ProfileViewModel(profiles: profiles, auth: deps.auth, feed: deps.feed, photos: deps.photos,
                                session: deps.session, libraryStore: deps.libraryStore, router: deps.router)
    }
}

#Preview("With posts") { NavigationStack { ProfileView(viewModel: .preview()) } }
#Preview("No posts yet") { NavigationStack { ProfileView(viewModel: .preview(asFriend: false)) } }
#Preview("Error") { NavigationStack { ProfileView(viewModel: .preview(.failing, asFriend: false)) } }
#Preview("Loading") { NavigationStack { ProfileView(viewModel: .preview(.neverReturns, asFriend: false)) } }
#Preview("Large text") {
    NavigationStack { ProfileView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
