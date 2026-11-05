import Components
import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import CommunityFeature

/// The sample feed with switches a test can flip: saving fails, likes fail, someone else owns the post, or the
/// comments come in fixed pages.
private final class ControlledFeed: FeedRepository {
    let base: any FeedRepository
    let failAdd = Mutex(false)
    let failLike = Mutex(false)
    let owner: UserID?
    let pages: [String?: Page<Models.Comment>]?

    init(base: any FeedRepository, owner: UserID? = nil, pages: [String?: Page<Models.Comment>]? = nil) {
        self.base = base
        self.owner = owner
        self.pages = pages
    }

    func feed(after cursor: String?) async throws -> Page<HangoutRun> { try await base.feed(after: cursor) }
    func trending() async throws -> [HangoutRun] { try await base.trending() }
    func post(id: RunID) async throws -> HangoutRun {
        var run = try await base.post(id: id)
        if let owner { run.runnerID = owner }
        return run
    }
    func comments(for runID: RunID, after cursor: String?) async throws -> Page<Models.Comment> {
        if let pages { return pages[cursor] ?? Page(items: []) }
        return try await base.comments(for: runID, after: cursor)
    }
    func likes() async throws -> Set<LikeTarget> { try await base.likes() }
    func like(_ target: LikeTarget) async throws {
        if failLike.withLock({ $0 }) { throw AppError.offline }
        try await base.like(target)
    }
    func unlike(_ target: LikeTarget) async throws {
        if failLike.withLock({ $0 }) { throw AppError.offline }
        try await base.unlike(target)
    }
    func addComment(to runID: RunID, text: String, replyingTo parentID: CommentID?) async throws -> Models.Comment {
        if failAdd.withLock({ $0 }) { throw AppError.offline }
        return try await base.addComment(to: runID, text: text, replyingTo: parentID)
    }
    func deleteComment(_ id: CommentID) async throws { try await base.deleteComment(id) }
    func activity(after cursor: String?) async throws -> Page<Activity> { try await base.activity(after: cursor) }
    func markActivityRead() async throws { try await base.markActivityRead() }
}

@MainActor
struct CommentsViewModelTests {
    /// Post 1 has a thread: comment 1, a reply to it (comment 2), and comment 3.
    private let threadPost = SampleSocialData.posts[0]
    /// Post 3 has a comment by the signed-in person (comment 4) and a reply by someone else (comment 5).
    private let myCommentPost = SampleSocialData.posts[2]

    private final class Reports { var ids: [CommentID] = [] }

    private func makeViewModel(
        _ run: HangoutRun, feed: ControlledFeed? = nil, offline: Bool = false, reports: Reports = Reports()
    ) -> (CommentsViewModel, ControlledFeed) {
        let deps = AppDependencies.preview(.loaded)
        let controlled = feed ?? ControlledFeed(base: deps.feed)
        let viewModel = CommentsViewModel(
            runID: run.id, feed: controlled, profiles: deps.profiles, session: deps.session,
            network: NetworkMonitor(isOffline: offline), now: deps.now, makeID: { "id-1" },
            onReport: { reports.ids.append($0) })
        return (viewModel, controlled)
    }

    private func rows(_ viewModel: CommentsViewModel) -> [CommentRowData] {
        if case .loaded(let content, _) = viewModel.state { content.rows } else { [] }
    }

    @Test func theThreadIsOldestFirstAndARelyIsIndented() async {
        let (viewModel, _) = makeViewModel(threadPost)
        await viewModel.load()
        #expect(rows(viewModel).map(\.id) == ["comment-sample-1", "comment-sample-2", "comment-sample-3"])
        #expect(rows(viewModel).map(\.depth) == [0, 1, 0])
    }

