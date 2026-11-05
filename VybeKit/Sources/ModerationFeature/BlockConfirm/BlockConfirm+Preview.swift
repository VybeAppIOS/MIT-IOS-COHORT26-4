#if DEBUG
import Core
import Models
import SwiftUI

extension BlockConfirmViewModel {
    /// The real ViewModel on the stub repositories. The person is a sample friend, never a real one.
    static func preview(_ mode: StubMode = .loaded) -> BlockConfirmViewModel {
        let deps = AppDependencies.preview(mode)
        return BlockConfirmViewModel(userID: SampleSocialData.aarav.id, profiles: deps.profiles, safety: deps.safety,
                                     session: deps.session, router: deps.router)
    }
}

#Preview("Block, name loaded") { BlockConfirmView(viewModel: .preview()) }
#Preview("Block, name not loaded") { BlockConfirmView(viewModel: .preview(.failing)) }
#Preview("Large text") { BlockConfirmView(viewModel: .preview()).dynamicTypeSize(.accessibility3) }
#endif
