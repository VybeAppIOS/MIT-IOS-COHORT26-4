import Components
import Core
import Foundation
import Models

extension ConversationViewModel {
    // MARK: Read receipts

    /// Who is in the chat and when they last read it. This tells me whether the admin has muted me in this group and
    /// whether anyone has seen my last message. A failed lookup keeps what was known before (so nothing flips to
    /// muted or seen by mistake); a muted person's message is still refused by the repository, with a notice.
    func loadMemberships(in conversation: Conversation) async {
        memberships = (try? await chat.memberships(in: conversationID)) ?? memberships
        guard conversation.kind == .group, let myID = session.currentUser?.id else {
            isMuted = false
            return
        }
        isMuted = memberships.first { $0.userID == myID }?.mutedAt != nil
    }

    /// The latest time any other active member (not someone I blocked) read this chat.
    func othersLastReadAt(myID: UserID?) -> Date? {
        memberships
            .filter { $0.userID != myID && $0.status == .active && !session.isBlocked($0.userID) }
            .compactMap(\.lastReadAt)
            .max()
    }

    /// "Seen" when someone else has read up to this message, otherwise "Delivered". Read receipts are always on.
    /// `othersLastReadAt` is the newest read time among the other members (nil when nobody has read the chat).
    static func receipt(for message: Message, othersLastReadAt: Date?) -> MessageRowData.Receipt {
        if let readAt = othersLastReadAt, readAt >= message.createdAt { return .seen }
        return .delivered
    }
}
