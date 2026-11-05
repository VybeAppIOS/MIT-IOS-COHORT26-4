#if DEBUG
import Core
import SwiftUI

extension FindFriendsViewModel {
    /// The real ViewModel on the stub social data, in one state.
    static func preview(_ mode: StubMode = .loaded) -> FindFriendsViewModel {
        let deps = AppDependencies.preview(mode)
        return FindFriendsViewModel(friends: deps.friends, photos: deps.photos, session: deps.session,
                                    router: deps.router)
    }
}

private func screen(_ viewModel: FindFriendsViewModel) -> some View {
    NavigationStack { FindFriendsView(viewModel: viewModel) }
}

#Preview("Loaded") { screen(.preview()) }
#Preview("Empty") { screen(.preview(.empty)) }
#Preview("Error") { screen(.preview(.failing)) }
#Preview("Loading") { screen(.preview(.neverReturns)) }
#Preview("Large text") { screen(.preview()).dynamicTypeSize(.accessibility3) }
#endif
