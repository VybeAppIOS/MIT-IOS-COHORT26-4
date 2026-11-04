import Foundation
import Models

/// PR2 to PR8 and ST1 to ST8 (PR1 is the root of the Profile tab, PR6 Edit profile a local sheet).
public enum ProfileRoute: Hashable, Codable, Sendable {
    /// PR3: another person's profile.
    case person(UserID)
    /// PR4.
    case saved
    /// PR5.
    case drafts
    /// PR7.
    case mutualFriends(UserID)
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
    static func profile(_ id: UserID) -> Route { .profile(.person(id)) }
    static func mutualFriends(_ id: UserID) -> Route { .profile(.mutualFriends(id)) }
    static let saved = Route.profile(.saved)
    static let drafts = Route.profile(.drafts)
    static let readyToPost = Route.profile(.readyToPost)
    static let settings = Route.profile(.settings)
    static func settingsPage(_ page: SettingsPage) -> Route { .profile(.settingsPage(page)) }
    static let deleteAccount = Route.profile(.deleteAccount)
}
