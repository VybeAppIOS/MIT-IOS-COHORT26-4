import Foundation

/// Light, dark, or follow the phone (Settings > Appearance). Stored as its raw value.
public enum AppearanceChoice: String, CaseIterable, Sendable {
    case system
    case light
    case dark
}

/// Small settings in `UserDefaults` (Foundation only; `@AppStorage` is SwiftUI and not allowed in Core).
/// Never personal data or tokens.
public struct AppSettings: Sendable {
    private enum Key {
        static let onboardingDone = "onboardingDone"
        static let selectedAreaID = "selectedAreaID"
        static let interests = "interests"
        static let notificationPrefix = "notify."
        static let recentSearches = "recentSearches"
    }

    /// Nil means the app's standard settings. Only the name is stored: `UserDefaults` itself is not `Sendable`,
    /// and every `UserDefaults` object for the same suite shares the same storage.
    private let suiteName: String?

    /// The `UserDefaults` key of the appearance choice. The App reads it with `@AppStorage` (SwiftUI) so a change
    /// applies at once; everything else goes through `appearance` below.
    public static let appearanceKey = "appearance"

    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    public var onboardingDone: Bool {
        get { defaults.bool(forKey: Key.onboardingDone) }
        nonmutating set { defaults.set(newValue, forKey: Key.onboardingDone) }
    }

    /// The area the person picked, for example "kothrud". Nil until chosen.
    public var selectedAreaID: String? {
        get { defaults.string(forKey: Key.selectedAreaID) }
        nonmutating set { defaults.set(newValue, forKey: Key.selectedAreaID) }
    }

    public var interests: [String] {
        get { defaults.stringArray(forKey: Key.interests) ?? [] }
        nonmutating set { defaults.set(newValue, forKey: Key.interests) }
    }

    /// Whether one kind of notification may be sent ("friendRequests", "messages", "likes", "comments",
    /// "reminders"). All start on; the system permission is asked separately, at the first friend request or chat.
    public func notificationOn(_ name: String) -> Bool {
        defaults.object(forKey: Key.notificationPrefix + name) as? Bool ?? true
    }

    public func setNotification(_ name: String, on enabled: Bool) {
        defaults.set(enabled, forKey: Key.notificationPrefix + name)
    }

    public var appearance: AppearanceChoice {
        get { defaults.string(forKey: Self.appearanceKey).flatMap(AppearanceChoice.init(rawValue:)) ?? .system }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.appearanceKey) }
    }

    /// What the person typed in Search, newest first. Small text only; the screen keeps the list short.
    public var recentSearches: [String] {
        get { defaults.stringArray(forKey: Key.recentSearches) ?? [] }
        nonmutating set { defaults.set(newValue, forKey: Key.recentSearches) }
    }

    /// Forget everything (sign out, delete account, reset onboarding).
    public func clear() {
        [Key.onboardingDone, Key.selectedAreaID, Key.interests, Key.recentSearches]
            .forEach(defaults.removeObject(forKey:))
    }
}
