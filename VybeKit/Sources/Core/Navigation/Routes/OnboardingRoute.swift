import Foundation

/// O2 to O5 (O1 Welcome is the root of the onboarding stack).
public enum OnboardingRoute: Hashable, Codable, Sendable {
    case nameAndPhoto
    case interests
    case location
    case findFriends
}

public extension Route {
    static let nameAndPhoto = Route.onboarding(.nameAndPhoto)
    static let interests = Route.onboarding(.interests)
    static let location = Route.onboarding(.location)
    static let findFriends = Route.onboarding(.findFriends)
}
