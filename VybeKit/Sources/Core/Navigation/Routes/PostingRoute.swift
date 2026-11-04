import Foundation
import Models

/// PO1 (PO2, Edit post, is a `Sheet`).
public enum PostingRoute: Hashable, Codable, Sendable {
    case compose(RunID)
}

public extension Route {
    static func composePost(_ id: RunID) -> Route { .posting(.compose(id)) }
}
