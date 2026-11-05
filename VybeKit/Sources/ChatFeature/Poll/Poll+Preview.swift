#if DEBUG
import Core
import Models
import SwiftUI

extension PollViewModel {
    /// The real ViewModel on the stub repositories, for the sample group.
    static func preview(offline: Bool = false) -> PollViewModel {
        let deps = AppDependencies.preview(.loaded)
        return PollViewModel(
            conversationID: SampleSocialData.crew.id, chat: deps.chat, network: NetworkMonitor(isOffline: offline),
            onClose: {})
    }
}

#Preview("Empty question") { PollView(viewModel: .preview()) }
#Preview("Offline") { PollView(viewModel: .preview(offline: true)) }
#Preview("Large text") { PollView(viewModel: .preview()).dynamicTypeSize(.accessibility3) }
#endif
