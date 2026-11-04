import Foundation
import Testing
@testable import Models

struct JSONCodingTests {
    private struct Stamp: Codable, Equatable { var value: Date }

    private func decode(_ json: String) throws -> Stamp {
        try JSONCoding.decoder.decode(Stamp.self, from: Data(json.utf8))
    }

    @Test func decodesDateWithoutFractionalSeconds() throws {
        #expect(try decode(#"{"value":"2026-11-03T10:00:00Z"}"#).value == Date(timeIntervalSince1970: 1_793_700_000))
    }

    @Test func decodesDateWithFractionalSeconds() throws {
        let date = try decode(#"{"value":"2026-11-03T10:00:00.250Z"}"#).value
        #expect(abs(date.timeIntervalSince1970 - 1_793_700_000.25) < 0.001)
    }

    @Test func rejectsNonDate() {
        #expect(throws: DecodingError.self) { try decode(#"{"value":"yesterday"}"#) }
    }

    @Test func encodesWholeSecondsInUTC() throws {
        let data = try JSONCoding.encoder.encode(Stamp(value: Date(timeIntervalSince1970: 1_793_700_000)))
        #expect(String(bytes: data, encoding: .utf8) == #"{"value":"2026-11-03T10:00:00Z"}"#)
    }

    @Test func ignoresUnknownKeys() throws {
        let stamp = try decode(#"{"value":"2026-11-03T10:00:00Z","newField":42}"#)
        #expect(stamp.value == Date(timeIntervalSince1970: 1_793_700_000))
    }

    @Test func sortsKeys() throws {
        let data = try JSONCoding.encoder.encode(["b": 2, "a": 1])
        #expect(String(bytes: data, encoding: .utf8) == #"{"a":1,"b":2}"#)
    }
}
