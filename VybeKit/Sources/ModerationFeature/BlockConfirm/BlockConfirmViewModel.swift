import Core
import Foundation
import Models

/// R2, Block confirm. Explains what blocking does, then blocks. Opened with `router.present(.blockConfirm(userID))`
/// from the Report screen, a person's profile and a chat. Unblocking lives in Settings (ST3).
@MainActor @Observable
final class BlockConfirmViewModel {
    enum Phase: Equatable {
        case asking
        case blocking
        /// The block did not go through. The sheet stays so they can try again.
        case failed
    }

    private(set) var phase: Phase = .asking
    /// Loaded from the profile. Until it arrives (or if it never does) the title says "this person".
    private(set) var name: String?

    private let userID: UserID
    private let profiles: any ProfileRepository
    private let safety: any SafetyRepository
    private let session: SessionStore
    private let router: Router

    /// Cheap: nothing loads here (ADR 005).
    init(
        userID: UserID, profiles: any ProfileRepository, safety: any SafetyRepository, session: SessionStore,
        router: Router
    ) {
        self.userID = userID
        self.profiles = profiles
        self.safety = safety
        self.session = session
        self.router = router
    }

    var title: String {
        guard let name else { return String(localized: "moderation.block.title.generic", bundle: #bundle) }
        return String(format: String(localized: "moderation.block.title.named", bundle: #bundle), name)
    }

    var message: String { String(localized: "moderation.block.body", bundle: #bundle) }
    var confirmTitle: String { String(localized: "moderation.block.confirm", bundle: #bundle) }
    var errorMessage: String { String(localized: "moderation.block.error", bundle: #bundle) }
    var isBlocking: Bool { phase == .blocking }
    var hasFailed: Bool { phase == .failed }

    /// Called by `.task`. Only the name; a failure just keeps the generic title.
    func load() async {
        guard name == nil else { return }
        name = try? await profiles.profile(id: userID).displayName
    }

    func blockTapped() async {
        guard phase != .blocking else { return }
        phase = .blocking
        do {
            try await safety.block(userID)
            session.block(userID)   // every screen that filters on blockedIDs hides them at once
            router.dismissSheet()
        } catch is CancellationError {
            phase = .asking   // leaving the screen is not an error (ADR 005)
        } catch {
            phase = .failed
        }
    }

    func cancelTapped() { router.dismissSheet() }
}
