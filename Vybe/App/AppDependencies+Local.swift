import Core
import Foundation
import Models

extension AppDependencies {
    /// The dependencies the running app uses, built once in `RootView`.
    @MainActor
    static func local() -> AppDependencies {
        #if DEBUG
        // Until task F-8 adds the LocalData repositories (bundled JSON), the app runs on the stub repositories
        // with the EXAMPLE sample data. F-8 replaces these lines; no screen changes.
        let library = StubLibraryRepository(mode: .empty)
        let now: @Sendable () -> Date = { Date() }
        return AppDependencies(
            hangouts: StubHangoutRepository(),
            places: StubPlaceRepository(),
            library: library,
            profiles: StubProfileRepository(),
            search: StubSearchRepository(),
            photos: StubPhotoStore(),
            session: SessionStore(settings: AppSettings(), currentUser: SampleData.signedInUser),
            libraryStore: LibraryStore(repository: library, now: now),
            router: Router(),
            flags: .current,
            now: now)
        #else
        fatalError("Release builds need the LocalData repositories from task F-8.")
        #endif
    }
}
