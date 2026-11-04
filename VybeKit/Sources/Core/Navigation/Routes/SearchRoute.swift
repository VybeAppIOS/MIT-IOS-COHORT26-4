import Foundation

/// S2 (S1 is the root of the Search tab).
public enum SearchRoute: Hashable, Codable, Sendable {
    case seeAll(SearchKind)
}

public extension Route {
    static func searchSeeAll(_ kind: SearchKind) -> Route { .search(.seeAll(kind)) }
}