    @Test func aPostWithNoCommentsIsTheEmptyState() async {
        let (viewModel, _) = makeViewModel(SampleSocialData.posts[1])
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = CommentsViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func aReplyNestsUnderItsParent() async {
        let (viewModel, _) = makeViewModel(threadPost)
        await viewModel.load()
        viewModel.replyTapped("comment-sample-3")
        #expect(viewModel.replyingToText != nil)
        viewModel.draft = "Thanks, the park was best."
        await viewModel.sendTapped()
        let list = rows(viewModel)
        #expect(list.count == 4)
        #expect(list.last?.depth == 1)
        #expect(list.last?.text == "Thanks, the park was best.")
        #expect(viewModel.replyingToText == nil)
    }

    @Test func sendingClearsTheBoxAndKeepsNoPendingRow() async {
        let (viewModel, _) = makeViewModel(threadPost)
        await viewModel.load()
        viewModel.draft = "Looks great"
        await viewModel.sendTapped()
        #expect(viewModel.draft.isEmpty)
        #expect(viewModel.pending.isEmpty)
        #expect(rows(viewModel).last?.text == "Looks great")
    }

    @Test func sendNeedsWordsAtMost500CharactersAndAConnection() async {
        let (viewModel, _) = makeViewModel(threadPost)
        viewModel.draft = ""
        #expect(!viewModel.canSend)
        viewModel.draft = "   \n "
        #expect(!viewModel.canSend)
        viewModel.draft = String(repeating: "a", count: 500)
        #expect(viewModel.canSend)
        viewModel.draft = String(repeating: "a", count: 501)
        #expect(!viewModel.canSend)

        let (offline, _) = makeViewModel(threadPost, offline: true)
        offline.draft = "Hello"
        #expect(!offline.canSend)
    }

    @Test func aFailedSendStaysVisibleAndRetryWorks() async {
        let (viewModel, feed) = makeViewModel(threadPost)
        await viewModel.load()
        feed.failAdd.withLock { $0 = true }
        viewModel.draft = "Will this send?"
        await viewModel.sendTapped()
        #expect(viewModel.pending.map(\.phase) == [.failed])
        #expect(viewModel.pending.first?.text == "Will this send?")

        feed.failAdd.withLock { $0 = false }
        await viewModel.retryTapped(viewModel.pending[0].id)
        #expect(viewModel.pending.isEmpty)
        #expect(rows(viewModel).last?.text == "Will this send?")
    }

    @Test func aFailedSendCanBeRemoved() async {
        let (viewModel, feed) = makeViewModel(threadPost)
        await viewModel.load()
        feed.failAdd.withLock { $0 = true }
        viewModel.draft = "Nope"
        await viewModel.sendTapped()
        viewModel.removePending(viewModel.pending[0].id)
        #expect(viewModel.pending.isEmpty)
    }

    @Test func youCanDeleteYourOwnCommentButNotSomeoneElses() async {
        let (viewModel, _) = makeViewModel(myCommentPost)
        await viewModel.load()
        let byId = Dictionary(uniqueKeysWithValues: rows(viewModel).map { ($0.id, $0) })
        #expect(byId["comment-sample-4"]?.canDelete == true)
        #expect(byId["comment-sample-5"]?.canDelete == false)
    }

    @Test func deletingShowsDeletedInPlaceAndKeepsTheReply() async {
        let (viewModel, _) = makeViewModel(myCommentPost)
        await viewModel.load()
        viewModel.deleteTapped("comment-sample-4")
        #expect(viewModel.deletingID == "comment-sample-4")
        await viewModel.confirmDelete()
        let list = rows(viewModel)
        #expect(list.map(\.id) == ["comment-sample-4", "comment-sample-5"])
        #expect(list[0].isDeleted && list[0].canDelete == false)
        #expect(list[1].isDeleted == false)
    }

    @Test func cancellingTheQuestionDeletesNothing() async {
        let (viewModel, _) = makeViewModel(myCommentPost)
        await viewModel.load()
        viewModel.deleteTapped("comment-sample-4")
        viewModel.cancelDelete()
        await viewModel.confirmDelete()
        #expect(rows(viewModel)[0].isDeleted == false)
    }

    @Test func theOwnerOfThePostCanDeleteAnyCommentOnIt() async {
        let deps = AppDependencies.preview(.loaded)
        let owned = ControlledFeed(base: deps.feed, owner: SampleData.signedInUser.id)
        let (viewModel, _) = makeViewModel(threadPost, feed: owned)
        await viewModel.load()
        #expect(rows(viewModel).allSatisfy { $0.canDelete })
    }

    @Test func aLikeCountsAtOnceAndAFailedOneRollsBack() async {
        let (viewModel, feed) = makeViewModel(threadPost)
        await viewModel.load()
        let before = rows(viewModel)[0]
        await viewModel.likeTapped(before.id)
        #expect(rows(viewModel)[0].isLiked == !before.isLiked)
        #expect(rows(viewModel)[0].likeCount == before.likeCount + (before.isLiked ? -1 : 1))

        let afterOne = rows(viewModel)[0]
        feed.failLike.withLock { $0 = true }
        await viewModel.likeTapped(before.id)
        #expect(rows(viewModel)[0].isLiked == afterOne.isLiked)
        #expect(rows(viewModel)[0].likeCount == afterOne.likeCount)
        #expect(viewModel.notice != nil)
    }

    @Test func reportHandsTheCommentBackSoTheSheetCanClose() async {
        let reports = Reports()
        let (viewModel, _) = makeViewModel(threadPost, reports: reports)
        await viewModel.load()
        viewModel.reportTapped("comment-sample-3")
        #expect(reports.ids == ["comment-sample-3"])
    }

    @Test func theLastCommentLoadsTheNextPage() async {
        let comments = SampleSocialData.comments.filter { $0.runID == threadPost.id }
        let deps = AppDependencies.preview(.loaded)
        let paged = ControlledFeed(base: deps.feed, pages: [
            nil: Page(items: Array(comments[0..<2]), nextCursor: "2"),
            "2": Page(items: Array(comments[2..<3]), nextCursor: nil)
        ])
        let (viewModel, _) = makeViewModel(threadPost, feed: paged)
        await viewModel.load()
        await viewModel.loadMoreIfNeeded(after: rows(viewModel)[0])   // not the last row: nothing happens
        #expect(rows(viewModel).count == 2)
        await viewModel.loadMoreIfNeeded(after: rows(viewModel)[1])
        #expect(rows(viewModel).map(\.id) == comments.map(\.id.rawValue))
    }

    @Test func timesAreHowLongAgoNeverAClockTime() async {
        let (viewModel, _) = makeViewModel(threadPost)
        await viewModel.load()
        for row in rows(viewModel) { #expect(!row.relativeTimeText.contains(":")) }
    }
}
