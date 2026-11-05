import Foundation
import Models
import Observation

/// What onboarding collects before it is saved (O2 to O4).
public struct OnboardingDraft: Hashable, Sendable {
    public var name: String
    public var photo: Photo?
    public var interests: [String]
    public var areaID: String?

    public init(name: String = "", photo: Photo? = nil, interests: [String] = [], areaID: String? = nil) {
        self.name = name
        self.photo = photo
        self.interests = interests
        self.areaID = areaID
    }
}

/// Who is using the app and whether onboarding is done. Shared by every tab.
@MainActor @Observable
public final class SessionStore {
    public private(set) var currentUser: UserProfile?
    public private(set) var onboardingDone: Bool
    public private(set) var blockedIDs: Set<UserID>
    /// Shows the hidden admin pages in Settings. The server enforces access; this only hides the entry.
    public private(set) var isTeamAccount: Bool
    public var onboardingDraft = OnboardingDraft()

    private let settings: AppSettings

    public init(
        settings: AppSettings, currentUser: UserProfile? = nil, blockedIDs: Set<UserID> = [],
        isTeamAccount: Bool = false
    ) {
        self.settings = settings
        self.currentUser = currentUser
        self.blockedIDs = blockedIDs
        self.isTeamAccount = isTeamAccount
        onboardingDone = settings.onboardingDone
    }

    public func setCurrentUser(_ user: UserProfile?) { currentUser = user }

    public func isBlocked(_ id: UserID) -> Bool { blockedIDs.contains(id) }

    #if DEBUG
    /// Debug launch option `-teamAccount`: opens the admin pages for a screenshot (in release the server decides).
    public func debugSetTeamAccount(_ enabled: Bool) { isTeamAccount = enabled }
    #endif

    /// Called after `SafetyRepository.block` succeeds, so every screen that filters on `blockedIDs` hides them at once.
    public func block(_ id: UserID) { blockedIDs.insert(id) }

    /// Called after `SafetyRepository.unblock` succeeds (the Blocked list in Settings).
    public func unblock(_ id: UserID) { blockedIDs.remove(id) }

    /// Saves the onboarding draft (interests and area to settings; name and photo onto the current user).
    public func completeOnboarding() {
        let draft = onboardingDraft
        settings.interests = draft.interests
        settings.selectedAreaID = draft.areaID
        if var user = currentUser {
            if !draft.name.isEmpty { user.displayName = draft.name }
            if let photo = draft.photo { user.photo = photo }
            user.interests = draft.interests
            currentUser = user
        }
        settings.onboardingDone = true
        onboardingDone = true
        onboardingDraft = OnboardingDraft()
    }

    /// Back to the Welcome screen with an empty draft ("reset onboarding" in Settings).
    public func resetOnboarding() {
        settings.clear()
        onboardingDone = false
        onboardingDraft = OnboardingDraft()
    }
}
