import Components
import Core
import Foundation
import Models
import Observation

/// Builds the Comments sheet's ViewModel. The Feed and Post detail hold one, so neither needs to know what Comments
/// is made of. `onReport` is called when the person chooses Report on a comment (the parent closes the sheet first).
typealias CommentsFactory = @MainActor (RunID, @escaping @MainActor (CommentID) -> Void) -> CommentsViewModel

/// The view-ready values of the Comments sheet (never a raw model).
struct CommentsContent: Equatable, Sendable {
    var rows: [CommentRowData]
    var hasMore: Bool
}

/// A comment the person just wrote: shown at once, then confirmed or marked as failed (with a retry).
struct PendingComment: Identifiable, Equatable {
    enum Phase: Equatable { case sending, failed }

    let id: String
    let text: String
    let parentID: CommentID?
    var phase: Phase
}

/// Comments (SC-CM3): the threaded comments of one post, oldest first, with a composer.
@MainActor @Observable
final class CommentsViewModel {
    static let characterLimit = 500

    private(set) var state: LoadState<CommentsContent> = .loading
    private(set) var pending: [PendingComment] = []
    private(set) var isLoadingMore = false
    /// The comment the person is replying to, shown above the composer.
    private(set) var replyTarget: (id: CommentID, name: String)?
    /// The comment waiting for a "Delete?" answer.
    private(set) var deletingID: CommentID?
    /// Counts up each time a like is added (not removed), so the View can play the like haptic.
    private(set) var likeCount = 0
    /// A short message to show once. The View clears it.
    var notice: String?
    var draft = ""

