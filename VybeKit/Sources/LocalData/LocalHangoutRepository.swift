import Core
import Foundation
import Models

/// Hangouts from the bundled content. Only published Hangouts are returned; drafts are the person's own (Library).
public struct LocalHangoutRepository: HangoutRepository {
    private let content: ContentStore

    public init(content: ContentStore) {
        self.content = content
    }

    public func hangout(id: HangoutID) async throws -> Hangout {
        let hangouts = try await content.snapshot().hangouts
        guard let found = hangouts.first(where: { $0.id == id && $0.status == .published }) else {
            throw AppError.notFound
        }
        return found
    }

    /// Filters: the budget range must fit inside the chosen one; every chosen tag must be present; a chosen category
    /// must appear among the Spots' Places. With a `center`, nearest first (by the nearest Spot); otherwise Picks
    /// first, then newest.
    public func hangouts(near center: Coordinate?, filters: HangoutFilters) async throws -> [Hangout] {
        let snapshot = try await content.snapshot()
        let places = Dictionary(snapshot.places.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let matching = snapshot.hangouts.filter { $0.status == .published && Self.matches($0, filters, places) }
        if let center {
            return matching
                .map { (hangout: $0, meters: Self.distance(of: $0, from: center, places)) }
                .sorted { $0.meters < $1.meters }
                .map(\.hangout)
        }
        return matching.sorted { ($0.isPick ? 0 : 1, $1.updatedAt) < ($1.isPick ? 0 : 1, $0.updatedAt) }
    }

    public func picks() async throws -> [Hangout] {
        try await content.snapshot().hangouts.filter { $0.isPick && $0.status == .published }
    }

    public func remixes(of id: HangoutID) async throws -> [Hangout] {
        try await content.snapshot().hangouts.filter { $0.remixedFromID == id && $0.status == .published }
    }

    /// The server keeps the real counts (Phase 2). Locally, only Remixes can be counted from the content.
    public func stats(for id: HangoutID) async throws -> HangoutStats {
        HangoutStats(doneCount: 0, remixCount: try await remixes(of: id).count)
    }

    private static func matches(_ hangout: Hangout, _ filters: HangoutFilters, _ places: [PlaceID: Place]) -> Bool {
        if let budget = filters.budget,
           hangout.budgetPerPerson.lower < budget.lower || hangout.budgetPerPerson.upper > budget.upper { return false }
        if let maxMinutes = filters.maxMinutes, hangout.estimatedMinutes > maxMinutes { return false }
        if !filters.tags.isSubset(of: hangout.tags) { return false }
        if !filters.vibeTags.isSubset(of: hangout.vibeTags) { return false }
        if filters.goodForGroups && !hangout.tags.contains("good-for-groups") { return false }
        if !filters.categories.isEmpty {
            let categories = Set(hangout.spots.compactMap { places[$0.placeID]?.category })
            if categories.isDisjoint(with: filters.categories) { return false }
        }
        return true
    }

    private static func distance(of hangout: Hangout, from center: Coordinate, _ places: [PlaceID: Place]) -> Double {
        hangout.spots.compactMap { places[$0.placeID] }.map { center.meters(to: $0.coordinate) }.min() ?? .infinity
    }
}

extension Coordinate {
    /// Straight-line distance in metres (haversine).
    func meters(to other: Coordinate) -> Double {
        let earthRadius = 6_371_000.0
        let latitude1 = latitude * .pi / 180
        let latitude2 = other.latitude * .pi / 180
        let deltaLatitude = (other.latitude - latitude) * .pi / 180
        let deltaLongitude = (other.longitude - longitude) * .pi / 180
        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(latitude1) * cos(latitude2) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return earthRadius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
    }
}
