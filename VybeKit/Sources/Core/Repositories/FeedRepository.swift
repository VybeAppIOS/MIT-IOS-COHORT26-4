import Foundation
import Models

/// Posts, comments, likes and the Activity list. Shaped so both backends can implement it: cursor paging with `Page`
/// (no offsets), no joins, and blocking is applied by the repository (a blocked person's posts and comments are
/// never returned). Errors are `AppError`s; a missing ID is `.notFound`.
public protocol FeedRepository: Sendable {
    /// Posted runs: friends first, then newest. Pass the previous page's `nextCursor` for the next page.
    func feed(after cursor: String?) async throws -> Page<HangoutRun>
    func trending() async throws -> [HangoutRun]
    func post(id: RunID) async throws -> HangoutRun
    /// Threaded through `Comment.parentID`; a reply always comes after its parent.
    func comments(for runID: RunID, after cursor: String?) async throws -> Page<Comment>
    /// What the current person has liked.
    func likes() async throws -> Set<LikeTarget>
    /// Liking twice changes nothing.
    func like(_ target: LikeTarget) async throws
    func unlike(_ target: LikeTarget) async throws
    func addComment(to runID: RunID, text: String, replyingTo parentID: CommentID?) async throws -> Comment
    /// Deleted comments stay in the thread as "[deleted]" (`deletedAt`).
    func deleteComment(_ id: CommentID) async throws
    func activity(after cursor: String?) async throws -> Page<Activity>
    func markActivityRead() async throws
}
