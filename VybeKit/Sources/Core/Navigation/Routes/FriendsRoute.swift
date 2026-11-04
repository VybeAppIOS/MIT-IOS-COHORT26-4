import Foundation

/// FR1.
public enum FriendsRoute: Hashable, Codable, Sendable {
    case hub
}

public extension Route {
    static let friendsHub = Route.friends(.hub)
}
