import Foundation

/// What a Report is about. IDs only. In JSON: `{"kind": "comment", "id": "c1"}` (same style as `MessagePayload`).
public enum ReportTarget: Hashable, Sendable {
    case run(RunID)
    case comment(CommentID)
    case user(UserID)
    case message(MessageID)
    case place(PlaceID)
}

extension ReportTarget: Codable {
    private enum CodingKeys: String, CodingKey { case kind, id }
    private enum Kind: String, Codable { case run, comment, user, message, place }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        let id = try container.decode(String.self, forKey: .id)
        switch kind {
        case .run: self = .run(RunID(id))
        case .comment: self = .comment(CommentID(id))
        case .user: self = .user(UserID(id))
        case .message: self = .message(MessageID(id))
        case .place: self = .place(PlaceID(id))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .run(let id): try encode(.run, id.rawValue, into: &container)
        case .comment(let id): try encode(.comment, id.rawValue, into: &container)
        case .user(let id): try encode(.user, id.rawValue, into: &container)
        case .message(let id): try encode(.message, id.rawValue, into: &container)
        case .place(let id): try encode(.place, id.rawValue, into: &container)
        }
    }

    private func encode(_ kind: Kind, _ id: String, into container: inout KeyedEncodingContainer<CodingKeys>) throws {
        try container.encode(kind, forKey: .kind)
        try container.encode(id, forKey: .id)
    }
}
