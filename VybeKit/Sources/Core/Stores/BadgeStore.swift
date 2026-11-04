import Foundation
import Models
import Observation

/// The numbers on the Community tab and the bell: unread chats, unseen Activity and waiting friend requests.
/// Shared by every tab. A failed refresh keeps the last numbers (a badge never blanks because of one bad load).
@MainActor @Observable
public final class BadgeStore {
    public private(set) var unreadChatCount = 0
    public private(set) var unseenActivityCount = 0
    public private(set) var pendingRequestCount = 0

    private let chat: any ChatRepository
    private let feed: any FeedRepository
    private let friends: any FriendsRepository

    public init(chat: any ChatRepository, feed: any FeedRepository, friends: any FriendsRepository) {
        self.chat = chat
        self.feed = feed
        self.friends = friends
    }

    /// The number on the Community tab.
    public var communityBadge: Int { unreadChatCount + unseenActivityCount + pendingRequestCount }

    /// Reloads all three counts. Each one that fails keeps its previous value.
    public func refresh() async {
        if let counts = try? await chat.unreadCounts() {
            unreadChatCount = counts.values.reduce(0, +)
        }
        if let page = try? await feed.activity(after: nil) {
            unseenActivityCount = page.items.filter { $0.readAt == nil }.count
        }
        if let requests = try? await friends.requests() {
            pendingRequestCount = requests.received.count   // "Other" requests do not make a badge
        }
    }

    /// The person opened Activity.
    public func activityWasSeen() { unseenActivityCount = 0 }

    /// The person opened a chat.
    public func chatWasRead(unread: Int) { unreadChatCount = max(0, unreadChatCount - unread) }
}
