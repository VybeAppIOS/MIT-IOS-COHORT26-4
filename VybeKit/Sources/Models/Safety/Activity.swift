import Foundation

public extension IDTag {
    enum Activity {}
}

public typealias ActivityID = ID<IDTag.Activity>

public enum ActivityKind: String, Codable, Hashable, Sendable, CaseIterable {
    case like
    case comment
    case reply
    case friendRequest = "friend-request"
    case friendAccepted = "friend-accepted"
    case remixCredit = "remix-credit"
    /// Any kind this app version does not know.
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ActivityKind(rawValue: raw) ?? .unknown
    }
}

/// What an activity row opens. IDs only. In JSON: `{"kind": "run", "id": "..."}`.
public enum ActivityTarget: Hashable, Sendable {
    case run(RunID)
    case comment(CommentID)
    case user(UserID)
    case hangout(HangoutID)
}

extension ActivityTarget: Codable {
    private enum CodingKeys: String, CodingKey { case kind, id }
    private enum Kind: String, Codable { case run, comment, user, hangout }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .run: self = .run(RunID(id))
        case .comment: self = .comment(CommentID(id))
        case .user: self = .user(UserID(id))
        case .hangout: self = .hangout(HangoutID(id))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .run(let id): try write(.run, id.rawValue, &container)
        case .comment(let id): try write(.comment, id.rawValue, &container)
        case .user(let id): try write(.user, id.rawValue, &container)
        case .hangout(let id): try write(.hangout, id.rawValue, &container)
        }
    }

    private func write(_ kind: Kind, _ id: String, _ container: inout KeyedEncodingContainer<CodingKeys>) throws {
        try container.encode(kind, forKey: .kind)
        try container.encode(id, forKey: .id)
    }
}

/// One row of the Activity screen (CM5). Written by the server; only the recipient reads it.
public struct Activity: Codable, Hashable, Sendable, Identifiable {
    public let id: ActivityID
    public var recipientID: UserID
    public var kind: ActivityKind
    public var actorID: UserID
    public var target: ActivityTarget
    public var createdAt: Date
    public var readAt: Date?

    public init(
        id: ActivityID, recipientID: UserID, kind: ActivityKind, actorID: UserID, target: ActivityTarget,
        createdAt: Date, readAt: Date? = nil
    ) {
        self.id = id
        self.recipientID = recipientID
        self.kind = kind
        self.actorID = actorID
        self.target = target
        self.createdAt = createdAt
        self.readAt = readAt
    }
}
