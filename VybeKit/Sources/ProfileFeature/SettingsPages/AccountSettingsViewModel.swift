import Core
import Foundation
import Models

/// ST1, Account. Who you are signed in as, Sign out (confirmed) and the way to Delete account (ST8).
/// Real sign-in arrives with the backend; until then the account is the sample person.
@MainActor @Observable
final class AccountSettingsViewModel {
    enum Phase: Equatable {
        case idle
        case signingOut
        /// Signing out did not go through; the person stays signed in and can try again.
        case failed
    }

    private(set) var phase: Phase = .idle
    /// The "Sign out?" confirmation is up.
    var isConfirmingSignOut = false

    private let auth: any AuthRepository
    private let session: SessionStore
    private let network: NetworkMonitor
    private let router: Router

    /// Cheap: nothing loads here (ADR 005).
    init(auth: any AuthRepository, session: SessionStore, network: NetworkMonitor, router: Router) {
        self.auth = auth
        self.session = session
        self.network = network
        self.router = router
    }

    // MARK: What the screen shows

    var title: String { String(localized: "profile.account.title", bundle: #bundle) }
    var nameLabel: String { String(localized: "profile.account.name", bundle: #bundle) }
    var usernameLabel: String { String(localized: "profile.account.username", bundle: #bundle) }
    var signInLabel: String { String(localized: "profile.account.signIn", bundle: #bundle) }
    var signInValue: String { String(localized: "profile.account.signIn.sample", bundle: #bundle) }
    var signOutTitle: String { String(localized: "profile.account.signOut", bundle: #bundle) }
    var signOutConfirmTitle: String { String(localized: "profile.account.signOut.confirm", bundle: #bundle) }
    var signOutMessage: String { String(localized: "profile.account.signOut.message", bundle: #bundle) }
    var deleteTitle: String { String(localized: "profile.account.delete", bundle: #bundle) }
    var deleteSubtitle: String { String(localized: "profile.account.delete.subtitle", bundle: #bundle) }
    var errorMessage: String { String(localized: "profile.account.signOut.error", bundle: #bundle) }
    var offlineMessage: String { String(localized: "profile.account.offline", bundle: #bundle) }

    var name: String { session.currentUser?.displayName ?? "" }
    var username: String { session.currentUser.map { "@\($0.username)" } ?? "" }
    var isOffline: Bool { network.isOffline }
    var isSigningOut: Bool { phase == .signingOut }
    var hasFailed: Bool { phase == .failed }
    /// Signing out needs the server once there is one, so it waits for a connection.
    var canSignOut: Bool { !isOffline && !isSigningOut }

    // MARK: What the person does

    func signOutTapped() { isConfirmingSignOut = true }

    /// Signs out, forgets who was signed in and goes back to the Welcome screen with every stack cleared.
    func signOutConfirmed() async {
        guard canSignOut else { return }
        isConfirmingSignOut = false
        phase = .signingOut
        do {
            try await auth.signOut()
            session.setCurrentUser(nil)
            session.resetOnboarding()
            router.reset()
            phase = .idle
        } catch is CancellationError {
            phase = .idle   // leaving the screen is not an error (ADR 005)
        } catch {
            phase = .failed
        }
    }

    func deleteAccountTapped() { router.open(.deleteAccount) }
}
