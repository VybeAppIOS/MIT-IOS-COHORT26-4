import Core
import Foundation
import LocalData
import Models

extension AppDependencies {
    /// The dependencies the running app uses, built once in `RootView`: the bundled team content, and the person's
    /// own files in Application Support. Phase 2 swaps these lines for the backend (one place, no screen changes).
    @MainActor
    static func local() -> AppDependencies {
        #if DEBUG
        // Debug launch options (task X-14): reset or skip onboarding first, then maybe swap in the stubs.
        let options = LaunchOptions.current
        options.prepareState()
        if let mode = options.stubMode { return .preview(mode) }
        let location: any LocationService = options.simulateWalk ? SimulatedLocationService.examplePreview
            : LiveLocationService()
        #else
        let location: any LocationService = LiveLocationService()
        #endif
        let loader = ContentLoader.bundled
        let content = ContentStore(loader: loader)
        let library = LocalLibraryRepository()
        let now: @Sendable () -> Date = { Date() }
        let hangouts = LocalHangoutRepository(content: content)
        let session = SessionStore(settings: AppSettings())
        let libraryStore = LibraryStore(repository: library, now: now)
        let social = socialRepositories()
        let profiles = profileRepository(now: now)
        return AppDependencies(
            hangouts: hangouts,
            places: LocalPlaceRepository(content: content),
            library: library,
            profiles: profiles,
            search: LocalSearchRepository(content: content),
            photos: LocalPhotoStore(loader: loader),
            feed: social.feed,
            friends: social.friends,
            chat: social.chat,
            safety: social.safety,
            auth: social.auth,
            admin: social.admin,
            location: location,
            network: NetworkMonitor(),
            session: session,
            libraryStore: libraryStore,
            liveStore: LiveHangoutStore(libraryStore: libraryStore, hangouts: hangouts, session: session, now: now),
            badges: BadgeStore(chat: social.chat, feed: social.feed, friends: social.friends),
            router: Router(),
            flags: .current,
            now: now)
    }

    /// The person's own profile file. While the social data is stubbed (DEBUG only) "you" must carry the sample
    /// person's ID, or chat, comments and Group info cannot tell which messages and rights are yours.
    private static func profileRepository(now: @escaping @Sendable () -> Date) -> any ProfileRepository {
        #if DEBUG
        SampleIdentityProfileRepository(wrapping: LocalProfileRepository(now: now))
        #else
        LocalProfileRepository(now: now)
        #endif
    }

    /// Community, friends, chat, safety, sign-in and admin have no local data: until the backend (Phase 2) they run
    /// on the sample social data. The chat stub fakes an incoming message after 2 seconds.
    @MainActor
    private static func socialRepositories() -> SocialRepositories {
        #if DEBUG
        let store = SocialStubStore(simulateIncomingMessages: true)
        return SocialRepositories(
            feed: StubFeedRepository(store: store), friends: StubFriendsRepository(store: store),
            chat: StubChatRepository(store: store), safety: StubSafetyRepository(store: store),
            auth: StubAuthRepository(), admin: StubAdminRepository(store: store))
        #else
        fatalError("Release builds need the backend for community, chat and sign-in (Phase 2).")
        #endif
    }
}

/// The repositories that have no local data yet (see `socialRepositories()`).
private struct SocialRepositories {
    let feed: any FeedRepository
    let friends: any FriendsRepository
    let chat: any ChatRepository
    let safety: any SafetyRepository
    let auth: any AuthRepository
    let admin: any AdminRepository
}
