import Foundation
import Models

/// H3 (H1 is the live cover's root, H2 a local sheet, H4 a bar above the tabs).
public enum LiveRoute: Hashable, Codable, Sendable {
    case summary(RunID)
}

public extension Route {
    static func liveSummary(_ id: RunID) -> Route { .live(.summary(id)) }
}
