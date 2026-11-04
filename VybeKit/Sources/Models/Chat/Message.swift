import Foundation

/// What a message holds. In JSON it is an object with a `kind`, for example `{"kind": "text", "text": "hi"}`.
/// A kind this app version does not know decodes as `.unsupported`, so one new kind never breaks a whole chat.
public enum MessagePayload: Hashable, Sendable {
    case text(String)
    /// Up to 2 (the limit is a rule, not checked here).
    case photos([Photo])
    case hangout(HangoutID)
    case link(URL)
    /// A voice note: a file path and its length in seconds (capped by the voice recorder).
    case voice(path: String, seconds: Int)
    /// Voting happens in group chats only, never inside a Hangout.
    case poll(question: String)
    case unsupported
}

extension MessagePayload: Codable {
    private enum CodingKeys: String, CodingKey { case kind, text, photos, hangoutID, url, path, seconds, question }
    private enum Kind: String { case text, photos, hangout, link, voice, poll }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(String.self, forKey: .kind)
        guard let kind = Kind(rawValue: raw) else {
            self = .unsupported
            return
        }
        switch kind {
        case .text: self = .text(try container.decode(String.self, forKey: .text))
        case .photos: self = .photos(try container.decode([Photo].self, forKey: .photos))
        case .hangout: self = .hangout(try container.decode(HangoutID.self, forKey: .hangoutID))
        case .link: self = .link(try container.decode(URL.self, forKey: .url))
        case .voice:
            self = .voice(path: try container.decode(String.self, forKey: .path),
                          seconds: try container.decode(Int.self, forKey: .seconds))
        case .poll: self = .poll(question: try container.decode(String.self, forKey: .question))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode(Kind.text.rawValue, forKey: .kind)
            try container.encode(text, forKey: .text)
        case .photos(let photos):
            try container.encode(Kind.photos.rawValue, forKey: .kind)
            try container.encode(photos, forKey: .photos)
        case .hangout(let id):
            try container.encode(Kind.hangout.rawValue, forKey: .kind)
            try container.encode(id, forKey: .hangoutID)
        case .link(let url):
            try container.encode(Kind.link.rawValue, forKey: .kind)
            try container.encode(url, forKey: .url)
        case .voice(let path, let seconds):
            try container.encode(Kind.voice.rawValue, forKey: .kind)
            try container.encode(path, forKey: .path)
            try container.encode(seconds, forKey: .seconds)
        case .poll(let question):
            try container.encode(Kind.poll.rawValue, forKey: .kind)
            try container.encode(question, forKey: .question)
        case .unsupported:
            try container.encode("unsupported", forKey: .kind)
        }
    }
}

public struct Message: Codable, Hashable, Sendable, Identifiable {
    public let id: MessageID
    public var conversationID: ConversationID
    public var senderID: UserID
    /// Set by the server.
    public var createdAt: Date
    public var editedAt: Date?
    /// Deleted messages show as "[deleted]".
    public var deletedAt: Date?
    public var payload: MessagePayload

    public init(
        id: MessageID, conversationID: ConversationID, senderID: UserID, createdAt: Date, editedAt: Date? = nil,
        deletedAt: Date? = nil, payload: MessagePayload
    ) {
        self.id = id
        self.conversationID = conversationID
        self.senderID = senderID
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.deletedAt = deletedAt
        self.payload = payload
    }
}

/// The two fixed answers to a poll.
public enum PollChoice: String, Codable, Hashable, Sendable, CaseIterable {
    case imIn = "im-in"
    case notForMe = "not-for-me"
}

/// One vote on a poll message. One per person.
public struct PollVote: Codable, Hashable, Sendable {
    public var messageID: MessageID
    public var userID: UserID
    public var choice: PollChoice
    public var votedAt: Date

    public init(messageID: MessageID, userID: UserID, choice: PollChoice, votedAt: Date) {
        self.messageID = messageID
        self.userID = userID
        self.choice = choice
        self.votedAt = votedAt
    }
}
