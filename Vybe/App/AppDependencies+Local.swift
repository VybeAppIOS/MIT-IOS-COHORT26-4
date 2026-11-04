import Core
import Foundation
import LocalData
import Models

extension AppDependencies {
    /// The dependencies the running app uses, built once in `RootView`: the bundled team content, and the person's
    /// own files in Application Support. Phase 2 swaps these lines for the backend (one place, no screen changes).
    @MainActor
    static func local() -> AppDependencies {
        let loader = ContentLoader.bundled
        let content = ContentStore(loader: loader)
        let library = LocalLibraryRepository()
        let now: @Sendable () -> Date = { Date() }
        return AppDependencies(
            hangouts: LocalHangoutRepository(content: content),
            places: LocalPlaceRepository(content: content),
            library: library,
            profiles: LocalProfileRepository(now: now),
            search: LocalSearchRepository(content: content),
            photos: LocalPhotoStore(loader: loader),
            session: SessionStore(settings: AppSettings()),
            libraryStore: LibraryStore(repository: library, now: now),
            router: Router(),
            flags: .current,
            now: now)
    }
}
