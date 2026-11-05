import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import CommunityFeature

/// A feed with a fixed trending list and switches for "likes fail" and "the next load fails".
private final class TrendingFeed: FeedRepository {
    let base: any FeedRepository
    let list: [HangoutRun]
    let failLike = Mutex(false)
    let failTrending = Mutex(false)

    init(base: any FeedRepository, list: [HangoutRun]) {
        self.base = base
        self.list = list
    }

    func feed(after cursor: String?) async throws -> Page<HangoutRun> { try await base.feed(after: cursor) }
    func trending() async throws -> [HangoutRun] {
        if failTrending.withLock({ $0 }) { throw AppError.offline }
        return list
    }
    func post(id: RunID) async throws -> HangoutRun { try await base.post(id: id) }
    func comments(for runID: RunID, after cursor: String?) async throws -> Page<Models.Comment> {
        try await base.comments(for: runID, after: cursor)
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
        try await base.addComment(to: runID, text: text, replyingTo: parentID)
    }
    func deleteComment(_ id: CommentID) async throws { try await base.deleteComment(id) }
    func activity(after cursor: String?) async throws -> Page<Activity> { try await base.activity(after: cursor) }
    func markActivityRead() async throws { try await base.markActivityRead() }
}

@MainActor
struct TrendingViewModelTests {
    /// 25 posts, each a copy of a sample post with its own ID, so paging has something to page.
    private func manyPosts(_ count: Int) -> [HangoutRun] {
        (0..<count).map { index in
            let source = SampleSocialData.posts[index % SampleSocialData.posts.count]
            return HangoutRun(
                id: RunID("run-trending-\(index)"), hangoutID: source.hangoutID, runnerID: source.runnerID,
                state: .posted, visits: source.visits, durationMinutes: source.durationMinutes, title: source.title,
                caption: source.caption, tags: source.tags, visibility: source.visibility, audience: source.audience,
                card: source.card, likeCount: source.likeCount, commentCount: source.commentCount,
                postedAt: source.postedAt)
        }
    }

    private func makeViewModel(
        list: [HangoutRun], deps: AppDependencies = .preview(.loaded)
    ) -> (TrendingViewModel, TrendingFeed) {
        let feed = TrendingFeed(base: deps.feed, list: list)
        let viewModel = TrendingViewModel(
            feed: feed, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            libraryStore: deps.libraryStore, session: deps.session, router: deps.router,
            makeComments: CommentsViewModel.previewFactory(deps))
        return (viewModel, feed)
    }

    private func content(_ viewModel: TrendingViewModel) -> TrendingContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func loadShowsThePostsInTheOrderGiven() async {
        let list = manyPosts(4)
        let (viewModel, _) = makeViewModel(list: list)
        await viewModel.load()
        #expect(content(viewModel)?.posts.map(\.id) == list.map(\.id))
        #expect(content(viewModel)?.hasMore == false)
    }

    @Test func aLongListShowsOneBatchThenMoreWhenTheLastCardAppears() async {
        let list = manyPosts(25)
        let (viewModel, _) = makeViewModel(list: list)
        await viewModel.load()
        #expect(content(viewModel)?.posts.count == TrendingViewModel.pageSize)
        #expect(content(viewModel)?.hasMore == true)

        await viewModel.loadMoreIfNeeded(after: content(viewModel)!.posts[0])   // not the last card: nothing
        #expect(content(viewModel)?.posts.count == TrendingViewModel.pageSize)

        await viewModel.loadMoreIfNeeded(after: content(viewModel)!.posts.last!)
        #expect(content(viewModel)?.posts.count == TrendingViewModel.pageSize * 2)
        await viewModel.loadMoreIfNeeded(after: content(viewModel)!.posts.last!)
        #expect(content(viewModel)?.posts.map(\.id) == list.map(\.id))
        #expect(content(viewModel)?.hasMore == false)
    }

    @Test func nothingTrendingIsTheEmptyState() async {
        let viewModel = TrendingViewModel.preview(.empty)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = TrendingViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func aFailedRefreshKeepsThePostsAndMarksThemStale() async {
        let (viewModel, feed) = makeViewModel(list: manyPosts(3))
        await viewModel.load()
        feed.failTrending.withLock { $0 = true }
        await viewModel.reload()
        guard case .loaded(let kept, let isStale) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        #expect(isStale && kept.posts.count == 3)
    }

    @Test func aFailedLikeRollsBackAndTellsThePerson() async {
        let (viewModel, feed) = makeViewModel(list: Array(SampleSocialData.posts.prefix(3)))
        await viewModel.load()
        let before = content(viewModel)!.posts[0]
        feed.failLike.withLock { $0 = true }
        await viewModel.likeTapped(before)
        let after = content(viewModel)!.posts[0]
        #expect(after.isLiked == before.isLiked && after.likeCount == before.likeCount)
        #expect(viewModel.notice != nil)
    }

    @Test func aLikeCountsAtOnce() async {
        let (viewModel, _) = makeViewModel(list: Array(SampleSocialData.posts.prefix(3)))
        await viewModel.load()
        let before = content(viewModel)!.posts[0]
        await viewModel.likeTapped(before)
        let after = content(viewModel)!.posts[0]
        #expect(after.isLiked == !before.isLiked)
        #expect(after.likeCount == before.likeCount + (before.isLiked ? -1 : 1))
    }

    @Test func tapsGoThroughTheRouter() async {
        let deps = AppDependencies.preview(.loaded)
        let list = manyPosts(3)
        let (viewModel, _) = makeViewModel(list: list, deps: deps)
        await viewModel.load()
        let post = content(viewModel)!.posts[0]

        viewModel.remixTapped(post)
        #expect(deps.router.cover == .editor(.remix(list[0].hangoutID)))
        viewModel.shareTapped(post)
        #expect(deps.router.sheet == .share(.post(post.id)))
        viewModel.reportTapped(post)
        #expect(deps.router.sheet == .report(.run(post.id)))
        viewModel.openPost(post)
        #expect(deps.router.path(for: deps.router.currentStack).last == .post(post.id))
        viewModel.openAuthor(of: post)
        #expect(deps.router.path(for: deps.router.currentStack).last == .profile(list[0].runnerID))
        viewModel.commentTapped(post)
        #expect(viewModel.commentsRunID == post.id)
    }

    @Test func reportIsOfferedOnOthersPostsButNotOnYours() async {
        let myself = SampleData.signedInUser
        var list = manyPosts(2)
        list[0].runnerID = myself.id
        let (viewModel, _) = makeViewModel(list: list)
        await viewModel.load()
        let cards = content(viewModel)!.posts
        #expect(!viewModel.canReport(cards[0]))
        #expect(viewModel.canReport(cards[1]) == (list[1].runnerID != myself.id))
        #expect(list[1].runnerID != myself.id)
    }

    @Test func nothingOnACardIsAClockTime() async {
        let (viewModel, _) = makeViewModel(list: manyPosts(5))
        await viewModel.load()
        for post in content(viewModel)!.posts {
            #expect(!post.factsText.contains(":") && !(post.dayText ?? "").contains(":"))
        }
    }
}
