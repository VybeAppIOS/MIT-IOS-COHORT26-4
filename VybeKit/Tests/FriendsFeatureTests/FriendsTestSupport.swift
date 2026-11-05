import Core
import Foundation
import Models
import Synchronization

/// A friends repository whose lists the test sets, with a switch to make changes fail.
final class FakeFriends: FriendsRepository {
    struct State {
        var friends: [UserProfile] = []
        var received: [FriendRequest] = []
        var sent: [FriendRequest] = []
        var other: [FriendRequest] = []
        var suggestions: [UserProfile] = []
        var mutual: [UserID: [UserProfile]] = [:]
    }

    let state: Mutex<State>
    let failChanges = Mutex(false)
    let calls = Mutex<[String]>([])

    init(_ state: State) { self.state = Mutex(state) }

    private func record(_ call: String) throws {
        calls.withLock { $0.append(call) }
        if failChanges.withLock({ $0 }) { throw AppError.offline }
    }

    func friends() async throws -> [UserProfile] { state.withLock { $0.friends } }
    func requests() async throws -> FriendRequests {
        state.withLock { FriendRequests(received: $0.received, sent: $0.sent, other: $0.other) }
    }
    func suggestions() async throws -> [UserProfile] { state.withLock { $0.suggestions } }
    func mutualFriends(with user: UserID) async throws -> [UserProfile] { state.withLock { $0.mutual[user] ?? [] } }

    func sendRequest(to user: UserID) async throws -> FriendRequest {
        try record("send \(user.rawValue)")
        let request = FriendRequest(
            fromID: SampleData.signedInUser.id, toID: user, createdAt: SampleData.day)
        state.withLock { $0.sent.append(request) }
        return request
    }
    func acceptRequest(from user: UserID) async throws {
        try record("accept \(user.rawValue)")
        state.withLock { state in
            state.received.removeAll { $0.fromID == user }
            state.other.removeAll { $0.fromID == user }
            if let person = SampleSocialData.people.first(where: { $0.id == user }) { state.friends.append(person) }
        }
    }
    func cancelRequest(to user: UserID) async throws {
        try record("cancel \(user.rawValue)")
        state.withLock { $0.sent.removeAll { $0.toID == user } }
    }
    func removeFriend(_ user: UserID) async throws {
        try record("remove \(user.rawValue)")
        state.withLock { $0.friends.removeAll { $0.id == user } }
    }
}

extension FakeFriends {
    /// Three friends, one request to answer, one "Other" request, one sent request and one suggestion with two
    /// mutual friends.
    static func standard() -> FakeFriends {
        let myID = SampleData.signedInUser.id
        var state = State()
        state.friends = [SampleSocialData.rohan, SampleSocialData.aarav, SampleSocialData.isha]
        state.received = [FriendRequest(fromID: SampleSocialData.sanya.id, toID: myID, createdAt: SampleData.day)]
        state.other = [
            FriendRequest(fromID: SampleSocialData.tara.id, toID: myID, createdAt: SampleData.day, isOther: true)
        ]
        state.sent = [FriendRequest(fromID: myID, toID: SampleSocialData.neel.id, createdAt: SampleData.day)]
        state.suggestions = [SampleSocialData.vihaan]
        state.mutual = [SampleSocialData.vihaan.id: [SampleSocialData.aarav, SampleSocialData.isha]]
        return FakeFriends(state)
    }
}
