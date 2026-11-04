import Foundation
import Models

/// CM2, CM4 and CM5 (CM1 Feed is the root of the Community tab, CM3 Comments a local sheet).
public enum CommunityRoute: Hashable, Codable, Sendable {
    case post(RunID)
    case trending
    case activity
}

public extension Route {
    static func post(_ id: RunID) -> Route { .community(.post(id)) }
    static let trending = Route.community(.trending)
    static let activity = Route.community(.activity)
}
