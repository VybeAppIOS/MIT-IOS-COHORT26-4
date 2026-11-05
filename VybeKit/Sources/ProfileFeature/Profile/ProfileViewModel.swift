import Components
import Core
import Foundation
import Models

/// The parts of My profile that come from a load: the header and my posted Hangouts.
struct ProfileContent: Equatable {
    var header: ProfileHeaderData
    var posts: [PostCardData]
}

/// One of the three library rows (Saved, Drafts, Ready to post), with its live count.
struct ProfileLibraryRow: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let count: Int
    let route: Route
}

/// PR1, My profile (the Profile tab's root): the header, my library rows, and my posted Hangouts.
/// The stats are counts only, never times (`docs/RISKS.md` 3).
@MainActor @Observable
final class ProfileViewModel {
    private(set) var state: LoadState<ProfileContent> = .loading
    /// The profile being edited in the Edit profile sheet (PR6); nil when the sheet is down.
    var editing: UserProfile?

    private let profiles: any ProfileRepository
    private let auth: any AuthRepository
    private let feed: any FeedRepository
    private let photos: any PhotoStore
    private let session: SessionStore
    private let libraryStore: LibraryStore
    private let router: Router
    private var hasLoaded = false
    /// The profile from the last load, used to start Edit profile.
    private var loadedProfile: UserProfile?
    /// The feed is paged; reading my own posts stops after this many pages.
    static let maxPages = 20

    /// Cheap: nothing loads here (ADR 005).
    init(
        profiles: any ProfileRepository, auth: any AuthRepository, feed: any FeedRepository, photos: any PhotoStore,
        session: SessionStore, libraryStore: LibraryStore, router: Router
    ) {
        self.profiles = profiles
        self.auth = auth
        self.feed = feed
        self.photos = photos
        self.session = session
        self.libraryStore = libraryStore
        self.router = router
    }

    // MARK: What the screen shows

    var title: String { String(localized: "profile.profile.title", bundle: #bundle) }
    var settingsLabel: String { String(localized: "profile.profile.settings", bundle: #bundle) }
    var postsHeader: String { String(localized: "profile.profile.posts", bundle: #bundle) }
    var emptyPosts: String { String(localized: "profile.profile.posts.empty", bundle: #bundle) }

    /// Read from the shared library, so the numbers change as soon as something is saved, drafted or finished.
    var libraryRows: [ProfileLibraryRow] {
        [ProfileLibraryRow(id: "saved", title: String(localized: "profile.profile.saved", bundle: #bundle),
                           systemImage: "bookmark", count: libraryStore.library.saves.count, route: .saved),
         ProfileLibraryRow(id: "drafts", title: String(localized: "profile.profile.drafts", bundle: #bundle),
                           systemImage: "pencil", count: libraryStore.drafts.count, route: .drafts),
         ProfileLibraryRow(id: "ready", title: String(localized: "profile.profile.ready", bundle: #bundle),
                           systemImage: "paperplane", count: libraryStore.finishedRuns.count, route: .readyToPost)]
    }

    // MARK: Loading

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        do {
            await libraryStore.ensureLoaded()
            let mine = try await profiles.currentProfile()
            loadedProfile = mine
            let posts = try await myPosts(mine.id)
            state = .loaded(ProfileContent(header: header(for: mine), posts: posts.map(card)))
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))
            }
        }
    }

    /// My posted runs from the feed (every page), newest first.
    private func myPosts(_ mine: UserID) async throws -> [HangoutRun] {
        var found: [HangoutRun] = []
        var cursor: String?
        for _ in 0..<Self.maxPages {
            let page = try await feed.feed(after: cursor)
            found += page.items.filter { $0.runnerID == mine }
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return found.sorted { ($0.postedAt ?? .distantPast) > ($1.postedAt ?? .distantPast) }
    }

    /// Stats are counts from my own runs: Hangouts done (ended, scheduled or posted) and Spots visited in them.
    private func header(for mine: UserProfile) -> ProfileHeaderData {
        let doneRuns = libraryStore.library.runs.filter { $0.state != .live }
        return ProfileHeaderData(
            name: mine.displayName, username: "@\(mine.username)", bio: mine.bio,
            bannerURL: mine.banner.flatMap { photos.url(for: $0) },
            avatarURL: mine.photo.flatMap { photos.url(for: $0) },
            hangoutsDone: doneRuns.count, spotsVisited: doneRuns.reduce(0) { $0 + $1.visits.count },
            friendCount: mine.friendCount)
    }

    private func card(_ run: HangoutRun) -> PostCardData {
        let cover = run.photos.first { $0.id == run.coverPhotoID } ?? run.photos.first
        return PostCardData(run, coverURL: cover.flatMap { photos.url(for: $0) }, avatarURL: nil, routePoints: [],
                            remixCount: 0, isPick: false, isLiked: false, isSaved: false)
    }

    // MARK: What the person does

    func libraryRowTapped(_ row: ProfileLibraryRow) { router.open(row.route) }
    func settingsTapped() { router.open(.settings) }
    func editTapped() { editing = loadedProfile ?? session.currentUser }

    /// The Edit profile sheet's ViewModel, for the profile being edited.
    func makeEditViewModel(_ profile: UserProfile) -> EditProfileViewModel {
        EditProfileViewModel(profile: profile, profiles: profiles, auth: auth, session: session)
    }

    /// The sheet closed: show what was saved.
    func editingEnded() async { await reload() }
    func postTapped(_ id: RunID) { router.open(.post(id)) }
}
