import Foundation

public extension ID where Tag == IDTag.Conversation {
    /// The ID of the one-to-one chat between two people: `dm_<idA>_<idB>` with the IDs sorted, so both people
    /// always get the same chat.
    static func dm(_ first: UserID, _ second: UserID) -> ConversationID {
        let sorted = [first.rawValue, second.rawValue].sorted()
        return ConversationID("dm_\(sorted[0])_\(sorted[1])")
    }
}

public enum ConversationKind: String, Codable, Hashable, Sendable {
    /// A one-to-one chat. Its JSON word is `"dm"`.
    case directMessage = "dm"
    case group
}

/// The newest message, copied onto the conversation so the Chats list needs no second load.
public struct LastMessagePreview: Codable, Hashable, Sendable {
    public var senderID: UserID
    /// Plain text a list row can show (for a photo or a poll, a short label).
    public var text: String
    public var sentAt: Date

    public init(senderID: UserID, text: String, sentAt: Date) {
        self.senderID = senderID
        self.text = text
        self.sentAt = sentAt
    }
}

public struct Conversation: Codable, Hashable, Sendable, Identifiable {
    public let id: ConversationID
    public var kind: ConversationKind
    /// Groups only.
    public var name: String?
    public var photo: Photo?
    /// Groups only. The oldest member becomes admin if the admin leaves.
    public var adminID: UserID?
    public var memberIDs: [UserID]
    public var lastMessage: LastMessagePreview?
    public var createdAt: Date

    public init(
        id: ConversationID, kind: ConversationKind, name: String? = nil, photo: Photo? = nil, adminID: UserID? = nil,
        memberIDs: [UserID], lastMessage: LastMessagePreview? = nil, createdAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.photo = photo
        self.adminID = adminID
        self.memberIDs = memberIDs
        self.lastMessage = lastMessage
        self.createdAt = createdAt
    }
}

public enum MembershipRole: String, Codable, Hashable, Sendable {
    case admin
    case member
}

public enum MembershipStatus: String, Codable, Hashable, Sendable {
    /// Added by someone who is not a friend: waits until the person accepts.
    case pending
    case active
}

public struct Membership: Codable, Hashable, Sendable {
    public var conversationID: ConversationID
    public var userID: UserID
    public var role: MembershipRole
    public var status: MembershipStatus
    /// Messages sent before this are hidden from the new member.
    public var joinedAt: Date
    /// "Seen" is every member whose `lastReadAt` is after the message.
    public var lastReadAt: Date?
    /// Set when the admin muted this person: they stay in the group and can read, but cannot send.
    public var mutedAt: Date?
    /// Who added this person to the group (the name an invitation shows).
    public var addedByID: UserID?

    public init(
        conversationID: ConversationID, userID: UserID, role: MembershipRole = .member,
        status: MembershipStatus = .active, joinedAt: Date, lastReadAt: Date? = nil, mutedAt: Date? = nil,
        addedByID: UserID? = nil
    ) {
        self.conversationID = conversationID
        self.userID = userID
        self.role = role
        self.status = status
        self.joinedAt = joinedAt
        self.lastReadAt = lastReadAt
        self.mutedAt = mutedAt
        self.addedByID = addedByID
    }
}
