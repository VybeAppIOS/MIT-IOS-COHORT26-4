#if DEBUG
import Core
import Models
import SwiftUI

extension GroupPhotosViewModel {
    /// The real ViewModel on the stub repositories, in one state (the sample Kothrud Crew chat).
    static func preview(_ mode: StubMode) -> GroupPhotosViewModel {
        let deps = AppDependencies.preview(mode)
        return GroupPhotosViewModel(
            conversationID: SampleSocialData.crew.id, chat: deps.chat, photos: deps.photos, session: deps.session)
    }
}

#Preview("Loaded") { NavigationStack { GroupPhotosView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { GroupPhotosView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { GroupPhotosView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { GroupPhotosView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { GroupPhotosView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
