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
        return AppDependencies(
            hangouts: hangouts,
            places: StubPlaceRepository(mode: mode),
            library: library,
            profiles: StubProfileRepository(mode: mode),
            search: StubSearchRepository(mode: mode),
            photos: StubPhotoStore(),
            session: session,
            libraryStore: libraryStore,
            liveStore: LiveHangoutStore(libraryStore: libraryStore, hangouts: hangouts, session: session,
                                        now: fixedNow),
            router: Router(),
            flags: .allOn,
            now: fixedNow)
    }
}
#endif
