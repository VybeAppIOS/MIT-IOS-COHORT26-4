#if DEBUG
import Core
import SwiftUI

extension ListViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode) -> ListViewModel {
        let deps = AppDependencies.preview(mode)
        return ListViewModel(
            chat: deps.chat, profiles: deps.profiles, session: deps.session, badges: deps.badges,
            network: deps.network, router: deps.router, now: deps.now,
            makeNewChat: { onExit in
                NewChatViewModel(
                    friends: deps.friends, chat: deps.chat, session: deps.session, network: deps.network,
                    onExit: onExit)
            })
    }
}

#Preview("Loaded") { NavigationStack { ListView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { ListView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { ListView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { ListView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { ListView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
