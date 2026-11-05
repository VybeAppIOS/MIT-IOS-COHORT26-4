import Core
import Models
import Synchronization
import Testing
@testable import CommunityFeature

/// Wraps the sample feed and lets a test make likes fail.
private final class FlakyLikes: FeedRepository {
    let base: any FeedRepository
    let failLike = Mutex(false)
    init(base: any FeedRepository) { self.base = base }

    func feed(after cursor: String?) async throws -> Page<HangoutRun> { try await base.feed(after: cursor) }
    func trending() async throws -> [HangoutRun] { try await base.trending() }
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
struct PostDetailViewModelTests {
    private let friendPost = SampleSocialData.posts[2]
    private let pickPost = SampleSocialData.posts[0]

    private func makeViewModel(
        _ run: HangoutRun, feed: (any FeedRepository)? = nil, deps: AppDependencies = .preview(.loaded)
    ) -> PostDetailViewModel {
        PostDetailViewModel(
            runID: run.id, feed: feed ?? deps.feed, hangouts: deps.hangouts, places: deps.places,
            profiles: deps.profiles, friends: deps.friends, photos: deps.photos, libraryStore: deps.libraryStore,
            session: deps.session, router: deps.router, now: deps.now,
            makeComments: CommentsViewModel.previewFactory(deps))
    }

    private func content(_ viewModel: PostDetailViewModel) -> PostDetailContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func loadShowsThePostWithItsSpotsInOrder() async {
        let viewModel = makeViewModel(friendPost)
        await viewModel.load()
        let spots = content(viewModel)?.spots
        #expect(content(viewModel)?.post.id == friendPost.id)
        #expect(spots?.map(\.order) == (spots?.map(\.order).sorted()))
        #expect(spots?.allSatisfy { $0.state == .visited } == true)
    }

    @Test func onlyAFriendsOnlyPostShowsTheNote() async {
        let viewModel = makeViewModel(friendPost)
        await viewModel.load()
        #expect(content(viewModel)?.isFriendsOnly == (friendPost.audience == .friends))
    }

    @Test func onlyAPickShowsTheDoneAndRemixedLine() async {
        let pick = makeViewModel(pickPost)
        await pick.load()
        let friend = makeViewModel(friendPost)
        await friend.load()
        #expect(content(pick)?.pickStatsText != nil)
        #expect(content(friend)?.pickStatsText == nil)
    }

    @Test func atMostThreeCommentsAreShownAndTheRestAreOneTapAway() async {
        let viewModel = makeViewModel(pickPost)
        await viewModel.load()
        let shown = content(viewModel)?.comments.count ?? 99
        #expect(shown <= PostDetailViewModel.previewCommentCount)
    }

    @Test func aMissingPostIsUnavailableNotAnError() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = PostDetailViewModel(
            runID: "no-such-post", feed: deps.feed, hangouts: deps.hangouts, places: deps.places,
            profiles: deps.profiles, friends: deps.friends, photos: deps.photos, libraryStore: deps.libraryStore,
            session: deps.session, router: deps.router, now: deps.now,
            makeComments: CommentsViewModel.previewFactory(deps))
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = PostDetailViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func aLikeCountsAtOnceAndAFailedOneRollsBack() async {
        let deps = AppDependencies.preview(.loaded)
        let flaky = FlakyLikes(base: deps.feed)
        let viewModel = makeViewModel(friendPost, feed: flaky, deps: deps)
        await viewModel.load()
        let before = content(viewModel)!.post

        await viewModel.likeTapped()
        let liked = content(viewModel)!.post
        #expect(liked.isLiked == !before.isLiked)
        #expect(liked.likeCount == before.likeCount + (before.isLiked ? -1 : 1))

        flaky.failLike.withLock { $0 = true }
        await viewModel.likeTapped()
        #expect(content(viewModel)!.post.isLiked == liked.isLiked)
        #expect(viewModel.notice != nil)
    }

    @Test func tapsGoThroughTheRouter() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(friendPost, deps: deps)
        await viewModel.load()

        viewModel.remixTapped()
        #expect(deps.router.cover == .editor(.remix(friendPost.hangoutID)))
        viewModel.shareTapped()
        #expect(deps.router.sheet == .share(.post(friendPost.id)))
        viewModel.editTapped()
        #expect(deps.router.sheet == .editPost(friendPost.id))
        viewModel.reportTapped()
        #expect(deps.router.sheet == .report(.run(friendPost.id)))
        viewModel.openAuthor()
        #expect(deps.router.path(for: deps.router.currentStack).last == .profile(friendPost.runnerID))
    }

    @Test func nothingOnTheScreenIsAClockTime() async {
        let viewModel = makeViewModel(pickPost)
        await viewModel.load()
        let post = content(viewModel)!.post
        #expect(!post.factsText.contains(":"))
        #expect(!(post.dayText ?? "").contains(":"))
    }

    @Test func blockIsOfferedOnAFriendsPostButNotOnAPick() async {
        let deps = AppDependencies.preview(.loaded)
        let friend = makeViewModel(friendPost, deps: deps)
        await friend.load()
        #expect(friend.canBlock)
        friend.blockTapped()
        #expect(deps.router.sheet == .blockConfirm(friendPost.runnerID))

        let pick = makeViewModel(pickPost)
        await pick.load()
        #expect(!pick.canBlock)
    }
}
