import Foundation
import Testing
@testable import Models

struct ContentModelsTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONCoding.decoder.decode(type, from: Data(json.utf8))
    }

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        try JSONCoding.decoder.decode(T.self, from: JSONCoding.encoder.encode(value))
    }

    private func keys<T: Encodable>(of value: T) throws -> Set<String> {
        let object = try JSONSerialization.jsonObject(with: JSONCoding.encoder.encode(value))
        return Set(try #require(object as? [String: Any]).keys)
    }

    // MARK: Place

    @Test func decodesExamplePlace() throws {
        let place = try decode(Place.self, ContentFixtures.examplePlace)
        #expect(place.id == "place-example-cafe-a1b2")
        #expect(place.category == .cafe)
        #expect(place.coordinate == Coordinate(latitude: 18.5, longitude: 73.8))
        #expect(place.costPerPerson.formattedPerPerson == "₹100–250")
        #expect(place.hours == [OpeningPeriod(weekday: 1, open: "09:00", close: "22:00"),
                                OpeningPeriod(weekday: 2, open: "09:00", close: "22:00")])
        #expect(place.hoursNote == nil && place.applePlaceID == nil && place.trekInfo == nil)
        #expect(place.photos.first?.credit == "EXAMPLE Teammate")
        #expect(place.status == .approved)
        #expect(place.verifiedAt == Date(timeIntervalSince1970: 1_793_700_000))
    }

    @Test func placeRoundTripsAndIgnoresUnknownKeys() throws {
        let place = try decode(Place.self, ContentFixtures.examplePlace)
        #expect(try roundTrip(place) == place)
        let extra = ContentFixtures.examplePlace.replacingOccurrences(
            of: "\"schemaVersion\": 1,", with: "\"schemaVersion\": 1, \"futureField\": [1, 2],")
        #expect(try decode(Place.self, extra) == place)
    }

    @Test func decodesTrekWithClosedStatusAndFractionalDate() throws {
        let place = try decode(Place.self, ContentFixtures.exampleTrek)
        #expect(place.status == .closedByAuthorities)
        #expect(place.trekInfo?.difficulty == .moderate)
        #expect(place.trekInfo?.safetyNote == "EXAMPLE note")
        #expect(place.hours.isEmpty)
        // The fraction is read (.500) but written back as whole seconds, so compare without the fraction.
        #expect(abs(place.verifiedAt.timeIntervalSince1970 - 1_793_700_000.5) < 0.001)
        var wholeSeconds = place
        wholeSeconds.verifiedAt = Date(timeIntervalSince1970: 1_793_700_000)
        #expect(try roundTrip(wholeSeconds) == wholeSeconds)
    }

    @Test(arguments: [
        ("cafe", PlaceCategory.cafe), ("viewpoint-hill", .viewpointHill), ("park-garden", .parkGarden),
        ("chai-tapri", .chaiTapri), ("heritage-temple", .heritageTemple), ("restaurant", .restaurant),
        ("museum", .museum), ("cinema", .cinema)
    ])
    func categoriesFromContentFilesDecode(raw: String, expected: PlaceCategory) throws {
        #expect(try decode(PlaceCategory.self, "\"\(raw)\"") == expected)
    }

    @Test func unknownCategoryAndDifficultyFallBackInsteadOfFailing() throws {
        #expect(try decode(PlaceCategory.self, "\"teleporter-pad\"") == .unknown)
        #expect(try decode(TrekDifficulty.self, "\"extreme\"") == .unknown)
    }

    // MARK: Hangout

    @Test func decodesExampleHangoutKeepingSpotOrder() throws {
        let hangout = try decode(Hangout.self, ContentFixtures.exampleHangout)
        #expect(hangout.spots.map(\.id) == ["s1", "s2"])
        #expect(hangout.spots[0].minutes == 45 && hangout.spots[1].note == nil)
        #expect(hangout.budgetPerPerson.formattedPerPerson == "₹150–400")
        #expect(hangout.isPick && hangout.status == .published)
        #expect(hangout.remixedFromID == nil && hangout.remixedFromPlaceIDs == nil)
        #expect(hangout.authorID == "user-vybe-team")
        #expect(hangout.tags == ["good-for-groups"] && hangout.vibeTags == ["chill"])
    }

    @Test func hangoutRoundTripsAndHasNoServerCounts() throws {
        let hangout = try decode(Hangout.self, ContentFixtures.exampleHangout)
        #expect(try roundTrip(hangout) == hangout)
        #expect(try keys(of: hangout) == [
            "id", "title", "summary", "spots", "budgetPerPerson", "estimatedMinutes", "bestTimes", "tags", "vibeTags",
            "authorID", "isPick", "status", "createdAt", "updatedAt"
        ])
    }

    @Test func tenSpotsKeepTheirOrder() throws {
        let spots = (1...10).map { Spot(id: SpotID("s\($0)"), placeID: PlaceID("p\($0)")) }
        let hangout = Hangout(id: "h", title: "EXAMPLE", summary: "EXAMPLE", spots: spots,
                              budgetPerPerson: RupeeRange(lower: 0, upper: 0), estimatedMinutes: 60,
                              authorID: "u", createdAt: .now, updatedAt: .now)
        #expect(try roundTrip(hangout).spots.map(\.id.rawValue) == (1...10).map { "s\($0)" })
    }

    @Test func remixKeepsItsOriginAndPlaces() throws {
        let json = ContentFixtures.exampleHangout
            .replacingOccurrences(of: "\"remixedFromID\": null", with: "\"remixedFromID\": \"hangout-example-x-0000\"")
            .replacingOccurrences(of: "\"remixedFromPlaceIDs\": null",
                                  with: "\"remixedFromPlaceIDs\": [\"p1\", \"p2\"]")
        let remix = try decode(Hangout.self, json)
        #expect(remix.remixedFromID == "hangout-example-x-0000")
        #expect(remix.remixedFromPlaceIDs == ["p1", "p2"])
        #expect(try roundTrip(remix) == remix)
    }

    @Test func draftStatusDecodes() throws {
        let json = ContentFixtures.exampleHangout.replacingOccurrences(of: "\"published\"", with: "\"draft\"")
        #expect(try decode(Hangout.self, json).status == .draft)
    }

    @Test func filtersStartEmptyAndRoundTrip() throws {
        #expect(HangoutFilters() == HangoutFilters(categories: [], tags: [], goodForGroups: false))
        let filters = HangoutFilters(budget: RupeeRange(lower: 0, upper: 300), maxMinutes: 180,
                                     categories: [.cafe, .parkGarden], tags: ["good-for-groups"], goodForGroups: true)
        #expect(try roundTrip(filters) == filters)
    }
}
