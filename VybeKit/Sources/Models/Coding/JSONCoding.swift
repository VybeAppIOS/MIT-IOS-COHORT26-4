import Foundation

/// The one JSON coder for the whole app (ADR 004). LocalData and Remote use only this.
/// Reads ISO 8601 dates with and without fractional seconds (backends emit fractions), writes whole seconds in UTC
/// (`"2026-11-03T10:00:00Z"`), ignores unknown keys and sorts keys so file diffs stay stable.
/// A new coder is returned each time because `JSONDecoder`/`JSONEncoder` are not `Sendable`.
public enum JSONCoding {
    public static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            return try parseDate(text)
        }
        return decoder
    }

    public static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(Date.ISO8601FormatStyle()))
        }
        return encoder
    }

    private static func parseDate(_ text: String) throws -> Date {
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(text) { return date }
        if let date = try? Date.ISO8601FormatStyle().parse(text) { return date }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Not an ISO 8601 date: \(text)"))
    }
}