    private let runID: RunID
    private let feed: any FeedRepository
    private let profiles: any ProfileRepository
    private let session: SessionStore
    private let network: NetworkMonitor
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> String
    private let onReport: @MainActor (CommentID) -> Void
    private var comments: [Comment] = []
    private var authors: [UserID: UserProfile] = [:]
    private var likedComments: Set<CommentID> = []
    private var postOwnerID: UserID?
    private var nextCursor: String?
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        runID: RunID, feed: any FeedRepository, profiles: any ProfileRepository, session: SessionStore,
        network: NetworkMonitor, now: @escaping @Sendable () -> Date, makeID: @escaping @Sendable () -> String,
        onReport: @escaping @MainActor (CommentID) -> Void
    ) {
        self.runID = runID
        self.feed = feed
        self.profiles = profiles
        self.session = session
        self.network = network
        self.now = now
        self.makeID = makeID
        self.onReport = onReport
    }

    // MARK: Words

    var title: String { String(localized: "community.comments.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "community.comments.empty", bundle: #bundle) }
    var placeholder: String { String(localized: "community.comments.placeholder", bundle: #bundle) }
    var sendLabel: String { String(localized: "community.comments.send", bundle: #bundle) }
    var doneLabel: String { String(localized: "community.comments.done", bundle: #bundle) }
    var cancelReplyLabel: String { String(localized: "community.comments.cancelReply", bundle: #bundle) }
    var retryLabel: String { String(localized: "community.comments.retry", bundle: #bundle) }
    var removeLabel: String { String(localized: "community.comments.remove", bundle: #bundle) }
    var failedText: String { String(localized: "community.comments.failed", bundle: #bundle) }
    var sendingText: String { String(localized: "community.comments.sending", bundle: #bundle) }
    var offlineText: String { String(localized: "community.comments.offline", bundle: #bundle) }
    var deleteTitle: String { String(localized: "community.comments.deleteTitle", bundle: #bundle) }
    var deleteLabel: String { String(localized: "community.comments.delete", bundle: #bundle) }
    var cancelLabel: String { String(localized: "community.comments.cancel", bundle: #bundle) }
    var okLabel: String { String(localized: "community.comments.ok", bundle: #bundle) }

    var replyingToText: String? {
        replyTarget.map { String(localized: "community.comments.replyingTo \($0.name)", bundle: #bundle) }
    }

    /// "120 left" once the person is close to the limit; nil before that.
    var remainingText: String? {
        let remaining = Self.characterLimit - draft.count
        guard remaining <= 50 else { return nil }
        return String(localized: "community.comments.remaining \(remaining)", bundle: #bundle)
    }

    var isOffline: Bool { network.isOffline }

    /// Send needs words, at most 500 characters, and a connection.
    var canSend: Bool {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !text.isEmpty && draft.count <= Self.characterLimit && !network.isOffline
    }

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
            async let post = feed.post(id: runID)
            async let page = feed.comments(for: runID, after: nil)
            async let likes = feed.likes()
            let (run, firstPage) = try await (post, page)
            postOwnerID = run.runnerID
            likedComments = Set(((try? await likes) ?? []).compactMap { target in
                if case .comment(let id) = target { id } else { nil }
            })
            comments = firstPage.items
            nextCursor = firstPage.nextCursor
            await loadAuthors(for: comments)
            publish(hasMore: nextCursor != nil)
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

    /// Called when the last comment scrolls into view.
    func loadMoreIfNeeded(after row: CommentRowData) async {
        guard case .loaded(let content, _) = state, content.hasMore, !isLoadingMore,
              content.rows.last?.id == row.id, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await feed.comments(for: runID, after: cursor)
            comments += page.items.filter { new in !comments.contains { $0.id == new.id } }
            nextCursor = page.nextCursor
            await loadAuthors(for: page.items)
            publish(hasMore: nextCursor != nil)
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message   // a failed next page keeps what is on screen
        }
    }

    private func loadAuthors(for items: [Comment]) async {
        for id in Set(items.map(\.authorID)) where authors[id] == nil {
            authors[id] = try? await profiles.profile(id: id)
        }
    }

    /// Turns the loaded comments into rows. The repository keeps a reply after its parent, so the order is the thread.
    private func publish(hasMore: Bool) {
        let rows = comments.map(row(for:))
        state = rows.isEmpty && pending.isEmpty ? .empty : .loaded(CommentsContent(rows: rows, hasMore: hasMore))
    }

    private func row(for comment: Comment) -> CommentRowData {
        let author = authors[comment.authorID]
        return CommentRowData(
            id: comment.id.rawValue, authorName: author?.displayName ?? "", username: "@\(author?.username ?? "")",
            text: comment.text, relativeTimeText: relativeText(since: comment.createdAt),
            likeCount: comment.likeCount, isLiked: likedComments.contains(comment.id), depth: depth(of: comment),
            isDeleted: comment.deletedAt != nil, canDelete: canDelete(comment))
    }

    /// The author may delete their own comment; the owner of the post may delete any comment on it.
    private func canDelete(_ comment: Comment) -> Bool {
        guard comment.deletedAt == nil, let userID = session.currentUser?.id else { return false }
        return comment.authorID == userID || postOwnerID == userID
    }

    private func depth(of comment: Comment) -> Int {
        var depth = 0
        var parent = comment.parentID
        while let id = parent, depth < CommentRowData.maxVisibleDepth {
            depth += 1
            parent = comments.first { $0.id == id }?.parentID
        }
        return depth
    }

    /// "2d", "5h", "12m": how long ago, never a clock time.
    func relativeText(since date: Date) -> String {
        let seconds = max(0, now().timeIntervalSince(date))
        return Duration.seconds(seconds).formatted(
            .units(allowed: [.days, .hours, .minutes], width: .narrow, maximumUnitCount: 1))
    }

    // MARK: Writing

    func replyTapped(_ rowID: String) {
        guard let comment = comments.first(where: { $0.id.rawValue == rowID }), comment.deletedAt == nil else { return }
        replyTarget = (comment.id, authors[comment.authorID]?.displayName ?? "")
    }

    func cancelReply() { replyTarget = nil }

    /// Shows the comment at once, then saves it. If saving fails it stays, marked as failed, with Retry.
    func sendTapped() async {
        guard canSend else { return }
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = PendingComment(id: "pending-\(makeID())", text: text, parentID: replyTarget?.id, phase: .sending)
        pending.append(item)
        draft = ""
        replyTarget = nil
        publish(hasMore: nextCursor != nil)
        await save(item)
    }

    func retryTapped(_ id: String) async {
        guard let index = pending.firstIndex(where: { $0.id == id }), pending[index].phase == .failed else { return }
        pending[index].phase = .sending
        await save(pending[index])
    }

    func removePending(_ id: String) { pending.removeAll { $0.id == id } }

    private func save(_ item: PendingComment) async {
        do {
            let created = try await feed.addComment(to: runID, text: item.text, replyingTo: item.parentID)
            pending.removeAll { $0.id == item.id }
            if let user = session.currentUser { authors[user.id] = user }
            comments.append(created)
            publish(hasMore: nextCursor != nil)
        } catch {
            mark(item.id, as: .failed)   // a cancelled or failed save stays on screen with Retry
        }
    }

    private func mark(_ id: String, as phase: PendingComment.Phase) {
        if let index = pending.firstIndex(where: { $0.id == id }) { pending[index].phase = phase }
    }

    // MARK: Likes, delete, report

    /// Optimistic: the heart changes at once; if saving fails it goes back and a notice appears.
    func likeTapped(_ rowID: String) async {
        let id = CommentID(rowID)
        guard let index = comments.firstIndex(where: { $0.id == id }) else { return }
        let wasLiked = likedComments.contains(id)
        setLiked(!wasLiked, at: index)
        do {
            if wasLiked { try await feed.unlike(.comment(id)) } else { try await feed.like(.comment(id)) }
            if !wasLiked { likeCount += 1 }
        } catch {
            if let back = comments.firstIndex(where: { $0.id == id }) { setLiked(wasLiked, at: back) }
            if !(error is CancellationError) {
                notice = String(localized: "community.comments.likeFailed", bundle: #bundle)
            }
        }
    }

    private func setLiked(_ liked: Bool, at index: Int) {
        let id = comments[index].id
        guard likedComments.contains(id) != liked else { return }
        if liked { likedComments.insert(id) } else { likedComments.remove(id) }
        comments[index].likeCount = max(0, comments[index].likeCount + (liked ? 1 : -1))
        publish(hasMore: nextCursor != nil)
    }

    func deleteTapped(_ rowID: String) { deletingID = CommentID(rowID) }
    func cancelDelete() { deletingID = nil }

    /// Deleting keeps the comment in the thread as "[deleted]", so replies below it still make sense.
    func confirmDelete() async {
        guard let id = deletingID else { return }
        deletingID = nil
        do {
            try await feed.deleteComment(id)
            if let index = comments.firstIndex(where: { $0.id == id }) { comments[index].deletedAt = now() }
            publish(hasMore: nextCursor != nil)
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    func reportTapped(_ rowID: String) { onReport(CommentID(rowID)) }
}
