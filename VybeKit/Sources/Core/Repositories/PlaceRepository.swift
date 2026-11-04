import Foundation
import Models

public protocol PlaceRepository: Sendable {
    func place(id: PlaceID) async throws -> Place
    /// Approved Places in an area, for example "Kothrud".
    func places(in area: String) async throws -> [Place]
    /// The Places of a Hangout's Spots, in Spot order. A Spot whose Place is missing is left out.
    func spots(for hangout: Hangout) async throws -> [Place]
}
