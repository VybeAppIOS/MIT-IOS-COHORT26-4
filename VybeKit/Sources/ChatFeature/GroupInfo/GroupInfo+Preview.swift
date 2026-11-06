#if DEBUG
import Core
import Models
import SwiftUI

extension GroupInfoViewModel {
    /// The real ViewModel on the stub repositories, in one state, for the sample group.
    static func preview(
        _ mode: StubMode, group: ConversationID = SampleSocialData.crew.id
    ) -> GroupInfoViewModel {
        let deps = AppDependencies.preview(mode)
        return GroupInfoViewModel(
            conversationID: group, chat: deps.chat, friends: deps.friends, profiles: deps.profiles,
            session: deps.session, network: deps.network, router: deps.router)
    }
}

#Preview("Loaded") { NavigationStack { GroupInfoView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { GroupInfoView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { GroupInfoView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { GroupInfoView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { GroupInfoView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
