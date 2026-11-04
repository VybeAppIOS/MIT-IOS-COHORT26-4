import Foundation

/// Everything a feature's `Screens` may hand to a ViewModel (ADR 002). The App builds the real one once
/// (`AppDependencies.local()`); previews and tests use `AppDependencies.preview(_:)`.
/// The social repositories are stubs until the backend (Phase 2).
public struct AppDependencies: Sendable {
    public let hangouts: any HangoutRepository
    public let places: any PlaceRepository
    public let library: any LibraryRepository
    public let profiles: any ProfileRepository
    public let search: any SearchRepository
    public let photos: any PhotoStore
    public let feed: any FeedRepository
    public let friends: any FriendsRepository
    public let chat: any ChatRepository
    public let safety: any SafetyRepository
    public let auth: any AuthRepository
    public let admin: any AdminRepository
    public let location: any LocationService
    public let session: SessionStore
    public let libraryStore: LibraryStore
    public let liveStore: LiveHangoutStore
    public let badges: BadgeStore
    public let router: Router
    public let flags: FeatureFlags
    public let now: @Sendable () -> Date

    public init(
        hangouts: any HangoutRepository, places: any PlaceRepository, library: any LibraryRepository,
        profiles: any ProfileRepository, search: any SearchRepository, photos: any PhotoStore,
        feed: any FeedRepository, friends: any FriendsRepository, chat: any ChatRepository,
        safety: any SafetyRepository, auth: any AuthRepository, admin: any AdminRepository,
        location: any LocationService,
        session: SessionStore, libraryStore: LibraryStore, liveStore: LiveHangoutStore, badges: BadgeStore,
        router: Router, flags: FeatureFlags,
        now: @escaping @Sendable () -> Date
    ) {
        self.hangouts = hangouts
        self.places = places
        self.library = library
        self.profiles = profiles
        self.search = search
        self.photos = photos
        self.feed = feed
        self.friends = friends
        self.chat = chat
        self.safety = safety
        self.auth = auth
        self.admin = admin
        self.location = location
        self.session = session
        self.libraryStore = libraryStore
        self.liveStore = liveStore
        self.badges = badges
        self.router = router
        self.flags = flags
        self.now = now
    }
}
