#if DEBUG
import Core
import Foundation
import Models

/// Debug builds run friends on the sample social data, but `LocalSearchRepository` has no people (there are none in
/// the bundled content), so Search's People group was always empty. This wrapper keeps Hangouts and Places on the
/// local repository and answers People from `SampleSocialData.people`, matching the name or the @username the same
/// way the stub does. Blocked people and "you" are left out by the screens, not here. Phase 2 (the backend) searches
/// people on the server and removes this file.
struct SampleSocialSearchRepository: SearchRepository {
    private let local: any SearchRepository
    private let people: [UserProfile]

    init(wrapping local: any SearchRepository, people: [UserProfile] = SampleSocialData.people) {
        self.local = local
        self.people = people
    }

    func search(text: String, scope: Set<SearchKind>) async throws -> SearchResults {
        var found = try await local.search(text: text, scope: scope.subtracting([.people]))
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if scope.contains(.people), !query.isEmpty {
            found.people = people.filter {
                $0.displayName.localizedStandardContains(query) || $0.username.localizedStandardContains(query)
            }
        }
        return found
    }
}
#endif
