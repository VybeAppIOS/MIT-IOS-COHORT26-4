import Core
import Models
import Synchronization
import Testing
@testable import CommunityFeature

/// A feed we control: fixed pages, and switches for "likes fail" and "the next load fails".
private final class FakeFeed: FeedRepository {
    let pages: [String?: Page<HangoutRun>]
    let failLike = Mutex(false)
    let failFeed = Mutex(false)

    init(pages: [String?: Page<HangoutRun>]) { self.pages = pages }

    func feed(after cursor: String?) async throws -> Page<HangoutRun> {
        if failFeed.withLock({ $0 }) { throw AppError.offline }
        return pages[cursor] ?? Page(items: [])
    }
    func trending() async throws -> [HangoutRun] { [] }
    func post(id: RunID) async throws -> HangoutRun { throw AppError.notFound }
    func comments(for runID: RunID, after cursor: String?) async throws -> Page<Models.Comment> { Page(items: []) }
    func likes() async throws -> Set<LikeTarget> { [] }
    func like(_ target: LikeTarget) async throws { if failLike.withLock({ $0 }) { throw AppError.offline } }
    func unlike(_ target: LikeTarget) async throws { if failLike.withLock({ $0 }) { throw AppError.offline } }
    func addComment(to runID: RunID, text: String, replyingTo parentID: CommentID?) async throws -> Models.Comment {
        throw AppError.unknown
    }
    func deleteComment(_ id: CommentID) async throws {}
    func activity(after cursor: String?) async throws -> Page<Activity> { Page(items: []) }
    func markActivityRead() async throws {}
}

@MainActor
struct FeedViewModelTests {
    private let posts = Array(SampleSocialData.posts.prefix(6))

    private func makeViewModel(_ feed: FakeFeed, deps: AppDependencies = .preview(.loaded)) -> FeedViewModel {
        FeedViewModel(
            feed: feed, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            libraryStore: deps.libraryStore, badges: deps.badges, session: deps.session, router: deps.router,
            makeComments: CommentsViewModel.previewFactory(deps))
    }

    private func twoPages() -> FakeFeed {
        FakeFeed(pages: [
            nil: Page(items: Array(posts[0..<3]), nextCursor: "3"),
            "3": Page(items: Array(posts[3..<6]), nextCursor: nil)
        ])
    }

    private func content(_ viewModel: FeedViewModel) -> FeedContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func loadShowsPostsInTheOrderTheRepositoryGaveThem() async {
        let viewModel = makeViewModel(twoPages())
        await viewModel.load()
        #expect(content(viewModel)?.posts.map(\.id) == posts[0..<3].map(\.id))
        #expect(content(viewModel)?.hasMore == true)
    }

    @Test func loadingTheLastCardAddsTheNextPage() async {
        let viewModel = makeViewModel(twoPages())
        await viewModel.load()
        let first = content(viewModel)!.posts[0]
        await viewModel.loadMoreIfNeeded(after: first)   // not the last card: nothing happens
        #expect(content(viewModel)?.posts.count == 3)

        await viewModel.loadMoreIfNeeded(after: content(viewModel)!.posts[2])
        #expect(content(viewModel)?.posts.map(\.id) == posts.map(\.id))
        #expect(content(viewModel)?.hasMore == false)
    }

    @Test func aLikeCountsAtOnceAndStays() async {
        let viewModel = makeViewModel(twoPages())
        await viewModel.load()
        let before = content(viewModel)!.posts[0]
        await viewModel.likeTapped(before)
        let after = content(viewModel)!.posts[0]
        #expect(after.isLiked == !before.isLiked)
        #expect(after.likeCount == before.likeCount + (before.isLiked ? -1 : 1))
        #expect(viewModel.notice == nil)
    }

    @Test func aFailedLikeRollsBackAndTellsThePerson() async {
        let feed = twoPages()
        let viewModel = makeViewModel(feed)
        await viewModel.load()
        let before = content(viewModel)!.posts[0]
        feed.failLike.withLock { $0 = true }
        await viewModel.likeTapped(before)
        let after = content(viewModel)!.posts[0]
        #expect(after.isLiked == before.isLiked)
        #expect(after.likeCount == before.likeCount)
        #expect(viewModel.notice != nil)
    }

    @Test func aFailedRefreshKeepsThePostsAndMarksThemStale() async {
        let feed = twoPages()
        let viewModel = makeViewModel(feed)
        await viewModel.load()
        feed.failFeed.withLock { $0 = true }
        await viewModel.reload()
        guard case .loaded(let kept, let isStale) = viewModel.state else {
            Issue.record("expected loaded, got \(viewModel.state)")
            return
        }
        #expect(isStale)
        #expect(kept.posts.count == 3)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = FeedViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func noPostsAndNoPicksIsTheEmptyState() async {
        let viewModel = FeedViewModel.preview(.empty)
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func tapsGoThroughTheRouter() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(twoPages(), deps: deps)
        await viewModel.load()
        let post = content(viewModel)!.posts[0]
        let hangoutID = posts[0].hangoutID

        viewModel.remixTapped(post)
        #expect(deps.router.cover == .editor(.remix(hangoutID)))
        viewModel.shareTapped(post)
        #expect(deps.router.sheet == .share(.post(post.id)))
        viewModel.reportTapped(post)
        #expect(deps.router.sheet == .report(.run(post.id)))
        viewModel.friendsTapped()
        #expect(deps.router.path(for: deps.router.currentStack).last == .friendsHub)
        viewModel.openPost(post)
        #expect(deps.router.path(for: deps.router.currentStack).last == .post(post.id))
    }

    @Test func aPostCardNeverCarriesAClockTime() async {
        let viewModel = makeViewModel(twoPages())
        await viewModel.load()
        for post in content(viewModel)!.posts {
            #expect(!post.factsText.contains(":"))
            #expect(!(post.dayText ?? "").contains(":"))
        }
    }

    @Test func blockIsOfferedOnOthersPostsButNotOnYoursOrOnPicks() async {
        let myself = SampleData.signedInUser
        let mine = HangoutRun(
            id: "run-mine", hangoutID: posts[2].hangoutID, runnerID: myself.id, state: .posted, visits: posts[2].visits,
            card: posts[2].card)
        let friendPost = posts.first { !$0.card.runnerUsername.hasPrefix("vybe") && $0.runnerID != myself.id }!
        let pick = posts.first { $0.card.runnerUsername == "vybe" }!
        let feed = FakeFeed(pages: [nil: Page(items: [friendPost, mine, pick], nextCursor: nil)])
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(feed, deps: deps)
        await viewModel.load()
        let cards = content(viewModel)!.posts
        #expect(viewModel.canBlock(cards[0]))
        #expect(!viewModel.canBlock(cards[1]))
        #expect(!viewModel.canBlock(cards[2]))

        #expect(viewModel.canReport(cards[0]))
        #expect(!viewModel.canReport(cards[1]))   // your own post: no Report
        #expect(viewModel.canReport(cards[2]))

        viewModel.blockTapped(cards[0])
        #expect(deps.router.sheet == .blockConfirm(friendPost.runnerID))
        deps.router.dismissSheet()
        viewModel.blockTapped(cards[1])
        #expect(deps.router.sheet == nil)
    }

    @Test func theChatsButtonShowsTheUnreadCountOnlyWhenThereIsOne() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(twoPages(), deps: deps)
        #expect(viewModel.chatBadgeText == nil)
        await viewModel.load()   // loading the Feed refreshes the badge numbers
        let unread = deps.badges.unreadChatCount
        #expect(unread > 0)
        #expect(viewModel.chatBadgeText == "\(unread)")
    }
}
