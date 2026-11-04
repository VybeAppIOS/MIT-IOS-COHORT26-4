#if DEBUG
import Foundation
import Models

// The promises every implementation keeps: the stubs now, LocalData (F-8) and Remote later.
// Plain throwing functions with no test framework, so any test target can call them.

public enum HangoutRepositoryContract {
    public static func verify(_ repository: any HangoutRepository) async throws {
        let all = try await repository.hangouts(near: nil, filters: HangoutFilters())
        for hangout in all {
            try require(hangout.status == .published, "hangouts() returned the draft \(hangout.id)")
            let again = try await repository.hangout(id: hangout.id)
            try require(again == hangout, "hangout(id:) differs from hangouts() for \(hangout.id)")
            let stats = try await repository.stats(for: hangout.id)
            try require(stats.doneCount >= 0 && stats.remixCount >= 0, "negative stats for \(hangout.id)")
            for remix in try await repository.remixes(of: hangout.id) {
                try require(remix.remixedFromID == hangout.id, "remixes(of:) returned \(remix.id), not a Remix")
            }
        }
        let allIDs = Set(all.map(\.id))
        for pick in try await repository.picks() {
            try require(pick.isPick, "picks() returned \(pick.id), which is not a Pick")
            try require(allIDs.contains(pick.id), "picks() returned \(pick.id), which hangouts() does not list")
        }
        try await requireNotFound("hangout(id:) with an unknown ID") {
            _ = try await repository.hangout(id: "contract-missing-hangout")
        }
    }
}

public enum PlaceRepositoryContract {
    /// `hangouts` are Hangouts whose Places this repository should know (pass what the Hangout repository returns).
    public static func verify(_ repository: any PlaceRepository, area: String, hangouts: [Hangout]) async throws {
        for place in try await repository.places(in: area) {
            try require(place.area.caseInsensitiveCompare(area) == .orderedSame, "places(in:) returned \(place.id)")
            try require(try await repository.place(id: place.id) == place, "place(id:) differs for \(place.id)")
        }
        for hangout in hangouts {
            let places = try await repository.spots(for: hangout)
            let expected = hangout.spots.map(\.placeID).filter { id in places.contains { $0.id == id } }
            try require(places.map(\.id) == expected, "spots(for:) is not in Spot order for \(hangout.id)")
        }
        try await requireNotFound("place(id:) with an unknown ID") {
            _ = try await repository.place(id: "contract-missing-place")
        }
    }
}

public enum LibraryRepositoryContract {
    /// Saves a changed library, reads it back, then restores what was there.
    public static func verify(_ repository: any LibraryRepository) async throws {
        let original = try await repository.load()
        var changed = original
        changed.saves.append(SavedHangout(hangoutID: "contract-saved", savedAt: Date(timeIntervalSince1970: 0)))
        try await repository.save(changed)
        try require(try await repository.load() == changed, "load() after save() did not return what was saved")
        try await repository.save(original)
        try require(try await repository.load() == original, "could not restore the original library")
    }
}

public enum ProfileRepositoryContract {
    public static func verify(_ repository: any ProfileRepository) async throws {
        let current = try await repository.currentProfile()
        let again = try await repository.profile(id: current.id)
        try require(again == current, "profile(id:) differs for the current user")
        try require(current.username == current.username.lowercased(), "usernames must be lower case")
        try await requireNotFound("profile(id:) with an unknown ID") {
            _ = try await repository.profile(id: "contract-missing-user")
        }
    }
}

public enum SearchRepositoryContract {
    /// `knownWord` must appear in at least one Hangout title the repository knows.
    public static func verify(_ repository: any SearchRepository, knownWord: String) async throws {
        let all = Set(SearchKind.allCases)
        try require(try await repository.search(text: "  ", scope: all).isEmpty, "blank text must give no results")
        let found = try await repository.search(text: knownWord, scope: [.hangouts])
        try require(!found.hangouts.isEmpty, "no Hangout found for \"\(knownWord)\"")
        try require(found.places.isEmpty && found.people.isEmpty, "results outside the requested scope")
        // A search may also match tags and areas (F-8 ranks title, then tag, then area), so only the best result
        // has to match by title: a title match always ranks first.
        let best = found.hangouts[0]
        try require(best.title.localizedStandardContains(knownWord), "\(best.id) is first but its title does not match")
    }
}
#endif
