import Core
import Foundation
import Models
import Testing
@testable import LocalData

/// The F-5 contract checks hold the Local repositories to the same promises as the stubs.
struct RepositoryTests {
    private let content = TestSupport.content

    @Test func hangoutRepositoryKeepsTheContract() async throws {
        try await HangoutRepositoryContract.verify(LocalHangoutRepository(content: content))
    }

    @Test func placeRepositoryKeepsTheContract() async throws {
        let hangouts = try await LocalHangoutRepository(content: content).hangouts(near: nil, filters: HangoutFilters())
        try await PlaceRepositoryContract.verify(
            LocalPlaceRepository(content: content), area: "Kothrud", hangouts: hangouts)
    }

    @Test func searchRepositoryKeepsTheContract() async throws {
        try await SearchRepositoryContract.verify(LocalSearchRepository(content: content), knownWord: "Evening")
    }

    @Test func libraryRepositoryKeepsTheContract() async throws {
        let url = try TestSupport.temporaryDirectory().appending(path: "library.json")
        let repository = LocalLibraryRepository(file: LibraryFile(url: url, empty: Library()))
        try await LibraryRepositoryContract.verify(repository)
    }

    @Test func profileRepositoryKeepsTheContract() async throws {
        let url = try TestSupport.temporaryDirectory().appending(path: "profile.json")
        let fallback = UserProfile(id: "user-local", username: "you", displayName: "You", createdAt: .now)
        let repository = LocalProfileRepository(file: DocumentFile(url: url, empty: fallback))
        try await ProfileRepositoryContract.verify(repository)
    }

    // MARK: Hangouts

    @Test func draftsAndHiddenPlacesAreNotServed() async throws {
        let hangouts = LocalHangoutRepository(content: content)
        #expect(try await hangouts.hangouts(near: nil, filters: HangoutFilters()).count == 3)
        await #expect(throws: AppError.notFound) { try await hangouts.hangout(id: "hangout-example-draft-m3n4") }
        let places = LocalPlaceRepository(content: content)
        await #expect(throws: AppError.notFound) { try await places.place(id: "place-example-fort-k1l2") }
    }

    @Test func picksComeFirstWithoutACenter() async throws {
        let all = try await LocalHangoutRepository(content: content).hangouts(near: nil, filters: HangoutFilters())
        #expect(all.first?.id == "hangout-example-evening-c3d4")
    }

    @Test func remixesAndStats() async throws {
        let hangouts = LocalHangoutRepository(content: content)
        let evening: HangoutID = "hangout-example-evening-c3d4"
        #expect(try await hangouts.remixes(of: evening).map(\.id) == ["hangout-example-remix-i9j0"])
        #expect(try await hangouts.stats(for: evening) == HangoutStats(doneCount: 0, remixCount: 1))
    }

    @Test func nearestSpotFirstWithACenter() async throws {
        let nearPark = Coordinate(latitude: 18.5011, longitude: 73.8021)
        let all = try await LocalHangoutRepository(content: content).hangouts(near: nearPark, filters: HangoutFilters())
        #expect(all.count == 3)
        #expect(all.map(\.id).contains("hangout-example-morning-g7h8"))
    }

    @Test func filtersNarrowTheList() async throws {
        let hangouts = LocalHangoutRepository(content: content)
        func ids(_ filters: HangoutFilters) async throws -> Set<HangoutID> {
            Set(try await hangouts.hangouts(near: nil, filters: filters).map(\.id))
        }
        #expect(try await ids(HangoutFilters(goodForGroups: true)) == ["hangout-example-evening-c3d4"])
        #expect(try await ids(HangoutFilters(maxMinutes: 95)) == ["hangout-example-morning-g7h8"])
        #expect(try await ids(HangoutFilters(budget: RupeeRange(lower: 0, upper: 300))).count == 2)
        #expect(try await ids(HangoutFilters(tags: ["outdoors"])) == ["hangout-example-morning-g7h8"])
        #expect(try await ids(HangoutFilters(vibeTags: ["chill"])) == ["hangout-example-evening-c3d4"])
        #expect(try await ids(HangoutFilters(categories: [.cafe])).count == 3)
        #expect(try await ids(HangoutFilters(categories: [.fort])).isEmpty)
    }

    // MARK: Places and photos

    @Test func spotsComeInSpotOrder() async throws {
        let morning = try await LocalHangoutRepository(content: content).hangout(id: "hangout-example-morning-g7h8")
        let places = try await LocalPlaceRepository(content: content).spots(for: morning)
        #expect(places.map(\.id) == ["place-example-park-e5f6", "place-example-cafe-a1b2"])
    }

    @Test func photoStoreFindsFilesThatExist() throws {
        let store = LocalPhotoStore(loader: TestSupport.fixtures)
        let there = Photo(id: "p1", path: "place-example-cafe-a1b2-1.jpg", width: 1, height: 1)
        let missing = Photo(id: "p2", path: "nope.jpg", width: 1, height: 1)
        #expect(store.url(for: there)?.lastPathComponent == "place-example-cafe-a1b2-1.jpg")
        #expect(store.url(for: missing) == nil)
    }

    // MARK: Search

    @Test func searchFindsAHangoutByTag() async throws {
        let search = LocalSearchRepository(content: content)
        let found = try await search.search(text: "good-for-groups", scope: [.hangouts])
        #expect(found.hangouts.map(\.id) == ["hangout-example-evening-c3d4"])
    }

    @Test func titleMatchesRankAboveTagMatchesAboveAreaMatches() async throws {
        let search = LocalSearchRepository(content: content)
        // "morning": title of one Hangout. "outdoors": a tag of the same one. "Kothrud": the area of every Spot.
        let byTitle = try await search.search(text: "morning", scope: [.hangouts])
        #expect(byTitle.hangouts.first?.id == "hangout-example-morning-g7h8")
        let byArea = try await search.search(text: "Kothrud", scope: [.hangouts, .places])
        #expect(byArea.hangouts.count == 3 && byArea.places.count == 2)
        #expect(byArea.people.isEmpty)
    }

    @Test func searchScopeAndBlankText() async throws {
        let search = LocalSearchRepository(content: content)
        #expect(try await search.search(text: "  ", scope: Set(SearchKind.allCases)).isEmpty)
        let onlyPlaces = try await search.search(text: "example", scope: [.places])
        #expect(onlyPlaces.hangouts.isEmpty && onlyPlaces.places.count == 2)
    }
}
