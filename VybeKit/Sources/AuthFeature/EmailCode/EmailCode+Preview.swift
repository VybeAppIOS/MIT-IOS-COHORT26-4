#if DEBUG
import Core
import SwiftUI

extension EmailCodeViewModel {
    /// The real ViewModel on the `AuthRepository` stub (its working code is 123456).
    static func preview(_ mode: StubMode = .loaded) -> EmailCodeViewModel {
        let deps = AppDependencies.preview(mode)
        return EmailCodeViewModel(auth: deps.auth, session: deps.session, router: deps.router, now: { Date() })
    }
}

private func screen(_ viewModel: EmailCodeViewModel) -> some View {
    NavigationStack { EmailCodeView(viewModel: viewModel) }
}

#Preview("Email") { screen(.preview()) }
#Preview("Email, invalid") {
    let viewModel = EmailCodeViewModel.preview()
    screen(viewModel).onAppear { viewModel.email = "riya@" }
}
#Preview("Code, counting down") {
    let viewModel = EmailCodeViewModel.preview()
    screen(viewModel).task {
        viewModel.email = "riya@example.com"
        await viewModel.sendCodeTapped()
    }
}
#Preview("Code, wrong") {
    let viewModel = EmailCodeViewModel.preview()
    screen(viewModel).task {
        viewModel.email = "riya@example.com"
        await viewModel.sendCodeTapped()
        viewModel.codeChanged("111111")
        await viewModel.verifyCode()
    }
}
#Preview("Large text") { screen(.preview()).dynamicTypeSize(.accessibility3) }
#endif
