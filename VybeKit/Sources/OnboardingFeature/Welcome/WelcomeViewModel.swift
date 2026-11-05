import Core
import Foundation

/// Welcome (O1): the first screen on first launch. It loads nothing: the hero is a drawing (a route through
/// three Spots), so there is no loading, empty or error state. Its two buttons ask the router for the next screen.
@MainActor @Observable
final class WelcomeViewModel {
    private let router: Router

    /// Cheap: no loading here (ADR 005). Take only what the screen needs, never `AppDependencies`.
    init(router: Router) {
        self.router = router
    }

    func getStarted() { router.open(.nameAndPhoto) }

    func signIn() { router.open(.signIn) }
}

/// Welcome's text, read from OnboardingFeature's own catalog (`bundle: #bundle`, task X-3).
enum WelcomeText {
    /// The app's name as text. The name is not final, so it lives here and nowhere else; the pitch reuses it.
    static var wordmark: String { String(localized: "onboarding.welcome.wordmark", bundle: #bundle) }
    /// "Find your Vybe." with the name filled in from `wordmark`.
    static var pitch: String { String(localized: "onboarding.welcome.pitch \(wordmark)", bundle: #bundle) }
    static var getStarted: String { String(localized: "onboarding.welcome.getStarted", bundle: #bundle) }
    static var haveAccount: String { String(localized: "onboarding.welcome.haveAccount", bundle: #bundle) }
    static var signIn: String { String(localized: "onboarding.welcome.signIn", bundle: #bundle) }
}
