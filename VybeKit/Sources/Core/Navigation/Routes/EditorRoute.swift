import Foundation

/// E3 pushed inside a sheet's own stack (E1 is the editor cover's root, E2 a local sheet).
public enum EditorRoute: Hashable, Codable, Sendable {
    case suggestPlace
}

public extension Route {
    static let suggestPlace = Route.editor(.suggestPlace)
}
