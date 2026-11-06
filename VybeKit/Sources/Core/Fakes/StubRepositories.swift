#if DEBUG
import Foundation
import Models
import Synchronization

public struct StubHangoutRepository: HangoutRepository {
    public let mode: StubMode
    public let hangouts: [Hangout]

    public init(mode: StubMode = .loaded, hangouts: [Hangout] = SampleData.hangouts) {
        self.mode = mode
        self.hangouts = hangouts
    }

    public func hangout(id: HangoutID) async throws -> Hangout {
        let found = try await mode.run(loaded: hangouts.first { $0.id == id }, empty: nil)
        guard let found else { throw AppError.notFound }
        return found
    }

    public func hangouts(near center: Coordinate?, filters: HangoutFilters) async throws -> [Hangout] {
        try await mode.run(loaded: hangouts.filter { $0.status == .published }, empty: [])
    }

    public func picks() async throws -> [Hangout] {
        try await mode.run(loaded: hangouts.filter { $0.isPick && $0.status == .published }, empty: [])
    }

    public func remixes(of id: HangoutID) async throws -> [Hangout] {
        try await mode.run(loaded: hangouts.filter { $0.remixedFromID == id }, empty: [])
    }

    public func stats(for id: HangoutID) async throws -> HangoutStats {
        try await mode.run(loaded: HangoutStats(doneCount: 12, remixCount: 3),
                           empty: HangoutStats(doneCount: 0, remixCount: 0))
    }
}

public struct StubPlaceRepository: PlaceRepository {
    public let mode: StubMode
    public let places: [Place]

    public init(mode: StubMode = .loaded, places: [Place] = SampleData.places) {
        self.mode = mode
        self.places = places
    }

    public func place(id: PlaceID) async throws -> Place {
        let found = try await mode.run(loaded: places.first { $0.id == id }, empty: nil)
        guard let found else { throw AppError.notFound }
        return found
    }

    public func places(in area: String) async throws -> [Place] {
        try await mode.run(loaded: places.filter { $0.area.caseInsensitiveCompare(area) == .orderedSame }, empty: [])
    }

    public func spots(for hangout: Hangout) async throws -> [Place] {
        let ordered = hangout.spots.compactMap { spot in places.first { $0.id == spot.placeID } }
        return try await mode.run(loaded: ordered, empty: [])
    }
}

/// Keeps the library in memory. In `.loaded` mode it starts with one saved Hangout.
public actor StubLibraryRepository: LibraryRepository {
    public let mode: StubMode
    private var stored: Library

    public init(mode: StubMode = .loaded) {
        self.mode = mode
        stored = mode == .loaded
            ? Library(saves: [SavedHangout(hangoutID: SampleData.evening.id, savedAt: SampleData.day)])
            : Library()
    }

    public func load() async throws -> Library {
        try await mode.run(loaded: stored, empty: stored)
    }

    public func save(_ library: Library) async throws {
        _ = try await mode.run(loaded: true, empty: true)
        stored = library
    }
}

public struct StubProfileRepository: ProfileRepository {
    public let mode: StubMode
    public let people: [UserProfile]
    public let currentID: UserID

    public init(mode: StubMode = .loaded, people: [UserProfile] = SampleData.people,
                currentID: UserID = SampleData.signedInUser.id) {
        self.mode = mode
        self.people = people
        self.currentID = currentID
    }

    public func currentProfile() async throws -> UserProfile { try await profile(id: currentID) }

    public func profile(id: UserID) async throws -> UserProfile {
        let found = try await mode.run(loaded: people.first { $0.id == id }, empty: nil)
        guard let found else { throw AppError.notFound }
        return found
    }

    public func update(_ profile: UserProfile) async throws -> UserProfile {
        try await mode.run(loaded: profile, empty: profile)
    }
}

public struct StubSearchRepository: SearchRepository {
    public let mode: StubMode

    public init(mode: StubMode = .loaded) {
        self.mode = mode
    }

    public func search(text: String, scope: Set<SearchKind>) async throws -> SearchResults {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return try await mode.run(loaded: SearchResults(), empty: SearchResults()) }
        let found = SearchResults(
            hangouts: scope.contains(.hangouts)
                ? SampleData.hangouts.filter { $0.title.localizedStandardContains(query) } : [],
            places: scope.contains(.places)
                ? SampleData.places.filter { $0.name.localizedStandardContains(query) } : [],
            people: scope.contains(.people)
                ? SampleData.people.filter {
                    $0.displayName.localizedStandardContains(query) || $0.username.localizedStandardContains(query)
                }
                : [])
        return try await mode.run(loaded: found, empty: SearchResults())
    }
}

/// No images in previews: every photo shows its placeholder. `save` keeps nothing and returns a new `Photo` value,
/// numbered in order, so a preview can send a photo without touching the disk.
public final class StubPhotoStore: PhotoStore {
    private let saved = Mutex(0)

    public init() {}
    public func url(for photo: Photo) -> URL? { nil }

    public func save(_ photo: ProcessedPhoto) async throws -> Photo {
        let number = saved.withLock { count -> Int in
            count += 1
            return count
        }
        let size = photo.pixelSize
        return Photo(id: PhotoID("photo-stub-\(number)"), path: "stub-\(number).jpg",
                     width: size?.width ?? 0, height: size?.height ?? 0)
    }
}
#endif
