#if DEBUG
import Core
import SwiftUI

extension AccountSettingsViewModel {
    /// The real ViewModel on the stubs; `offline` forces the network monitor.
    static func preview(_ mode: StubMode = .loaded, offline: Bool = false) -> AccountSettingsViewModel {
        let deps = AppDependencies.preview(mode)
        deps.network.forceOffline(offline)
        return AccountSettingsViewModel(auth: deps.auth, session: deps.session, network: deps.network,
                                        router: deps.router)
    }
}

#Preview("Account") { NavigationStack { AccountSettingsView(viewModel: .preview()) } }
#Preview("Offline") { NavigationStack { AccountSettingsView(viewModel: .preview(offline: true)) } }
#Preview("Large text") {
    NavigationStack { AccountSettingsView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
