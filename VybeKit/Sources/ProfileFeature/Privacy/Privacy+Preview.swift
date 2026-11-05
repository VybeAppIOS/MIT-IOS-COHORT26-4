#if DEBUG
import Core
import Models
import SwiftUI

extension PrivacyViewModel {
    /// Sample data from the stubs; a different `mode` gives the error and loading states.
    static func preview(mode: StubMode = .loaded) -> PrivacyViewModel {
        let deps = AppDependencies.preview(mode)
        return PrivacyViewModel(profiles: deps.profiles, session: deps.session, network: deps.network)
    }
}

#Preview("Loaded") { NavigationStack { PrivacyView(viewModel: .preview()) } }
#Preview("Error") { NavigationStack { PrivacyView(viewModel: .preview(mode: .failing)) } }
#Preview("Loading") { NavigationStack { PrivacyView(viewModel: .preview(mode: .neverReturns)) } }
#Preview("Large text") {
    NavigationStack { PrivacyView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
