#if DEBUG
import Foundation
import Models

// The promises every social repository keeps (the stubs now, Remote later). Run each on a FRESH repository: they
// change data (like, send, block) and do not undo everything.

public enum FeedRepositoryContract {
    public static func verify(_ repository: any FeedRepository) async throws {
        // Paging follows cursors, ends, and never repeats a post.
        var seen: [RunID] = []
        var cursor: String?
        for _ in 0..<50 {
            let page = try await repository.feed(after: cursor)
            seen += page.items.map(\.id)
            cursor = page.nextCursor
            if cursor == nil { break }
        }
        try require(cursor == nil, "feed paging never ended")
        try require(Set(seen).count == seen.count, "feed repeated a post")
        for id in seen.prefix(3) {
            let post = try await repository.post(id: id)
            try require(post.state == .posted, "post \(id) is not posted")
        }
        try await requireNotFound("post(id:) with an unknown ID") {
            _ = try await repository.post(id: "contract-missing")
        }

        guard let runID = seen.first else { return }
        let comments = try await allComments(repository, runID)
        let ids = Set(comments.map(\.id))
        for (index, comment) in comments.enumerated() {
            guard let parent = comment.parentID else { continue }
            try require(ids.contains(parent), "reply \(comment.id) has no parent in the list")
            try require(comments.firstIndex { $0.id == parent }! < index, "reply \(comment.id) comes before its parent")
        }

        // Liking twice counts once; unliking undoes it.
        let before = try await repository.post(id: runID).likeCount
        let wasLiked = try await repository.likes().contains(.run(runID))
        try await repository.like(.run(runID))
        try await repository.like(.run(runID))
        let liked = try await repository.post(id: runID).likeCount
        try require(liked == (wasLiked ? before : before + 1), "liking twice must count once")
        try require(try await repository.likes().contains(.run(runID)), "likes() misses a like")
        try await repository.unlike(.run(runID))
        try require(try await repository.likes().contains(.run(runID)) == false, "unlike did not remove the like")

        // Comments: empty is refused, a real one is added once and can be deleted.
        try await requireInvalid { _ = try await repository.addComment(to: runID, text: "   ", replyingTo: nil) }
        let added = try await repository.addComment(to: runID, text: "EXAMPLE contract comment", replyingTo: nil)
        try require(try await allComments(repository, runID).contains { $0.id == added.id }, "added comment missing")
        try await repository.deleteComment(added.id)
        let gone = try await allComments(repository, runID).first { $0.id == added.id }
        try require(gone?.deletedAt != nil, "deleted comment must stay with deletedAt set")

        try await repository.markActivityRead()
        try require(try await repository.activity(after: nil).items.allSatisfy { $0.readAt != nil },
                    "markActivityRead left unread items")
    }

    private static func allComments(_ repository: any FeedRepository, _ runID: RunID) async throws -> [Comment] {
        var all: [Comment] = []
        var cursor: String?
        for _ in 0..<50 {
            let page = try await repository.comments(for: runID, after: cursor)
            all += page.items
            cursor = page.nextCursor
            if cursor == nil { break }
        }
        return all
    }
}

public enum FriendsRepositoryContract {
    public static func verify(_ repository: any FriendsRepository, myID: UserID) async throws {
        let friends = try await repository.friends()
        let friendIDs = Set(friends.map(\.id))
        for person in try await repository.suggestions() {
            try require(person.id != myID && !friendIDs.contains(person.id), "suggestions() offered \(person.id)")
        }
        try await requireInvalid { _ = try await repository.sendRequest(to: myID) }
        for friend in friends.prefix(1) {
            try await requireInvalid { _ = try await repository.sendRequest(to: friend.id) }
            try require(try await repository.mutualFriends(with: friend.id).allSatisfy { friendIDs.contains($0.id) },
                        "mutual friends must be my friends")
        }
        if let stranger = try await repository.suggestions().first {
            let first = try await repository.sendRequest(to: stranger.id)
            let second = try await repository.sendRequest(to: stranger.id)
            try require(first == second, "sending twice must not make two requests")
            let requested = try await repository.requests().sent.contains { $0.toID == stranger.id }
            try require(requested, "sent request missing")
            try await repository.cancelRequest(to: stranger.id)
            let stillThere = try await repository.requests().sent.contains { $0.toID == stranger.id }
            try require(!stillThere, "cancel failed")
            try await requireNotFound("cancelRequest with none") { try await repository.cancelRequest(to: stranger.id) }
        }
        if let incoming = try await repository.requests().received.first {
            try await repository.acceptRequest(from: incoming.fromID)
            try require(try await repository.friends().contains { $0.id == incoming.fromID }, "accepted friend missing")
            try require(try await repository.requests().received.contains { $0.fromID == incoming.fromID } == false,
                        "accepted request must be removed")
        }
        try await requireNotFound("removeFriend of a stranger") {
            try await repository.removeFriend("contract-missing")
        }
    }
}

public enum ChatRepositoryContract {
    public static func verify(_ repository: any ChatRepository, myID: UserID) async throws {
        let conversations = try await repository.conversations()
        let unread = try await repository.unreadCounts()
        let known = Set(conversations.map(\.id))
        try require(unread.keys.allSatisfy(known.contains), "unread for a missing chat")
        guard let chat = conversations.first else { return }

        let sent = try await repository.send(.text("EXAMPLE contract message"), in: chat.id)
        let latest = try await firstList(repository, chat.id)
        try require(latest.last?.id == sent.id, "the sent message must be the newest")
        try await requireInvalid { _ = try await repository.send(.text("  "), in: chat.id) }

        try await repository.edit(sent.id, text: "EXAMPLE edited")
        try require(try await firstList(repository, chat.id).last?.editedAt != nil, "edit must set editedAt")
        try await repository.delete(sent.id)
        try require(try await firstList(repository, chat.id).last?.deletedAt != nil, "delete must set deletedAt")

        try await repository.markRead(chat.id)
        try require(try await repository.unreadCounts()[chat.id] == 0, "markRead must clear the unread count")
        try await requireNotFound("send to an unknown chat") {
            _ = try await repository.send(.text("x"), in: "contract-missing")
        }

        try await requireInvalid { _ = try await repository.createGroup(name: "EXAMPLE", members: []) }
    }

    private static func firstList(_ repository: any ChatRepository, _ id: ConversationID) async throws -> [Message] {
        for try await list in repository.messages(in: id) { return list }
        throw ContractFailure("messages(in:) ended without a list")
    }
}

public enum SafetyRepositoryContract {
    public static func verify(_ repository: any SafetyRepository, reporter: UserID, victim: UserID) async throws {
        let filed = try await repository.report(.user(victim), reason: .other, detail: "EXAMPLE")
        try require(filed.status == .open && filed.reporterID == reporter && filed.reason == .other,
                    "a new report must be open and from the reporter")
        try await repository.block(victim)
        try require(try await repository.blocked().contains { $0.id == victim }, "blocked() misses the person")
        try await requireInvalid { try await repository.block(reporter) }
        try await repository.unblock(victim)
        try require(try await repository.blocked().contains { $0.id == victim } == false, "unblock failed")
    }
}
#endif
