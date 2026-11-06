#if DEBUG
import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import Vybe

/// Stands in for `LocalSearchRepository`: fixed Hangouts and Places, never any people, and it remembers its scope.
private final class FakeLocalSearch: SearchRepository {
    let scopes = Mutex<[Set<SearchKind>]>([])

    func search(text: String, scope: Set<SearchKind>) async throws -> SearchResults {
        scopes.withLock { $0.append(scope) }
        return SearchResults(
            hangouts: scope.contains(.hangouts) ? SampleData.hangouts : [],
            places: scope.contains(.places) ? SampleData.places : [])
    }
}

/// While friends are stubbed, People must be found in the sample people; Hangouts and Places stay local.
struct SampleSocialSearchRepositoryTests {
    private let everything = Set(SearchKind.allCases)

    @Test func hangoutsAndPlacesStayLocal() async throws {
        let local = FakeLocalSearch()
        let found = try await SampleSocialSearchRepository(wrapping: local).search(text: "a", scope: everything)
        #expect(found.hangouts == SampleData.hangouts && found.places == SampleData.places)
        // The local repository is never asked for people.
        #expect(local.scopes.withLock { $0 } == [[.hangouts, .places]])
    }

    @Test func peopleAreFoundByNameOrUsernameInTheSamplePeople() async throws {
        let repository = SampleSocialSearchRepository(wrapping: FakeLocalSearch())
        let person = SampleSocialData.aarav
        let byName = try await repository.search(text: person.displayName, scope: [.people])
        #expect(byName.people.contains { $0.id == person.id })
        let byUsername = try await repository.search(text: person.username, scope: [.people])
        #expect(byUsername.people.contains { $0.id == person.id })
        #expect(byName.people.allSatisfy { found in SampleSocialData.people.contains { $0.id == found.id } })
    }

    @Test func peopleAreOnlySearchedWhenAsked() async throws {
        let repository = SampleSocialSearchRepository(wrapping: FakeLocalSearch())
        let found = try await repository.search(text: SampleSocialData.aarav.displayName, scope: [.hangouts])
        #expect(found.people.isEmpty)
    }

    @Test func blankTextAndNoMatchGiveNoPeople() async throws {
        let repository = SampleSocialSearchRepository(wrapping: FakeLocalSearch())
        #expect(try await repository.search(text: "   ", scope: everything).people.isEmpty)
        #expect(try await repository.search(text: "zzzzqq", scope: everything).people.isEmpty)
    }
}
#endif
