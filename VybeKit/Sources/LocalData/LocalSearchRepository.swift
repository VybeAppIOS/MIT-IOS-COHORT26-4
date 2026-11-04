import Core
import Foundation
import Models

/// On-device search over the bundled content. Score: a title match counts 3, a tag match 2, an area match 1.
/// Best match first, ties by title. People are not searchable yet (no people in Phase 1 content).
public struct LocalSearchRepository: SearchRepository {
    private let content: ContentStore

    public init(content: ContentStore) {
        self.content = content
    }

    public func search(text: String, scope: Set<SearchKind>) async throws -> SearchResults {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SearchResults() }
        let snapshot = try await content.snapshot()
        let places = Dictionary(snapshot.places.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var hangouts: [(hangout: Hangout, score: Int)] = []
        if scope.contains(.hangouts) {
            for hangout in snapshot.hangouts where hangout.status == .published {
                let areas = hangout.spots.compactMap { places[$0.placeID]?.area }
                let score = Self.score(title: hangout.title, tags: hangout.tags + hangout.vibeTags, areas: areas, query)
                if score > 0 { hangouts.append((hangout, score)) }
            }
        }
        var found: [(place: Place, score: Int)] = []
        if scope.contains(.places) {
            for place in snapshot.places where place.status != .hidden {
                let words = place.category.rawValue.replacingOccurrences(of: "-", with: " ")
                let score = Self.score(title: place.name, tags: [words], areas: [place.area], query)
                if score > 0 { found.append((place, score)) }
            }
        }
        return SearchResults(
            hangouts: hangouts.sorted { ($1.score, $0.hangout.title) < ($0.score, $1.hangout.title) }.map(\.hangout),
            places: found.sorted { ($1.score, $0.place.name) < ($0.score, $1.place.name) }.map(\.place))
    }

    private static func score(title: String, tags: [String], areas: [String], _ query: String) -> Int {
        (title.localizedStandardContains(query) ? 3 : 0)
            + (tags.contains { $0.localizedStandardContains(query) } ? 2 : 0)
            + (areas.contains { $0.localizedStandardContains(query) } ? 1 : 0)
    }
}
