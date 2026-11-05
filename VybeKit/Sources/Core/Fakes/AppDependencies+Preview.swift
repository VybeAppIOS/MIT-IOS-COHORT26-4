#if DEBUG
import Foundation
import Models

public extension AppDependencies {
    /// Stub dependencies for previews and ViewModel tests. Every repository behaves as `mode` says;
    /// the session is signed in as `SampleData.signedInUser` with onboarding done. Settings live in a throwaway store.
    @MainActor
    static func preview(_ mode: StubMode = .loaded) -> AppDependencies {
        let settings = AppSettings(suiteName: "vybe.preview.\(UUID().uuidString)")
        settings.onboardingDone = true
        let library = StubLibraryRepository(mode: mode)
        let fixedNow: @Sendable () -> Date = { SampleData.day }
        let hangouts = StubHangoutRepository(mode: mode)
        let session = SessionStore(settings: settings, currentUser: SampleData.signedInUser)
        let libraryStore = LibraryStore(repository: library, now: fixedNow)
        let social = SocialStubStore()
        let feed = StubFeedRepository(mode: mode, store: social)
        let friends = StubFriendsRepository(mode: mode, store: social)
        let chat = StubChatRepository(mode: mode, store: social)
        return AppDependencies(
            hangouts: hangouts,
            places: StubPlaceRepository(mode: mode),
            library: library,
            profiles: StubProfileRepository(mode: mode, people: SampleData.people + SampleSocialData.people),
            search: StubSearchRepository(mode: mode),
            photos: StubPhotoStore(),
            feed: feed,
            friends: friends,
            chat: chat,
            safety: StubSafetyRepository(mode: mode, store: social),
            auth: StubAuthRepository(mode: mode),
            admin: StubAdminRepository(mode: mode, store: social),
            location: SimulatedLocationService.examplePreview,
            network: NetworkMonitor(isOffline: false),
            session: session,
            libraryStore: libraryStore,
            liveStore: LiveHangoutStore(libraryStore: libraryStore, hangouts: hangouts, session: session,
                                        now: fixedNow),
            badges: BadgeStore(chat: chat, feed: feed, friends: friends),
            router: Router(),
            flags: .allOn,
            now: fixedNow)
    }
}
#endif
