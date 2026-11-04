import Foundation

/// PR2, PR4, PR5, PR8 and ST1 to ST8 (PR1 is the root of the Profile tab, PR6 Edit profile a local sheet;
/// PR3 and PR7 belong to Friends).
public enum ProfileRoute: Hashable, Codable, Sendable {
    /// PR4.
    case saved
    /// PR5.
    case drafts
    /// PR8.
    case readyToPost
    /// PR2: the Settings root.
    case settings
    /// ST1 to ST7.
    case settingsPage(SettingsPage)
    /// ST8.
    case deleteAccount
}

public extension Route {
    static let saved = Route.profile(.saved)
    static let drafts = Route.profile(.drafts)
    static let readyToPost = Route.profile(.readyToPost)
    static let settings = Route.profile(.settings)
    static func settingsPage(_ page: SettingsPage) -> Route { .profile(.settingsPage(page)) }
    static let deleteAccount = Route.profile(.deleteAccount)
}
