#if DEBUG
import Core
import SwiftUI

extension SignInViewModel {
    /// The real ViewModel on the `AuthRepository` stub, in one state.
    static func preview(_ mode: StubMode = .loaded) -> SignInViewModel {
        let deps = AppDependencies.preview(mode)
        return SignInViewModel(auth: deps.auth, session: deps.session, router: deps.router)
    }
}

private func screen(_ viewModel: SignInViewModel) -> some View {
    NavigationStack { SignInView(viewModel: viewModel) }
}

#Preview("Sign in") { screen(.preview()) }
#Preview("Loading") {
    let viewModel = SignInViewModel.preview(.neverReturns)
    screen(viewModel).task { await viewModel.appleTapped() }
}
#Preview("Failed, with Retry") {
    let viewModel = SignInViewModel.preview(.failing)
    screen(viewModel).task { await viewModel.googleTapped() }
}
#Preview("Large text") { screen(.preview()).dynamicTypeSize(.accessibility3) }
#endif
