import Foundation
import Models

public protocol ChatRepository: Sendable {
    func conversations() async throws -> [Conversation]
    /// Unread messages per conversation (messages from others sent after the person last read).
    func unreadCounts() async throws -> [ConversationID: Int]
    /// The conversation's messages, oldest first: the current list first, then a new list after every change
    /// (a message sent, received, edited or deleted). Ends when the caller stops listening.
    func messages(in id: ConversationID) -> AsyncThrowingStream<[Message], any Error>
    func send(_ payload: MessagePayload, in id: ConversationID) async throws -> Message
    func edit(_ id: MessageID, text: String) async throws
    /// The message stays as "[deleted]" (`deletedAt`).
    func delete(_ id: MessageID) async throws
    func markRead(_ id: ConversationID) async throws
    /// One vote per person; voting again changes the choice.
    func vote(_ choice: PollChoice, on message: MessageID) async throws
    func votes(for message: MessageID) async throws -> [PollVote]
    /// Opens the one-to-one chat with a person, creating it if needed.
    func startChat(with user: UserID) async throws -> Conversation
    func createGroup(name: String, members: [UserID]) async throws -> Conversation
    func rename(_ id: ConversationID, to name: String) async throws
    func add(_ members: [UserID], to id: ConversationID) async throws
    func remove(_ member: UserID, from id: ConversationID) async throws
    func leave(_ id: ConversationID) async throws
    /// Everyone in the conversation with their role, who added them and whether they are muted.
    func memberships(in id: ConversationID) async throws -> [Membership]
    /// Admin only. A muted person stays in the group and can read, but sending fails with `AppError.invalid`.
    /// The admin cannot be muted.
    func setMuted(_ muted: Bool, member: UserID, in id: ConversationID) async throws
    /// Groups the person was added to by a non-friend and has not answered yet. They are not in `conversations()`
    /// until accepted.
    func pendingInvitations() async throws -> [Conversation]
    func respondToInvitation(to id: ConversationID, accept: Bool) async throws
}
