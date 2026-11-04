import Foundation
import Models

public struct SearchResults: Hashable, Sendable {
    public var hangouts: [Hangout]
    public var places: [Place]
    public var people: [UserProfile]

    public init(hangouts: [Hangout] = [], places: [Place] = [], people: [UserProfile] = []) {
        self.hangouts = hangouts
        self.places = places
        self.people = people
    }

    public var isEmpty: Bool { hangouts.isEmpty && places.isEmpty && people.isEmpty }
}

public protocol SearchRepository: Sendable {
    /// Case-insensitive search. Empty or blank text gives empty results. Only the groups in `scope` are filled.
    func search(text: String, scope: Set<SearchKind>) async throws -> SearchResults
}
