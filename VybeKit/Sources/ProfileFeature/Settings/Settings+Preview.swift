#if DEBUG
import Core
import SwiftUI

extension SettingsViewModel {
    /// The real ViewModel on the stub dependencies.
    static func preview(_ mode: StubMode = .loaded) -> SettingsViewModel {
        let deps = AppDependencies.preview(mode)
        return SettingsViewModel(session: deps.session, router: deps.router)
    }
}

#Preview("Settings") { NavigationStack { SettingsView(viewModel: .preview()) } }
#Preview("Large text") {
    NavigationStack { SettingsView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
