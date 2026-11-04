import Foundation

/// A1 to A3.
public enum AuthRoute: Hashable, Codable, Sendable {
    case signIn
    case emailSignIn
    case accountBasics
}

public extension Route {
    static let signIn = Route.auth(.signIn)
    static let emailSignIn = Route.auth(.emailSignIn)
    static let accountBasics = Route.auth(.accountBasics)
}
