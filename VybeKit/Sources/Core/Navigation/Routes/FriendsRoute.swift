import Foundation
import Models

/// FR1, PR3 and PR7 (the folder map in `docs/ARCHITECTURE.md` 3.2 puts these screens in FriendsFeature).
public enum FriendsRoute: Hashable, Codable, Sendable {
    case hub
    /// PR3: another person's profile.
    case profile(UserID)
    /// PR7.
    case mutualFriends(UserID)
}

public extension Route {
    static let friendsHub = Route.friends(.hub)
    static func profile(_ id: UserID) -> Route { .friends(.profile(id)) }
    static func mutualFriends(_ id: UserID) -> Route { .friends(.mutualFriends(id)) }
}
