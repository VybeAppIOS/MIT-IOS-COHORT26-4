import Core
import Foundation
import Models
import Synchronization

/// The sample chat repository with switches a test can flip, and a record of what was sent. Anything not switched
/// behaves like the stub.
final class ControlledChat: ChatRepository {
    let base: any ChatRepository
    let failSend = Mutex(false)
    let failChanges = Mutex(false)
    let sent = Mutex<[(ConversationID, MessagePayload)]>([])
    /// When set, every group looks as if this person is its admin.
    let adminOverride = Mutex<UserID?>(nil)
    /// When set, `messages(in:)` returns exactly these messages (and finishes).
    let fixedMessages: Mutex<[Message]?>

    init(base: any ChatRepository, messages: [Message]? = nil) {
        self.base = base
        self.fixedMessages = Mutex(messages)
    }

    func conversations() async throws -> [Conversation] {
        let list = try await base.conversations()
        guard let admin = adminOverride.withLock({ $0 }) else { return list }
        return list.map { conversation in
            var changed = conversation
            if conversation.kind == .group { changed.adminID = admin }
            return changed
        }
    }
    func unreadCounts() async throws -> [ConversationID: Int] { try await base.unreadCounts() }
    func messages(in id: ConversationID) -> AsyncThrowingStream<[Message], any Error> {
        if let fixed = fixedMessages.withLock({ $0 }) {
            return AsyncThrowingStream { continuation in
                continuation.yield(fixed)
                continuation.finish()
            }
        }
        return base.messages(in: id)
    }
    func send(_ payload: MessagePayload, in id: ConversationID) async throws -> Message {
        if failSend.withLock({ $0 }) { throw AppError.offline }
        sent.withLock { $0.append((id, payload)) }
        return try await base.send(payload, in: id)
    }
    func edit(_ id: MessageID, text: String) async throws {
        if failChanges.withLock({ $0 }) { throw AppError.offline }
        try await base.edit(id, text: text)
    }
    func delete(_ id: MessageID) async throws {
        if failChanges.withLock({ $0 }) { throw AppError.offline }
        try await base.delete(id)
    }
    func markRead(_ id: ConversationID) async throws { try await base.markRead(id) }
    func vote(_ choice: PollChoice, on message: MessageID) async throws { try await base.vote(choice, on: message) }
    func votes(for message: MessageID) async throws -> [PollVote] { try await base.votes(for: message) }
    func startChat(with user: UserID) async throws -> Conversation { try await base.startChat(with: user) }
    func createGroup(name: String, members: [UserID]) async throws -> Conversation {
        if failChanges.withLock({ $0 }) { throw AppError.offline }
        return try await base.createGroup(name: name, members: members)
    }
    func rename(_ id: ConversationID, to name: String) async throws {
        if failChanges.withLock({ $0 }) { throw AppError.offline }
        try await base.rename(id, to: name)
    }
    func add(_ members: [UserID], to id: ConversationID) async throws { try await base.add(members, to: id) }
    func remove(_ member: UserID, from id: ConversationID) async throws { try await base.remove(member, from: id) }
    func leave(_ id: ConversationID) async throws { try await base.leave(id) }
    func respondToInvitation(to id: ConversationID, accept: Bool) async throws {
        try await base.respondToInvitation(to: id, accept: accept)
    }
    func memberships(in id: ConversationID) async throws -> [Membership] { try await base.memberships(in: id) }
    func setMuted(_ muted: Bool, member: UserID, in id: ConversationID) async throws {
        if failChanges.withLock({ $0 }) { throw AppError.offline }
        try await base.setMuted(muted, member: member, in: id)
    }
    func pendingInvitations() async throws -> [Conversation] { try await base.pendingInvitations() }
}
