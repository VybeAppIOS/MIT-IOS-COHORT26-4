import Foundation

/// Small settings in `UserDefaults` (Foundation only; `@AppStorage` is SwiftUI and not allowed in Core).
/// Never personal data or tokens.
public struct AppSettings: Sendable {
    private enum Key {
        static let onboardingDone = "onboardingDone"
        static let selectedAreaID = "selectedAreaID"
        static let interests = "interests"
        static let recentSearches = "recentSearches"
    }

    /// Nil means the app's standard settings. Only the name is stored: `UserDefaults` itself is not `Sendable`,
    /// and every `UserDefaults` object for the same suite shares the same storage.
    private let suiteName: String?

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
