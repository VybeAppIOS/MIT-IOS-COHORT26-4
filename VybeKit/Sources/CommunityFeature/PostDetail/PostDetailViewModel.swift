import Components
import Core
import Design
import Foundation
import Models
import Observation

/// The view-ready values of the Post detail screen (never a raw model).
struct PostDetailContent: Equatable, Sendable {
    var post: PostCardData
    var gallery: [GalleryPhoto]
    var spots: [SpotRowData]
    var comments: [CommentRowData]
    var hasMoreComments: Bool
    /// "Done 40× · Remixed 12×", only for a Pick.
    var pickStatsText: String?
    /// "You", "Friends" or nil.
    var relationshipText: String?
    var isFriendsOnly: Bool
    var isOwn: Bool
}

/// Post detail (SC-CM2): one posted Hangout in full. Shows the order of the visited Spots, never a time.
@MainActor @Observable
final class PostDetailViewModel {
    private(set) var state: LoadState<PostDetailContent> = .loading
    /// A short message to show once. The View clears it.
    var notice: String?
    /// True while the Comments sheet (SC-CM3) is open.
    var isShowingComments = false

    private let makeComments: CommentsFactory
    private var exitAfterComments: CommentsExit?

    private let runID: RunID
    private let feed: any FeedRepository
    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let profiles: any ProfileRepository
    private let friends: any FriendsRepository
    private let photos: any PhotoStore
    private let libraryStore: LibraryStore
    private let session: SessionStore
    private let router: Router
    private let now: @Sendable () -> Date
    private var run: HangoutRun?
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        runID: RunID, feed: any FeedRepository, hangouts: any HangoutRepository, places: any PlaceRepository,
        profiles: any ProfileRepository, friends: any FriendsRepository, photos: any PhotoStore,
        libraryStore: LibraryStore, session: SessionStore, router: Router, now: @escaping @Sendable () -> Date,
        makeComments: @escaping CommentsFactory
    ) {
        self.makeComments = makeComments
        self.runID = runID
        self.feed = feed
        self.hangouts = hangouts
        self.places = places
        self.profiles = profiles
        self.friends = friends
        self.photos = photos
        self.libraryStore = libraryStore
        self.session = session
        self.router = router
        self.now = now
    }

    // MARK: Words

    var title: String { String(localized: "community.postDetail.title", bundle: #bundle) }
    var unavailableMessage: String { String(localized: "community.postDetail.empty", bundle: #bundle) }
    var spotsTitle: String { String(localized: "community.postDetail.spots", bundle: #bundle) }
    var commentsTitle: String { String(localized: "community.postDetail.comments", bundle: #bundle) }
    var viewAllComments: String { String(localized: "community.postDetail.viewAll", bundle: #bundle) }
    var noComments: String { String(localized: "community.postDetail.noComments", bundle: #bundle) }
    var friendsOnlyNote: String { String(localized: "community.postDetail.friendsOnly", bundle: #bundle) }
    var editLabel: String { String(localized: "community.postDetail.edit", bundle: #bundle) }
    var reportLabel: String { String(localized: "community.postDetail.report", bundle: #bundle) }
    var moreLabel: String { String(localized: "community.postDetail.more", bundle: #bundle) }
    func saveLabel(isSaved: Bool) -> String {
        isSaved
            ? String(localized: "community.postDetail.unsave", bundle: #bundle)
            : String(localized: "community.postDetail.save", bundle: #bundle)
    }
    var blockLabel: String { String(localized: "community.postDetail.block", bundle: #bundle) }
    var okLabel: String { String(localized: "community.postDetail.ok", bundle: #bundle) }

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
            let run = try await feed.post(id: runID)
            self.run = run
            let content = await makeContent(for: run)
            state = .loaded(content)
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch AppError.notFound {
            state = .empty   // removed, or its author is blocked: "This post is unavailable"
            hasLoaded = true
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))   // only a first load can fail
            }
        }
    }

    /// Everything comes from the public post fields: never `RunTimes`, never a clock time.
    private func makeContent(for run: HangoutRun) async -> PostDetailContent {
        let likes = (try? await feed.likes()) ?? []
        await libraryStore.ensureLoaded()
        let stats = try? await hangouts.stats(for: run.hangoutID)
        let friendIDs = Set(((try? await friends.friends()) ?? []).map(\.id))
        let spots = await spotRows(for: run)
        let isPick = run.card.runnerUsername == "vybe"
        let isOwn = run.runnerID == session.currentUser?.id

        let card = PostCardData(
            run, coverURL: nil, avatarURL: run.card.runnerPhoto.flatMap { photos.url(for: $0) },
            routePoints: [], remixCount: stats?.remixCount ?? 0, isPick: isPick,
            isLiked: likes.contains(.run(run.id)), isSaved: libraryStore.isSaved(run.hangoutID))
        let page = try? await feed.comments(for: run.id, after: nil)
        let comments = await commentRows(page?.items ?? [], likes: likes, ownerID: run.runnerID)
        return PostDetailContent(
            post: card,
            gallery: run.photos.map { GalleryPhoto(id: $0.id.rawValue, url: photos.url(for: $0), credit: $0.credit) },
            spots: spots, comments: Array(comments.prefix(Self.previewCommentCount)),
            hasMoreComments: comments.count > Self.previewCommentCount || page?.nextCursor != nil,
            pickStatsText: isPick ? stats.map { Self.pickStats($0) } : nil,
            relationshipText: relationship(isOwn: isOwn, isFriend: friendIDs.contains(run.runnerID)),
            isFriendsOnly: run.audience == .friends, isOwn: isOwn)
    }

    static let previewCommentCount = 3

    private func relationship(isOwn: Bool, isFriend: Bool) -> String? {
        if isOwn { return ComponentStrings.you }
        return isFriend ? ComponentStrings.friends : nil
    }

    private static func pickStats(_ stats: HangoutStats) -> String {
        String(localized: "community.postDetail.pickStats \(stats.doneCount) \(stats.remixCount)", bundle: #bundle)
    }

    /// The visited Spots, in order, each marked visited. No times, only the order.
    private func spotRows(for run: HangoutRun) async -> [SpotRowData] {
        var rows: [SpotRowData] = []
        let notes = Dictionary(
            ((try? await hangouts.hangout(id: run.hangoutID))?.spots ?? []).map { ($0.id, $0.note) },
            uniquingKeysWith: { first, _ in first })
        for visit in run.visits.sorted(by: { $0.order < $1.order }) {
            guard let place = try? await places.place(id: visit.placeID) else { continue }
            rows.append(SpotRowData(
                id: visit.spotID, order: visit.order, total: run.card.totalSpots, placeName: place.name,
                categoryText: ComponentStrings.categoryName(place.category), note: notes[visit.spotID] ?? nil,
                state: .visited))
        }
        return rows
    }

    private func commentRows(_ items: [Comment], likes: Set<LikeTarget>, ownerID: UserID) async -> [CommentRowData] {
        var names: [UserID: UserProfile] = [:]
        var parents: [CommentID: CommentID?] = [:]
        for comment in items { parents[comment.id] = comment.parentID }
        var rows: [CommentRowData] = []
        for comment in items {
            if names[comment.authorID] == nil {
                names[comment.authorID] = try? await profiles.profile(id: comment.authorID)
            }
            let author = names[comment.authorID]
            rows.append(CommentRowData(
                id: comment.id.rawValue, authorName: author?.displayName ?? "", username: "@\(author?.username ?? "")",
                text: comment.text, relativeTimeText: relativeText(since: comment.createdAt),
                likeCount: comment.likeCount, isLiked: likes.contains(.comment(comment.id)),
                depth: Self.depth(of: comment.id, in: parents), isDeleted: comment.deletedAt != nil))
        }
        return rows
    }

    private static func depth(of id: CommentID, in parents: [CommentID: CommentID?]) -> Int {
        var depth = 0
        var current = id
        while let next = parents[current] ?? nil, depth < CommentRowData.maxVisibleDepth {
            depth += 1
            current = next
        }
        return depth
    }

    /// "2d", "5h", "12m": how long ago, never a clock time.
    func relativeText(since date: Date) -> String {
        let seconds = max(0, now().timeIntervalSince(date))
        return Duration.seconds(seconds).formatted(
            .units(allowed: [.days, .hours, .minutes], width: .narrow, maximumUnitCount: 1))
    }

    // MARK: Taps

    func openAuthor() {
        if let run { router.open(.profile(run.runnerID)) }
    }

    func remixTapped() {
        if let run { router.presentCover(.editor(.remix(run.hangoutID))) }
    }

    func shareTapped() { router.present(.share(.post(runID))) }
    func reportTapped() { router.present(.report(.run(runID))) }

    /// Block is offered on other people's posts only, and never on the official Vybe account.
    var canBlock: Bool {
        guard case .loaded(let content, _) = state, let run else { return false }
        return !content.isOwn && !content.post.isPick && run.runnerID != session.currentUser?.id
    }

    func blockTapped() {
        guard canBlock, let run else { return }
        router.present(.blockConfirm(run.runnerID))
    }
    func editTapped() { router.present(.editPost(runID)) }
    func reportComment(_ id: String) { router.present(.report(.comment(CommentID(id)))) }
    /// Comments open as a local sheet (SC-CM3).
    func commentsTapped() { isShowingComments = true }

    func makeCommentsViewModel() -> CommentsViewModel {
        makeComments(runID) { [weak self] exit in
            self?.exitAfterComments = exit
            self?.isShowingComments = false
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

    func saveTapped() async {
        guard let run else { return }
        await libraryStore.toggleSave(run.hangoutID)
        update { $0.post.isSaved = libraryStore.isSaved(run.hangoutID) }
    }

    /// Optimistic: the heart changes at once; if saving fails it goes back and a notice appears.
    func likeTapped() async {
        guard case .loaded(let content, _) = state else { return }
        let wasLiked = content.post.isLiked
        setLiked(!wasLiked)
        do {
            if wasLiked { try await feed.unlike(.run(runID)) } else { try await feed.like(.run(runID)) }
        } catch is CancellationError {
            setLiked(wasLiked)
        } catch {
            setLiked(wasLiked)
            notice = String(localized: "community.postDetail.likeFailed", bundle: #bundle)
        }
    }

    private func setLiked(_ liked: Bool) {
        update {
            guard $0.post.isLiked != liked else { return }
            $0.post.isLiked = liked
            $0.post.likeCount = max(0, $0.post.likeCount + (liked ? 1 : -1))
        }
    }

    private func update(_ change: (inout PostDetailContent) -> Void) {
        guard case .loaded(var content, let stale) = state else { return }
        change(&content)
        state = .loaded(content, isStale: stale)
    }
}
