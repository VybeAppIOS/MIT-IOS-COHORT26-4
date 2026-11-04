import Core
import Foundation
import Models

/// Places from the bundled content. Hidden Places are never returned; Places closed by the authorities are, so the
/// Spot sheet can warn about them.
public struct LocalPlaceRepository: PlaceRepository {
    private let content: ContentStore

    public init(content: ContentStore) {
        self.content = content
    }

    public func place(id: PlaceID) async throws -> Place {
        guard let found = try await content.snapshot().places.first(where: { $0.id == id && $0.status != .hidden })
        else { throw AppError.notFound }
        return found
    }

    public func places(in area: String) async throws -> [Place] {
        try await content.snapshot().places.filter {
            $0.status != .hidden && $0.area.caseInsensitiveCompare(area) == .orderedSame
        }
    }

    public func spots(for hangout: Hangout) async throws -> [Place] {
        let places = try await content.snapshot().places.filter { $0.status != .hidden }
        return hangout.spots.compactMap { spot in places.first { $0.id == spot.placeID } }
    }
}
