import Core
import Foundation
import Models

/// ST8, Delete account. Says what happens, asks for the username to be typed, then deletes: the account on the
/// server (a stub until the backend), any live Hangout, and the person's Saved, Drafts and runs on this phone.
/// Posts stay as "[deleted]" and the username is held for 30 days (decided 3 Nov).
@MainActor @Observable
final class DeleteAccountViewModel {
    enum Phase: Equatable {
        case confirming
        case deleting
        /// Deleting did not go through; nothing on the phone was removed, so the person can try again.
        case failed
    }

    private(set) var phase: Phase = .confirming
    /// What the person typed to confirm.
    var typedUsername = ""

    private let auth: any AuthRepository
    private let session: SessionStore
    private let libraryStore: LibraryStore
    private let liveStore: LiveHangoutStore
    private let network: NetworkMonitor
    private let router: Router

    /// Cheap: nothing loads here (ADR 005).
    init(
        auth: any AuthRepository, session: SessionStore, libraryStore: LibraryStore, liveStore: LiveHangoutStore,
        network: NetworkMonitor, router: Router
    ) {
        self.auth = auth
        self.session = session
        self.libraryStore = libraryStore
        self.liveStore = liveStore
        self.network = network
        self.router = router
    }

    // MARK: What the screen shows

    var title: String { String(localized: "profile.delete.title", bundle: #bundle) }
    var headline: String { String(localized: "profile.delete.headline", bundle: #bundle) }
    /// What happens, one line each, in the order the person needs to know it.
    var consequences: [String] {
        [String(localized: "profile.delete.point.photos", bundle: #bundle),
         String(localized: "profile.delete.point.posts", bundle: #bundle),
         String(localized: "profile.delete.point.phone", bundle: #bundle),
         String(localized: "profile.delete.point.username", bundle: #bundle)]
    }
    var fieldLabel: String {
        String(format: String(localized: "profile.delete.field", bundle: #bundle), username)
    }
    var confirmTitle: String { String(localized: "profile.delete.confirm", bundle: #bundle) }
    var errorMessage: String { String(localized: "profile.delete.error", bundle: #bundle) }
    var offlineMessage: String { String(localized: "profile.delete.offline", bundle: #bundle) }
    var mismatchMessage: String { String(localized: "profile.delete.mismatch", bundle: #bundle) }

    var username: String { session.currentUser?.username ?? "" }
    var isDeleting: Bool { phase == .deleting }
    var hasFailed: Bool { phase == .failed }
    var isOffline: Bool { network.isOffline }

    /// The typed text matches the username (spaces around it, an "@" and capitals do not matter).
    var matches: Bool {
        var typed = typedUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if typed.hasPrefix("@") { typed.removeFirst() }
        return !username.isEmpty && typed == username.lowercased()
    }

    /// Shown under the field only once something has been typed that does not match.
    var fieldError: String? {
        typedUsername.isEmpty || matches ? nil : mismatchMessage
    }

    var canDelete: Bool { matches && !isDeleting && !isOffline }

    // MARK: What the person does

    func deleteTapped() async {
        guard canDelete else { return }
        phase = .deleting
        do {
            try await auth.deleteAccount()   // the server first: if it fails, nothing on the phone is removed
        } catch is CancellationError {
            phase = .confirming   // leaving the screen is not an error (ADR 005)
            return
        } catch {
            phase = .failed
            return
        }
        liveStore.discard()
        await clearLibrary()
        session.setCurrentUser(nil)
        session.resetOnboarding()
        router.reset()   // back to Welcome (O1)
    }

    /// Removes every Saved Hangout, Draft and run (with their owner-only times) from this phone.
    private func clearLibrary() async {
        await libraryStore.ensureLoaded()
        let library = libraryStore.library
        for saved in library.saves { await libraryStore.toggleSave(saved.hangoutID) }
        for draft in library.drafts { await libraryStore.deleteDraft(draft.id) }
        for run in library.runs { libraryStore.removeRun(run.id) }
        await libraryStore.flush()
    }
}
