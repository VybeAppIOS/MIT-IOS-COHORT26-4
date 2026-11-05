#if DEBUG
import Core
import Models
import SwiftUI

extension InvitationViewModel {
    /// The real ViewModel on the stub repositories, in one state, for the sample group.
    static func preview(
        _ mode: StubMode, group: ConversationID = SampleSocialData.crew.id
    ) -> InvitationViewModel {
        let deps = AppDependencies.preview(mode)
        return InvitationViewModel(
            conversationID: group, chat: deps.chat, profiles: deps.profiles, network: deps.network, router: deps.router)
    }
}

#Preview("Loaded") { NavigationStack { InvitationView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { InvitationView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { InvitationView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { InvitationView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { InvitationView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
