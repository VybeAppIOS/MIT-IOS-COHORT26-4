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
        return AppDependencies(
            hangouts: StubHangoutRepository(mode: mode),
            places: StubPlaceRepository(mode: mode),
            library: library,
            profiles: StubProfileRepository(mode: mode),
            search: StubSearchRepository(mode: mode),
            photos: StubPhotoStore(),
            session: SessionStore(settings: settings, currentUser: SampleData.signedInUser),
            libraryStore: LibraryStore(repository: library, now: fixedNow),
            router: Router(),
            flags: .allOn,
            now: fixedNow)
    }
}
#endif
