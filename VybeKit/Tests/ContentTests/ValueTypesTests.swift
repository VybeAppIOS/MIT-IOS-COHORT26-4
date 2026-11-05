import Foundation
import Testing
@testable import Models

struct ValueTypesTests {
    @Test func coordinateAndPhotoRoundTrip() throws {
        let photo = Photo(id: "ph1", path: "Photos/a.jpg", width: 1200, height: 800, credit: "Own photo", spotID: "s1")
        let data = try JSONCoding.encoder.encode(photo)
        #expect(try JSONCoding.decoder.decode(Photo.self, from: data) == photo)
        let point = Coordinate(latitude: 18.5074, longitude: 73.8077)
        #expect(try JSONCoding.decoder.decode(Coordinate.self, from: JSONCoding.encoder.encode(point)) == point)
    }

    @Test func photoOptionalsMayBeMissing() throws {
        let json = #"{"id":"ph1","path":"a.jpg","width":10,"height":20}"#
        let photo = try JSONCoding.decoder.decode(Photo.self, from: Data(json.utf8))
        #expect(photo.credit == nil && photo.spotID == nil)
    }

    @Test(arguments: [
        ReportTarget.run("r1"), .comment("c1"), .user("u1"), .message("m1"), .place("p1"), .hangout("h1")
    ])
    func reportTargetRoundTrips(target: ReportTarget) throws {
        let data = try JSONCoding.encoder.encode(target)
        #expect(try JSONCoding.decoder.decode(ReportTarget.self, from: data) == target)
    }

    @Test func reportTargetJSONShapeIsKindAndID() throws {
        let data = try JSONCoding.encoder.encode(ReportTarget.comment("c1"))
        #expect(String(bytes: data, encoding: .utf8) == #"{"id":"c1","kind":"comment"}"#)
    }

    @Test func reportTargetRejectsUnknownKind() {
        #expect(throws: DecodingError.self) {
            try JSONCoding.decoder.decode(ReportTarget.self, from: Data(#"{"kind":"banana","id":"x"}"#.utf8))
        }
    }
}
