import Components
import Core
import Models

/// Turns posted runs into the cards the Feed and Trending show. Cards are built from the public post fields only:
/// never `RunTimes`, never a clock time (`docs/RISKS.md` 3).
@MainActor
struct PostCardMaker {
    /// The official Vybe account; its posts are Picks.
    static let vybeUsername = "vybe"

    let hangouts: any HangoutRepository
    let places: any PlaceRepository
    let photos: any PhotoStore
    let libraryStore: LibraryStore

    func cards(for runs: [HangoutRun], liked: Set<RunID>) async -> [PostCardData] {
        var result: [PostCardData] = []
        for run in runs {
            let cover = run.photos.first { $0.id == run.coverPhotoID } ?? run.photos.first
            let coverURL = cover.flatMap { photos.url(for: $0) }
            var points: [Coordinate] = []
            if coverURL == nil {
                for visit in run.visits.sorted(by: { $0.order < $1.order }) {
                    if let place = try? await places.place(id: visit.placeID) { points.append(place.coordinate) }
                }
            }
            let remixes = (try? await hangouts.stats(for: run.hangoutID))?.remixCount ?? 0
            result.append(PostCardData(
                run, coverURL: coverURL, avatarURL: run.card.runnerPhoto.flatMap { photos.url(for: $0) },
                routePoints: points, remixCount: remixes, isPick: run.card.runnerUsername == Self.vybeUsername,
                isLiked: liked.contains(run.id), isSaved: libraryStore.isSaved(run.hangoutID)))
        }
        return result
    }
}
