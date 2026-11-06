#if DEBUG
import Core
import SwiftUI

extension NewChatViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode) -> NewChatViewModel {
        let deps = AppDependencies.preview(mode)
        return NewChatViewModel(
            friends: deps.friends, chat: deps.chat, session: deps.session, network: deps.network, onExit: { _ in })
    }
}

#Preview("Loaded") { NewChatView(viewModel: .preview(.loaded)) }
#Preview("Empty") { NewChatView(viewModel: .preview(.empty)) }
#Preview("Error") { NewChatView(viewModel: .preview(.failing)) }
#Preview("Loading") { NewChatView(viewModel: .preview(.neverReturns)) }
#Preview("Large text") { NewChatView(viewModel: .preview(.loaded)).dynamicTypeSize(.accessibility3) }
#endif
