import Foundation

/// Everything a feature's `Screens` may hand to a ViewModel (ADR 002). The App builds the real one once
/// (`AppDependencies.local()`); previews and tests use `AppDependencies.preview(_:)`. F-7 adds the social repositories.
public struct AppDependencies: Sendable {
    public let hangouts: any HangoutRepository
    public let places: any PlaceRepository
    public let library: any LibraryRepository
    public let profiles: any ProfileRepository
    public let search: any SearchRepository
    public let photos: any PhotoStore
    public let session: SessionStore
    public let libraryStore: LibraryStore
    public let router: Router
    public let flags: FeatureFlags
    public let now: @Sendable () -> Date

    public init(
        hangouts: any HangoutRepository, places: any PlaceRepository, library: any LibraryRepository,
        profiles: any ProfileRepository, search: any SearchRepository, photos: any PhotoStore,
        session: SessionStore, libraryStore: LibraryStore, router: Router, flags: FeatureFlags,
        now: @escaping @Sendable () -> Date
    ) {
        self.hangouts = hangouts
        self.places = places
        self.library = library
        self.profiles = profiles
        self.search = search
        self.photos = photos
        self.session = session
        self.libraryStore = libraryStore
        self.router = router
        self.flags = flags
        self.now = now
    }
}
