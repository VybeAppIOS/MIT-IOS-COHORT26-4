import Foundation

/// A friend request. Accept = delete it and create a `Friendship`. Ignore = it stays (never shows "declined").
public struct FriendRequest: Codable, Hashable, Sendable, Identifiable {
    public var fromID: UserID
    public var toID: UserID
    public var createdAt: Date
    /// No mutual friends: shown in the separate "Other" folder.
    public var isOther: Bool

    public init(fromID: UserID, toID: UserID, createdAt: Date, isOther: Bool = false) {
        self.fromID = fromID
        self.toID = toID
        self.createdAt = createdAt
        self.isOther = isOther
    }

    /// `"<from>_<to>"`, so there is at most one request per direction.
    public var id: String { "\(fromID.rawValue)_\(toID.rawValue)" }

    private enum CodingKeys: String, CodingKey { case fromID, toID, createdAt, isOther }
}

/// Two people who are friends. Stored with the two IDs in sorted order, so (A, B) and (B, A) are the same record.
public struct Friendship: Codable, Hashable, Sendable {
    public let userA: UserID
    public let userB: UserID
    public var createdAt: Date

    public init(_ first: UserID, _ second: UserID, createdAt: Date) {
        let sorted = [first, second].sorted { $0.rawValue < $1.rawValue }
        userA = sorted[0]
        userB = sorted[1]
        self.createdAt = createdAt
    }

    public func contains(_ user: UserID) -> Bool { user == userA || user == userB }
}

/// One person blocking another. Only the blocker reads it.
public struct Block: Codable, Hashable, Sendable {
    public var blockerID: UserID
    public var blockedID: UserID
    public var createdAt: Date

    public init(blockerID: UserID, blockedID: UserID, createdAt: Date) {
        self.blockerID = blockerID
        self.blockedID = blockedID
        self.createdAt = createdAt
    }
}
