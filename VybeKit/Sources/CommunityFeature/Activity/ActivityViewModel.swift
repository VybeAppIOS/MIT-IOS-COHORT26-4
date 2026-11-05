import Core
import Foundation
import Models
import Observation

/// One line of the Activity list, ready to draw.
struct ActivityRowData: Identifiable, Equatable {
    enum Phase: Equatable {
        /// A friend request waiting for Accept or Ignore.
        case waiting
        /// The request was accepted just now.
        case accepted
        case plain
    }

    let id: String
    let actorName: String
    /// "Sanya liked your Hangout"
    let text: String
    let relativeText: String
    let systemImage: String
    let isUnread: Bool
    let phase: Phase
}

struct ActivitySection: Identifiable, Equatable {
    let id: String
    let title: String
    let rows: [ActivityRowData]
}

/// The view-ready values of the Activity screen (never a raw model).
struct ActivityContent: Equatable {
    var sections: [ActivitySection]
}

/// Activity (SC-CM5): likes, comments, replies, friend requests, new friends and Remix credits, grouped Today and
/// Earlier. A friend request is always at the top with Accept and Ignore.
@MainActor @Observable
final class ActivityViewModel {
    private(set) var state: LoadState<ActivityContent> = .loading
    /// A short message to show once. The View clears it.
    var notice: String?

    private let feed: any FeedRepository
    private let friends: any FriendsRepository
    private let profiles: any ProfileRepository
    private let badges: BadgeStore
    private let router: Router
    private let now: @Sendable () -> Date
    private var items: [Activity] = []
    private var names: [UserID: String] = [:]
    /// Requests the person ignored on this screen. Ignoring only hides the row; the other person is never told.
    private var ignored: Set<ActivityID> = []
    private var accepted: Set<ActivityID> = []
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        feed: any FeedRepository, friends: any FriendsRepository, profiles: any ProfileRepository,
        badges: BadgeStore, router: Router, now: @escaping @Sendable () -> Date
    ) {
        self.feed = feed
        self.friends = friends
        self.profiles = profiles
        self.badges = badges
        self.router = router
        self.now = now
    }

    // MARK: Words

    var title: String { String(localized: "community.activity.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "community.activity.empty", bundle: #bundle) }
    var acceptLabel: String { String(localized: "community.activity.accept", bundle: #bundle) }
    var ignoreLabel: String { String(localized: "community.activity.ignore", bundle: #bundle) }
    var unreadLabel: String { String(localized: "community.activity.unread", bundle: #bundle) }
    var okLabel: String { String(localized: "community.activity.ok", bundle: #bundle) }

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
            items = try await feed.activity(after: nil).items
            for id in Set(items.map(\.actorID)) where names[id] == nil {
                names[id] = (try? await profiles.profile(id: id))?.displayName
            }
            publish()
            hasLoaded = true
            await markRead()
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

    /// Opening the screen counts as seeing everything: the badge clears now. The dots stay until the next load, so
    /// the person can still see what is new.
    private func markRead() async {
        guard items.contains(where: { $0.readAt == nil }) else { return }
        try? await feed.markActivityRead()
        badges.activityWasSeen()
    }

    // MARK: Building rows

    private func publish() {
        let visible = items.filter { $0.kind != .unknown && !ignored.contains($0.id) }
        let sorted = visible.sorted {
            let leftRequest = $0.kind == .friendRequest, rightRequest = $1.kind == .friendRequest
            if leftRequest != rightRequest { return leftRequest }
            return $0.createdAt > $1.createdAt
        }
        let today = sorted.filter { isToday($0.createdAt) }
        let earlier = sorted.filter { !isToday($0.createdAt) }
        var sections: [ActivitySection] = []
        if !today.isEmpty {
            sections.append(ActivitySection(
                id: "today", title: String(localized: "community.activity.today", bundle: #bundle),
                rows: today.map(row(for:))))
        }
        if !earlier.isEmpty {
            sections.append(ActivitySection(
                id: "earlier", title: String(localized: "community.activity.earlier", bundle: #bundle),
                rows: earlier.map(row(for:))))
        }
        state = sections.isEmpty ? .empty : .loaded(ActivityContent(sections: sections))
    }

    private func isToday(_ date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar.isDate(date, inSameDayAs: now())
    }

    private func row(for item: Activity) -> ActivityRowData {
        let name = names[item.actorID] ?? ""
        var phase = ActivityRowData.Phase.plain
        if item.kind == .friendRequest { phase = accepted.contains(item.id) ? .accepted : .waiting }
        return ActivityRowData(
            id: item.id.rawValue, actorName: name, text: text(for: item.kind, name: name, accepted: phase == .accepted),
            relativeText: relativeText(since: item.createdAt), systemImage: symbol(for: item.kind),
            isUnread: item.readAt == nil, phase: phase)
    }

    private func text(for kind: ActivityKind, name: String, accepted: Bool) -> String {
        switch kind {
        case .like: String(localized: "community.activity.like \(name)", bundle: #bundle)
        case .comment: String(localized: "community.activity.comment \(name)", bundle: #bundle)
        case .reply: String(localized: "community.activity.reply \(name)", bundle: #bundle)
        case .friendRequest where accepted: String(localized: "community.activity.nowFriends \(name)", bundle: #bundle)
        case .friendRequest: String(localized: "community.activity.friendRequest \(name)", bundle: #bundle)
        case .friendAccepted: String(localized: "community.activity.friendAccepted \(name)", bundle: #bundle)
        case .remixCredit: String(localized: "community.activity.remixCredit \(name)", bundle: #bundle)
        case .unknown: ""
        }
    }

    private func symbol(for kind: ActivityKind) -> String {
        switch kind {
        case .like: "heart.fill"
        case .comment, .reply: "bubble.left.fill"
        case .friendRequest: "person.badge.plus"
        case .friendAccepted: "person.2.fill"
        case .remixCredit: "arrow.triangle.branch"
        case .unknown: "bell"
        }
    }

    /// "2d", "5h", "12m": how long ago, never a clock time.
    func relativeText(since date: Date) -> String {
        Duration.seconds(max(0, now().timeIntervalSince(date))).formatted(
            .units(allowed: [.days, .hours, .minutes], width: .narrow, maximumUnitCount: 1))
    }

    // MARK: Taps

    /// Opens the post, profile or Hangout the row is about.
    func rowTapped(_ rowID: String) {
        guard let item = items.first(where: { $0.id.rawValue == rowID }) else { return }
        switch item.target {
        case .run(let id): router.open(.post(id))
        case .hangout(let id): router.open(.hangout(id))
        case .user(let id): router.open(.profile(id))
        // A comment or reply row opens the post it is on; only an older row without a post opens the commenter.
        case .comment:
            if let runID = item.runID { router.open(.post(runID)) } else { router.open(.profile(item.actorID)) }
        }
    }

    /// Accepting makes you friends at once and refreshes the badge numbers.
    func acceptTapped(_ rowID: String) async {
        guard let item = items.first(where: { $0.id.rawValue == rowID && $0.kind == .friendRequest }) else { return }
        do {
            try await friends.acceptRequest(from: item.actorID)
            accepted.insert(item.id)
            publish()
            await badges.refresh()
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    /// Ignore hides the request here. Nobody is told, and it never shows as "declined".
    func ignoreTapped(_ rowID: String) {
        guard let item = items.first(where: { $0.id.rawValue == rowID && $0.kind == .friendRequest }) else { return }
        ignored.insert(item.id)
        publish()
    }
}
