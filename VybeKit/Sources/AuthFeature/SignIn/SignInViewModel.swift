import Core
import Foundation
import Models

/// A1: sign in with Apple, Google or email. Phase 1 runs on the `AuthRepository` stub only (no real accounts).
/// A new person goes on to Account basics (A3); someone who already has an account finishes onboarding.
///
/// "New" is a profile with no username yet (A3 is where it is chosen). `AuthRepository` gives no explicit flag;
/// Lohitaksh may add one later (for example a `SignInResult { user, isNewAccount }`).
@MainActor @Observable
final class SignInViewModel {
    enum Provider: Equatable, Sendable {
        case apple
        case google
    }

    /// The provider being signed in with right now (its button shows a spinner, the others are disabled).
    private(set) var loading: Provider?
    /// The provider whose last attempt failed; Retry tries it again.
    private(set) var failed: Provider?

    private let auth: any AuthRepository
    private let session: SessionStore
    private let router: Router

    /// Cheap: no loading here (ADR 005).
    init(auth: any AuthRepository, session: SessionStore, router: Router) {
        self.auth = auth
        self.session = session
        self.router = router
    }

    var isBusy: Bool { loading != nil }

    /// "Couldn't sign in with Apple. Try again."; nil when nothing failed.
    var errorMessage: String? {
        switch failed {
        case .apple: SignInText.appleFailed
        case .google: SignInText.googleFailed
        case nil: nil
        }
    }

    // MARK: Actions

    func appleTapped() async { await signIn(with: .apple) }

    func googleTapped() async { await signIn(with: .google) }

    func retryTapped() async {
        guard let failed else { return }
        await signIn(with: failed)
    }

    func emailTapped() {
        guard !isBusy else { return }
        router.open(.emailSignIn)
    }

    // MARK: Signing in

    private func signIn(with provider: Provider) async {
        guard loading == nil else { return }    // one sign-in at a time
        loading = provider
        failed = nil
        defer { loading = nil }
        do {
            let user = switch provider {
            case .apple: try await auth.signInWithApple()
            case .google: try await auth.signInWithGoogle()
            }
            signedIn(user)
        } catch is CancellationError {
            return                              // the person cancelled: no error, back to normal
        } catch {
            failed = provider
        }
    }

    private func signedIn(_ user: UserProfile) {
        session.setCurrentUser(user)
        if user.username.isEmpty {
            router.open(.accountBasics)         // new: choose a username, date of birth, 18+
            return
        }
        // An existing account skips onboarding. Copy its interests into the draft first, because finishing
        // saves the draft's interests onto the profile.
        session.onboardingDraft.interests = user.interests
        session.completeOnboarding()
        router.reset()                          // RootView switches to the tabs
    }
}

/// A1's text, read from AuthFeature's own catalog (`bundle: #bundle`, task X-3).
enum SignInText {
    static var title: String { String(localized: "auth.signIn.title", bundle: #bundle) }
    static var subtitle: String { String(localized: "auth.signIn.subtitle", bundle: #bundle) }
    static var google: String { String(localized: "auth.signIn.google", bundle: #bundle) }
    static var email: String { String(localized: "auth.signIn.email", bundle: #bundle) }
    static var appleFailed: String { String(localized: "auth.signIn.appleFailed", bundle: #bundle) }
    static var googleFailed: String { String(localized: "auth.signIn.googleFailed", bundle: #bundle) }
    static var retry: String { String(localized: "auth.signIn.retry", bundle: #bundle) }
    static var terms: String { String(localized: "auth.signIn.terms", bundle: #bundle) }
}
