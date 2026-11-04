import Foundation
import Models

/// HD1 and HD3 (HD2, the Spot sheet, is a `Sheet`).
public enum HangoutDetailRoute: Hashable, Codable, Sendable {
    case detail(HangoutID)
    case remixTree(HangoutID)
}

public extension Route {
    static func hangout(_ id: HangoutID) -> Route { .hangoutDetail(.detail(id)) }
    static func remixTree(_ id: HangoutID) -> Route { .hangoutDetail(.remixTree(id)) }
}
