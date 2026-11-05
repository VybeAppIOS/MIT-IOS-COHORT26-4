import Components
import Core
import Foundation
import Models
import Observation

/// The view-ready values of the Trending screen (never a raw model).
struct TrendingContent: Equatable, Sendable {
    var posts: [PostCardData]
    var hasMore: Bool
}

/// Trending (SC-CM4): the posts people liked most this week, as a full list. The repository returns the whole list,
/// so paging happens here: a first batch, then more as the last card comes into view.
@MainActor @Observable
final class TrendingViewModel {
    static let pageSize = 10

    private(set) var state: LoadState<TrendingContent> = .loading
    /// A short message to show once. The View clears it.
    var notice: String?
    /// The post whose Comments sheet is open (nil when closed).
    var commentsRunID: RunID?

    private let feed: any FeedRepository
    private let libraryStore: LibraryStore
    private let session: SessionStore
    private let router: Router
    private let makeComments: CommentsFactory
    private let maker: PostCardMaker
    private var runs: [HangoutRun] = []
    private var visibleCount = 0
    private var likedRuns: Set<RunID> = []
    private var exitAfterComments: CommentsExit?
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        feed: any FeedRepository, hangouts: any HangoutRepository, places: any PlaceRepository,
        photos: any PhotoStore, libraryStore: LibraryStore, session: SessionStore, router: Router,
        makeComments: @escaping CommentsFactory
    ) {
        self.feed = feed
        self.libraryStore = libraryStore
        self.session = session
        self.router = router
        self.makeComments = makeComments
        self.maker = PostCardMaker(hangouts: hangouts, places: places, photos: photos, libraryStore: libraryStore)
    }

    // MARK: Words

    var title: String { String(localized: "community.trending.title", bundle: #bundle) }
    var subtitle: String { String(localized: "community.trending.subtitle", bundle: #bundle) }
    var emptyMessage: String { String(localized: "community.trending.empty", bundle: #bundle) }
    var reportLabel: String { String(localized: "community.trending.report", bundle: #bundle) }
    var okLabel: String { String(localized: "community.trending.ok", bundle: #bundle) }

    // MARK: Loading

    /// Called by `.task`. Runs once; `.task` runs again whenever the screen reappears.
    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    /// Pull to refresh and the Retry button.
    func reload() async { await fetch() }

    private func fetch() async {
        do {
            runs = try await feed.trending()
            likedRuns = Set(((try? await feed.likes()) ?? []).compactMap { target in
                if case .run(let id) = target { id } else { nil }
            })
            await libraryStore.ensureLoaded()
            visibleCount = min(Self.pageSize, runs.count)
            await publish()
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))   // only a first load can fail
            }
        }
    }

    /// Called when a card scrolls into view: the last visible card shows the next batch.
    func loadMoreIfNeeded(after post: PostCardData) async {
        guard case .loaded(let content, _) = state, content.hasMore, content.posts.last?.id == post.id else { return }
        visibleCount = min(visibleCount + Self.pageSize, runs.count)
        await publish()
    }

    private func publish() async {
        let shown = Array(runs.prefix(visibleCount))
        let cards = await maker.cards(for: shown, liked: likedRuns)
        state = cards.isEmpty ? .empty : .loaded(TrendingContent(posts: cards, hasMore: visibleCount < runs.count))
    }

    // MARK: Taps

    func openPost(_ post: PostCardData) { router.open(.post(post.id)) }
    func openAuthor(of post: PostCardData) {
        if let run = runs.first(where: { $0.id == post.id }) { router.open(.profile(run.runnerID)) }
    }
    func commentTapped(_ post: PostCardData) { commentsRunID = post.id }
    func remixTapped(_ post: PostCardData) {
        if let run = runs.first(where: { $0.id == post.id }) { router.presentCover(.editor(.remix(run.hangoutID))) }
    }
    func shareTapped(_ post: PostCardData) { router.present(.share(.post(post.id))) }
    func reportTapped(_ post: PostCardData) { router.present(.report(.run(post.id))) }

    /// Report is offered on other people's posts only: you cannot report yourself.
    func canReport(_ post: PostCardData) -> Bool {
        guard let run = runs.first(where: { $0.id == post.id }) else { return true }
        return run.runnerID != session.currentUser?.id
    }

    func saveTapped(_ post: PostCardData) async {
        guard let run = runs.first(where: { $0.id == post.id }) else { return }
        await libraryStore.toggleSave(run.hangoutID)
        update(post.id) { $0.isSaved = libraryStore.isSaved(run.hangoutID) }
    }

    /// Optimistic: the heart changes at once; if saving fails it goes back and a notice appears.
    func likeTapped(_ post: PostCardData) async {
        let wasLiked = post.isLiked
        setLiked(!wasLiked, for: post.id)
        do {
            if wasLiked { try await feed.unlike(.run(post.id)) } else { try await feed.like(.run(post.id)) }
        } catch {
            setLiked(wasLiked, for: post.id)
            if !(error is CancellationError) {
                notice = String(localized: "community.trending.likeFailed", bundle: #bundle)
            }
        }
    }

    private func setLiked(_ liked: Bool, for id: RunID) {
        if liked { likedRuns.insert(id) } else { likedRuns.remove(id) }
        update(id) {
            guard $0.isLiked != liked else { return }
            $0.isLiked = liked
            $0.likeCount = max(0, $0.likeCount + (liked ? 1 : -1))
        }
    }

    private func update(_ id: RunID, _ change: (inout PostCardData) -> Void) {
        guard case .loaded(var content, let stale) = state,
              let index = content.posts.firstIndex(where: { $0.id == id }) else { return }
        change(&content.posts[index])
        state = .loaded(content, isStale: stale)
    }

    // MARK: Comments sheet

    func makeCommentsViewModel(for id: RunID) -> CommentsViewModel {
        makeComments(id) { [weak self] exit in
            self?.exitAfterComments = exit
            self?.commentsRunID = nil
        }
    }

    /// The Comments sheet has closed: go to Report or a profile if that is why it closed, and refresh the counts.
    func commentsDismissed() async {
        if let exit = exitAfterComments {
            exitAfterComments = nil
            switch exit {
            case .report(let id): router.present(.report(.comment(id)))
            case .profile(let id): router.open(.profile(id))
            }
        }
        await reload()
    }
}
