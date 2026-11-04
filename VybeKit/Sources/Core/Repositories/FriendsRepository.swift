import Foundation
import Models

public struct FriendRequests: Hashable, Sendable {
    /// Sent to me by people I may know.
    public var received: [FriendRequest]
    public var sent: [FriendRequest]
    /// Sent to me by people with no mutual friends: shown in a separate "Other" folder.
    public var other: [FriendRequest]

    public init(received: [FriendRequest] = [], sent: [FriendRequest] = [], other: [FriendRequest] = []) {
        self.received = received
        self.sent = sent
        self.other = other
    }
}

public protocol FriendsRepository: Sendable {
    func friends() async throws -> [UserProfile]
    func requests() async throws -> FriendRequests
    /// "You might know": never me, never someone I am already friends with or blocked.
    func suggestions() async throws -> [UserProfile]
    func mutualFriends(with user: UserID) async throws -> [UserProfile]
    func sendRequest(to user: UserID) async throws -> FriendRequest
    /// Accepting deletes the request and creates the friendship.
    func acceptRequest(from user: UserID) async throws
    func cancelRequest(to user: UserID) async throws
    func removeFriend(_ user: UserID) async throws
}
