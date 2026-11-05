#if DEBUG
import Core
import SwiftUI

extension HubViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode) -> HubViewModel {
        let deps = AppDependencies.preview(mode)
        return HubViewModel(
            friends: deps.friends, profiles: deps.profiles, session: deps.session, router: deps.router, now: deps.now)
    }
}

#Preview("Loaded") { NavigationStack { HubView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { HubView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { HubView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { HubView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { HubView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
