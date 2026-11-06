import Components
import Core
import Foundation
import Models
import Observation

/// The view-ready values of the Feed screen (never a raw model).
struct FeedContent: Equatable, Sendable {
    var picks: [HangoutCardData]
    var posts: [PostCardData]
    var hasMore: Bool
}

/// Feed (SC-CM1): the Picks strip, then posted Hangouts (friends first, then newest, as the repository orders them).
@MainActor @Observable
final class FeedViewModel {
    private(set) var state: LoadState<FeedContent> = .loading
    private(set) var isLoadingMore = false
    /// A short message to show once (for example when a like could not be saved). The View clears it.
    var notice: String?
    /// The post whose Comments sheet is open (nil when closed).
    var commentsRunID: RunID?

    private let session: SessionStore
    private let makeComments: CommentsFactory
    private let maker: PostCardMaker
    private var exitAfterComments: CommentsExit?
    private let feed: any FeedRepository
    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let libraryStore: LibraryStore
    private let badges: BadgeStore
    private let router: Router
    private var runs: [RunID: HangoutRun] = [:]
    private var likedRuns: Set<RunID> = []
    private var nextCursor: String?
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        feed: any FeedRepository, hangouts: any HangoutRepository, places: any PlaceRepository,
        photos: any PhotoStore, libraryStore: LibraryStore, badges: BadgeStore, session: SessionStore, router: Router,
        makeComments: @escaping CommentsFactory
    ) {
        self.session = session
        self.makeComments = makeComments
        self.maker = PostCardMaker(hangouts: hangouts, places: places, photos: photos, libraryStore: libraryStore)
        self.feed = feed
        self.hangouts = hangouts
        self.places = places
        self.photos = photos
        self.libraryStore = libraryStore
        self.badges = badges
        self.router = router
    }

    // MARK: Words

    var title: String { String(localized: "community.feed.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "community.feed.empty", bundle: #bundle) }
    var emptyAction: String { String(localized: "community.feed.emptyAction", bundle: #bundle) }
    var picksTitle: String { String(localized: "community.feed.picks", bundle: #bundle) }
    var trendingTitle: String { String(localized: "community.feed.trending", bundle: #bundle) }
    var friendsLabel: String { String(localized: "community.feed.friends", bundle: #bundle) }
    var reportLabel: String { String(localized: "community.feed.report", bundle: #bundle) }
    var blockLabel: String { String(localized: "community.feed.block", bundle: #bundle) }
    var okLabel: String { String(localized: "community.feed.ok", bundle: #bundle) }

    var activityLabel: String {
        hasUnseenActivity
            ? String(localized: "community.feed.activityUnseen", bundle: #bundle)
            : String(localized: "community.feed.activity", bundle: #bundle)
    }

    var chatsLabel: String {
        unreadChatCount > 0
            ? String(localized: "community.feed.chatsUnread \(unreadChatCount)", bundle: #bundle)
            : String(localized: "community.feed.chats", bundle: #bundle)
    }

    // MARK: Badges on the top bar

    var hasUnseenActivity: Bool { badges.unseenActivityCount > 0 }
    var unreadChatCount: Int { badges.unreadChatCount }
    /// "3" on the Chats button; nil when nothing is unread.
    var chatBadgeText: String? { unreadChatCount > 0 ? DisplayFormat.compactCount(unreadChatCount) : nil }

    // MARK: Loading

    /// Called by `.task`. Runs once; `.task` runs again whenever the screen reappears.
    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    /// Pull to refresh and the Retry button.
    func reload() async { await fetch() }

    /// Called when a card scrolls into view: the last card asks for the next page.
    func loadMoreIfNeeded(after post: PostCardData) async {
        guard case .loaded(let content, _) = state, content.hasMore, !isLoadingMore,
              content.posts.last?.id == post.id, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await feed.feed(after: cursor)
            let more = await cards(for: page.items)
            nextCursor = page.nextCursor
            if case .loaded(var current, let stale) = state {
                current.posts += more.filter { new in !current.posts.contains { $0.id == new.id } }
                current.hasMore = page.nextCursor != nil
                state = .loaded(current, isStale: stale)
            }
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message   // a failed next page keeps what is on screen
        }
    }

    private func fetch() async {
        do {
            let page = try await feed.feed(after: nil)
            likedRuns = Set(((try? await feed.likes()) ?? []).compactMap { target in
                if case .run(let id) = target { id } else { nil }
            })
            await libraryStore.ensureLoaded()
            let picks = ((try? await hangouts.picks()) ?? []).map {
                HangoutCardData($0, coverURL: nil, isSaved: libraryStore.isSaved($0.id))
            }
            runs = [:]
            let posts = await cards(for: page.items)
            nextCursor = page.nextCursor
            let content = FeedContent(picks: picks, posts: posts, hasMore: page.nextCursor != nil)
            state = posts.isEmpty && picks.isEmpty ? .empty : .loaded(content)
            hasLoaded = true
            await badges.refresh()   // the Chats and bell numbers belong to this tab
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

    private func cards(for items: [HangoutRun]) async -> [PostCardData] {
        for run in items { runs[run.id] = run }
        return await maker.cards(for: items, liked: likedRuns)
    }

    // MARK: Taps

    func friendsTapped() { router.open(.friendsHub) }
    func activityTapped() { router.open(.activity) }
    func chatsTapped() { router.open(.chatList) }
    func trendingTapped() { router.open(.trending) }
    func pickTapped(_ id: HangoutID) { router.open(.hangout(id)) }
    func openPost(_ post: PostCardData) { router.open(.post(post.id)) }
    func openAuthor(of post: PostCardData) {
        if let run = runs[post.id] { router.open(.profile(run.runnerID)) }
    }
    /// Comments open as a local sheet (SC-CM3).
    func commentTapped(_ post: PostCardData) { commentsRunID = post.id }

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

    func remixTapped(_ post: PostCardData) {
        if let run = runs[post.id] { router.presentCover(.editor(.remix(run.hangoutID))) }
    }
    func shareTapped(_ post: PostCardData) { router.present(.share(.post(post.id))) }
    func reportTapped(_ post: PostCardData) { router.present(.report(.run(post.id))) }

    /// Report is offered on other people's posts only: you cannot report yourself.
    func canReport(_ post: PostCardData) -> Bool {
        guard let run = runs[post.id] else { return true }
        return run.runnerID != session.currentUser?.id
    }

    /// Block is offered on other people's posts only, and never on the official Vybe account.
    func canBlock(_ post: PostCardData) -> Bool {
        guard let run = runs[post.id] else { return false }
        return run.runnerID != session.currentUser?.id && !post.isPick
    }

    func blockTapped(_ post: PostCardData) {
        guard canBlock(post), let run = runs[post.id] else { return }
        router.present(.blockConfirm(run.runnerID))
    }

    func saveTapped(_ post: PostCardData) async {
        guard let run = runs[post.id] else { return }
        await libraryStore.toggleSave(run.hangoutID)
        update(post.id) { $0.isSaved = libraryStore.isSaved(run.hangoutID) }
    }

    /// Optimistic: the heart changes at once; if saving fails it goes back and a notice appears.
    func likeTapped(_ post: PostCardData) async {
        let wasLiked = post.isLiked
        setLiked(!wasLiked, for: post.id)
        do {
            if wasLiked {
                try await feed.unlike(.run(post.id))
            } else {
                try await feed.like(.run(post.id))
            }
        } catch is CancellationError {
            setLiked(wasLiked, for: post.id)
        } catch {
            setLiked(wasLiked, for: post.id)
            notice = String(localized: "community.feed.likeFailed", bundle: #bundle)
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
}
