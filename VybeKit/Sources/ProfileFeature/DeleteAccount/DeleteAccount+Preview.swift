#if DEBUG
import Core
import SwiftUI

extension DeleteAccountViewModel {
    /// The real ViewModel on the stubs. `typed` fills the confirmation field.
    static func preview(
        _ mode: StubMode = .loaded, typed: String = "", offline: Bool = false
    ) -> DeleteAccountViewModel {
        let deps = AppDependencies.preview(mode)
        deps.network.forceOffline(offline)
        let viewModel = DeleteAccountViewModel(
            auth: deps.auth, session: deps.session, libraryStore: deps.libraryStore, liveStore: deps.liveStore,
            network: deps.network, router: deps.router)
        viewModel.typedUsername = typed
        return viewModel
    }
}

#Preview("Empty field") { NavigationStack { DeleteAccountView(viewModel: .preview()) } }
#Preview("Typed, matches") { NavigationStack { DeleteAccountView(viewModel: .preview(typed: "sample.me")) } }
#Preview("Typed, wrong") { NavigationStack { DeleteAccountView(viewModel: .preview(typed: "sample.you")) } }
#Preview("Offline") { NavigationStack { DeleteAccountView(viewModel: .preview(offline: true)) } }
#Preview("Large text") {
    NavigationStack { DeleteAccountView(viewModel: .preview(typed: "sample.me")) }
        .dynamicTypeSize(.accessibility3)
}
#endif
