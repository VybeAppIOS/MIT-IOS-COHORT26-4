import Components
import Core
import Foundation
import Models
import Observation

/// One post in the profile's grid: a cover photo or the route drawing, and the title. Never a time.
struct PostTileData: Identifiable, Equatable {
    let id: RunID
    let title: String
    let coverURL: URL?
    let routePoints: [Coordinate]
    /// How many Spots the post visited (a count, never a time).
    let spotCount: Int
}

/// The view-ready values of the profile screen (never a raw model).
struct OtherProfileContent: Equatable {
    var header: ProfileHeaderData
    var relationship: ProfileRelationship
    var tiles: [PostTileData]
    var mutualFriendCount: Int
    var canMessage: Bool
}

/// Other person's profile (SC-PR3): the header with the right relationship button, the posts this person lets you
/// see, mutual friends, and Message, Report and Block. A private profile shows only the name, photo and "Friends only".
@MainActor @Observable
final class OtherProfileViewModel {
    static let postPagesToRead = 3

    private(set) var state: LoadState<OtherProfileContent> = .loading
    /// True while the "Remove friend?" question is open.
    var isConfirmingRemove = false
    /// A short message to show once. The View clears it.
    var notice: String?

    private let userID: UserID
    private let profiles: any ProfileRepository
    private let friends: any FriendsRepository
    private let feed: any FeedRepository
    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let session: SessionStore
    private let router: Router
    private var profile: UserProfile?
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        userID: UserID, profiles: any ProfileRepository, friends: any FriendsRepository, feed: any FeedRepository,
        places: any PlaceRepository, photos: any PhotoStore, session: SessionStore, router: Router
    ) {
        self.userID = userID
        self.profiles = profiles
        self.friends = friends
        self.feed = feed
        self.places = places
        self.photos = photos
        self.session = session
        self.router = router
    }

    // MARK: Words

    var title: String { profile?.displayName ?? String(localized: "friends.profile.title", bundle: #bundle) }
    var unavailableMessage: String { String(localized: "friends.profile.unavailable", bundle: #bundle) }
    var postsTitle: String { String(localized: "friends.profile.posts", bundle: #bundle) }
    var noPostsText: String { String(localized: "friends.profile.noPosts", bundle: #bundle) }
    var messageLabel: String { String(localized: "friends.profile.message", bundle: #bundle) }
    var moreLabel: String { String(localized: "friends.profile.more", bundle: #bundle) }
    var reportLabel: String { String(localized: "friends.profile.report", bundle: #bundle) }
    var blockLabel: String { String(localized: "friends.profile.block", bundle: #bundle) }
    var removeLabel: String { String(localized: "friends.profile.remove", bundle: #bundle) }
    var cancelLabel: String { String(localized: "friends.profile.cancel", bundle: #bundle) }
    var okLabel: String { String(localized: "friends.profile.ok", bundle: #bundle) }
    var removeTitle: String {
        String(localized: "friends.profile.removeTitle \(profile?.displayName ?? "")", bundle: #bundle)
    }

    func mutualText(_ count: Int) -> String {
        String(localized: "friends.profile.mutual \(count)", bundle: #bundle)
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
        if session.isBlocked(userID) {
            // A blocked person is "Not available": no photo, no bio, no posts.
            state = .loaded(OtherProfileContent(
                header: ProfileHeaderData(name: unavailableMessage, username: ""), relationship: .blocked,
                tiles: [], mutualFriendCount: 0, canMessage: false))
            hasLoaded = true
            return
        }
        do {
            let person = try await profiles.profile(id: userID)
            profile = person
            async let friendList = friends.friends()
            async let requests = friends.requests()
            let (myFriends, pending) = try await (friendList, requests)
            let relationship = Self.relationship(
                for: person, myID: session.currentUser?.id, friends: myFriends, requests: pending)
            let gated = relationship == .privateGate || relationship == .blocked
            let tiles = gated ? [] : await postTiles()
            var mutual = 0
            if !gated && relationship != .own { mutual = (try? await friends.mutualFriends(with: userID))?.count ?? 0 }
            state = .loaded(OtherProfileContent(
                header: header(for: person, gated: gated, tiles: tiles),
                relationship: relationship, tiles: tiles, mutualFriendCount: mutual,
                canMessage: relationship == .friends))
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch AppError.notFound {
            state = .empty
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))   // only a first load can fail
            }
        }
    }

    /// How the person and you are connected, in the order that matters: yourself, a friend, a request either way,
    /// a private profile you cannot see yet, or a stranger you can add.
    static func relationship(
        for person: UserProfile, myID: UserID?, friends: [UserProfile], requests: FriendRequests
    ) -> ProfileRelationship {
        if person.id == myID { return .own }
        if friends.contains(where: { $0.id == person.id }) { return .friends }
        if requests.sent.contains(where: { $0.toID == person.id }) { return .requested }
        if (requests.received + requests.other).contains(where: { $0.fromID == person.id }) { return .respond }
        return person.isPrivate ? .privateGate : .addFriend
    }

    private func header(for person: UserProfile, gated: Bool, tiles: [PostTileData]) -> ProfileHeaderData {
        let isMe = person.id == session.currentUser?.id
        return ProfileHeaderData(
            name: person.displayName, username: "@\(person.username)", bio: gated ? nil : person.bio,
            bannerURL: gated ? nil : person.banner.flatMap { photos.url(for: $0) },
            avatarURL: person.photo.flatMap { photos.url(for: $0) }, isVerifiedVybe: person.username == "vybe",
            hangoutsDone: tiles.count, spotsVisited: tiles.map(\.spotCount).reduce(0, +),
            friendCount: isMe ? person.friendCount : nil)
    }

    /// This person's posts that you may see. The repository already hides what you must not see (blocked people,
    /// friends-only posts of non-friends); we read a few pages and keep this person's.
    private func postTiles() async -> [PostTileData] {
        var tiles: [PostTileData] = []
        var cursor: String?
        for _ in 0..<Self.postPagesToRead {
            guard let page = try? await feed.feed(after: cursor) else { break }
            for run in page.items where run.runnerID == userID && run.state == .posted {
                let cover = run.photos.first { $0.id == run.coverPhotoID } ?? run.photos.first
                let coverURL = cover.flatMap { photos.url(for: $0) }
                var points: [Coordinate] = []
                if coverURL == nil {
                    for visit in run.visits.sorted(by: { $0.order < $1.order }) {
                        if let place = try? await places.place(id: visit.placeID) { points.append(place.coordinate) }
                    }
                }
                tiles.append(PostTileData(
                    id: run.id, title: run.title ?? run.card.hangoutTitle, coverURL: coverURL, routePoints: points,
                    spotCount: run.visits.count))
            }
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return tiles
    }

    // MARK: Taps

    /// What the big button under the name does, depending on the relationship.
    func headerButtonTapped() async {
        guard case .loaded(let content, _) = state else { return }
        switch content.relationship {
        case .addFriend, .privateGate:
            await change(to: .requested, expecting: content.relationship) {
                _ = try await self.friends.sendRequest(to: self.userID)
            }
        case .requested:
            await change(to: .addFriend, expecting: content.relationship) {
                try await self.friends.cancelRequest(to: self.userID)
            }
        case .respond:
            await change(to: .friends, expecting: content.relationship) {
                try await self.friends.acceptRequest(from: self.userID)
            }
        case .friends: isConfirmingRemove = true
        case .own, .blocked: break
        }
    }

    /// Optimistic: the button changes at once; if the change fails it goes back and a message appears.
    private func change(
        to new: ProfileRelationship, expecting old: ProfileRelationship, _ action: () async throws -> Void
    ) async {
        setRelationship(new)
        do {
            try await action()
        } catch is CancellationError {
            setRelationship(old)
        } catch {
            setRelationship(old)
            notice = AppError(error).message
        }
    }

    private func setRelationship(_ relationship: ProfileRelationship) {
        guard case .loaded(var content, let stale) = state else { return }
        content.relationship = relationship
        content.canMessage = relationship == .friends
        state = .loaded(content, isStale: stale)
    }

    func confirmRemove() async {
        isConfirmingRemove = false
        await change(to: .addFriend, expecting: .friends) { try await self.friends.removeFriend(self.userID) }
    }

    func messageTapped() {
        guard let myID = session.currentUser?.id else { return }
        router.open(.conversation(.dm(myID, userID)))
    }

    func mutualFriendsTapped() { router.open(.mutualFriends(userID)) }
    func postTapped(_ id: RunID) { router.open(.post(id)) }
    func reportTapped() { router.present(.report(.user(userID))) }
    func blockTapped() { router.present(.blockConfirm(userID)) }
}
