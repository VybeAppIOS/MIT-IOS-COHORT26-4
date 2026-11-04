import Foundation

/// A comment on a post (a run). Threaded through `parentID`. Deleted comments show as "[deleted]" (`deletedAt`).
public struct Comment: Codable, Hashable, Sendable, Identifiable {
    public let id: CommentID
    public var runID: RunID
    public var authorID: UserID
    public var parentID: CommentID?
    public var text: String
    public var likeCount: Int
    public var createdAt: Date
    public var editedAt: Date?
    public var deletedAt: Date?

    public init(
        id: CommentID, runID: RunID, authorID: UserID, parentID: CommentID? = nil, text: String, likeCount: Int = 0,
        createdAt: Date, editedAt: Date? = nil, deletedAt: Date? = nil
    ) {
        self.id = id
        self.runID = runID
        self.authorID = authorID
        self.parentID = parentID
        self.text = text
        self.likeCount = likeCount
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.deletedAt = deletedAt
    }
}

/// What a like is on. In JSON: `{"kind": "run", "id": "..."}`.
public enum LikeTarget: Hashable, Sendable {
    case run(RunID)
    case comment(CommentID)
}

extension LikeTarget: Codable {
    private enum CodingKeys: String, CodingKey { case kind, id }
    private enum Kind: String, Codable { case run, comment }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .run: self = .run(RunID(id))
        case .comment: self = .comment(CommentID(id))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .run(let id):
            try container.encode(Kind.run, forKey: .kind)
            try container.encode(id.rawValue, forKey: .id)
        case .comment(let id):
            try container.encode(Kind.comment, forKey: .kind)
            try container.encode(id.rawValue, forKey: .id)
        }
    }
}

/// One person's like. One per person per target.
public struct Like: Codable, Hashable, Sendable {
    public var userID: UserID
    public var target: LikeTarget
    public var createdAt: Date

    public init(userID: UserID, target: LikeTarget, createdAt: Date) {
        self.userID = userID
        self.target = target
        self.createdAt = createdAt
    }
}
