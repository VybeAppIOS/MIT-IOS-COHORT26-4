import Foundation

/// Marker types for `ID`. They are never created: they only make `PlaceID` and `HangoutID` different types,
/// so passing one where the other is expected does not compile.
public enum IDTag {
    public enum Place {}
    public enum Hangout {}
    public enum Spot {}
    public enum Run {}
    public enum Photo {}
    public enum User {}
    public enum Comment {}
    public enum Conversation {}
    public enum Message {}
    public enum Report {}
}

// The name `ID` is fixed by every doc and task (`ID<Tag>`) but the type_name rule wants 3+ letters;
// the exemption on the struct line below was approved by Lohitaksh.
/// A typed ID. In JSON it is a plain string (also when used as a dictionary key, see `CodingKeyRepresentable`).
/// IDs never change once set (`docs/DATA-MODEL.md` 2).
public struct ID<Tag>: Hashable, Sendable, Codable, // swiftlint:disable:this type_name
                       ExpressibleByStringLiteral, CustomStringConvertible, CodingKeyRepresentable {
    public let rawValue: String

    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { rawValue = value }

    public init(from decoder: any Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String { rawValue }

    // Without these two, Swift writes a `[SpotID: Date]` as a flat array `[key, value, key, value]` (ADR 004).
    public var codingKey: any CodingKey { rawValue.codingKey }

    public init?<T: CodingKey>(codingKey: T) { self.init(codingKey.stringValue) }
}

public typealias PlaceID = ID<IDTag.Place>
public typealias HangoutID = ID<IDTag.Hangout>
public typealias SpotID = ID<IDTag.Spot>
public typealias RunID = ID<IDTag.Run>
public typealias PhotoID = ID<IDTag.Photo>
public typealias UserID = ID<IDTag.User>
public typealias CommentID = ID<IDTag.Comment>
public typealias ConversationID = ID<IDTag.Conversation>
public typealias MessageID = ID<IDTag.Message>
public typealias ReportID = ID<IDTag.Report>
