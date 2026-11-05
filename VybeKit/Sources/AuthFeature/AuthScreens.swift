import Core
import SwiftUI

/// The only public type in AuthFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. Every sign-in screen is built (A1 to A3).
public enum AuthScreens {
    @ViewBuilder
    public static func view(for route: AuthRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .signIn:
            SignInView(viewModel: SignInViewModel(auth: deps.auth, session: deps.session, router: deps.router))
        case .emailSignIn:
            EmailCodeView(viewModel: EmailCodeViewModel(
                auth: deps.auth, session: deps.session, router: deps.router, now: deps.now))
        case .accountBasics:
            AccountBasicsView(viewModel: AccountBasicsViewModel(
                auth: deps.auth, session: deps.session, router: deps.router, now: deps.now))
        }
    }
}
