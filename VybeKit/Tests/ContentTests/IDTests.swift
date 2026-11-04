import Foundation
import Testing
@testable import Models

struct IDTests {
    @Test func encodesAsPlainJSONString() throws {
        let data = try JSONCoding.encoder.encode(["id": PlaceID("place-fc-road-ab12")])
        #expect(String(bytes: data, encoding: .utf8) == #"{"id":"place-fc-road-ab12"}"#)
    }

    @Test func decodesFromPlainJSONString() throws {
        let id = try JSONCoding.decoder.decode(PlaceID.self, from: Data(#""place-fc-road-ab12""#.utf8))
        #expect(id == "place-fc-road-ab12")
        #expect(id.rawValue == "place-fc-road-ab12")
    }

    /// The data-format trap from ADR 004: without `CodingKeyRepresentable` this becomes a flat array.
    @Test func dictionaryKeyedByIDEncodesAsJSONObject() throws {
        let visitedAt: [SpotID: Date] = ["s1": Date(timeIntervalSince1970: 1_793_000_000)]
        let data = try JSONCoding.encoder.encode(visitedAt)
        let json = try JSONSerialization.jsonObject(with: data)
        let object = try #require(json as? [String: String])
        #expect(object.keys.contains("s1"))
        #expect(!(json is [Any]))
    }

    @Test func dictionaryKeyedByIDRoundTrips() throws {
        let original: [SpotID: Int] = ["s1": 1, "s2": 2]
        let data = try JSONCoding.encoder.encode(original)
        #expect(try JSONCoding.decoder.decode([SpotID: Int].self, from: data) == original)
    }

    @Test func sameRawValueInDifferentTagsAreDifferentTypes() {
        // A `PlaceID` cannot be passed where a `HangoutID` is expected. This does not compile:
        //     func open(_ id: HangoutID) {}
        //     open(PlaceID("x"))   // error: cannot convert 'PlaceID' to expected argument type 'HangoutID'
        let place: PlaceID = "x"
        let hangout: HangoutID = "x"
        #expect(place.rawValue == hangout.rawValue)
    }
}
