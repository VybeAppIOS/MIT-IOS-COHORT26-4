import Components
import Core
import Foundation
import Models

/// Everything the Remix tree shows, already as display text (never a raw model).
struct RemixTreeContent: Equatable, Sendable {
    /// One Remix: who made it, and its card.
    struct RemixItem: Equatable, Sendable, Identifiable {
        let card: HangoutCardData
        /// Nil when the remixer's profile could not be loaded: the card still shows, without a name.
        let authorName: String?
        /// "@riya"
        let authorUsername: String?
        let authorPhotoURL: URL?
        var id: HangoutID { card.id }
    }

    /// "Done 40× · Remixed 12×"; nil when both counts are zero (or the counts could not be loaded).
    let counterText: String?
    /// The Hangout this one was remixed from; nil when it is not a Remix (or the original is gone).
    let original: HangoutCardData?
    /// "Remixed from @riya"; nil when there is no original or its author is unknown.
    let originalCredit: String?
    let remixes: [RemixItem]
}

/// HD3: where a Hangout came from and the Remixes made from it. Opened from the "Remixed from @x" line on HD1.
@MainActor @Observable
final class RemixTreeViewModel {
    private(set) var state: LoadState<RemixTreeContent> = .loading
    let id: HangoutID

    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let profiles: any ProfileRepository
    private let photos: any PhotoStore
    private let library: LibraryStore
    private let session: SessionStore
    private let router: Router
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Take only what the screen needs, never `AppDependencies`.
    init(
        id: HangoutID, hangouts: any HangoutRepository, places: any PlaceRepository, profiles: any ProfileRepository,
        photos: any PhotoStore, library: LibraryStore, session: SessionStore, router: Router
    ) {
        self.id = id
        self.hangouts = hangouts
        self.places = places
        self.profiles = profiles
        self.photos = photos
        self.library = library
        self.session = session
        self.router = router
    }

    func load() async {
        guard !hasLoaded else { return }        // .task runs again whenever the screen reappears
        await fetch()
    }

    func reload() async { await fetch() }       // pull to refresh and the Retry button

    private func fetch() async {
        do {
            let hangout = try await hangouts.hangout(id: id)
            let remixList = try await hangouts.remixes(of: id)
            let stats = try? await hangouts.stats(for: id)          // extra: hide the counters if it fails
            let original = await originalCard(of: hangout)
            var items: [RemixTreeContent.RemixItem] = []
            for remix in remixList where !session.isBlocked(remix.authorID) {
                items.append(await item(for: remix))
            }
            state = .loaded(RemixTreeContent(
                counterText: stats.flatMap { Self.counterText(done: $0.doneCount, remixed: $0.remixCount) },
                original: original?.card, originalCredit: original?.credit, remixes: items))
            hasLoaded = true
        } catch is CancellationError {
            return                              // leaving the screen is not an error (ADR 005)
        } catch {
            let appError = AppError(error)
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else if appError == .notFound {
                state = .empty                            // "This Hangout is no longer available"
            } else {
                state = .failed(appError)                 // only a first load can fail
            }
        }
    }

    // MARK: Actions

    func hangoutTapped(_ hangoutID: HangoutID) { router.open(.hangout(hangoutID)) }

    // MARK: Building the content

    /// "Done 40× · Remixed 12×". The server already applies the rules (posted runs only, each person once,
    /// at least 70% of the Spots kept), so this only writes the numbers. A zero part is left out; nil when both are 0.
    static func counterText(done: Int, remixed: Int) -> String? {
        var parts: [String] = []
        if done > 0 { parts.append(RemixTreeText.done(done.formatted())) }
        if remixed > 0 { parts.append(RemixTreeText.remixed(remixed.formatted())) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The original's card and "Remixed from @x". Missing pieces only hide that part of the screen.
    private func originalCard(of hangout: Hangout) async -> (card: HangoutCardData, credit: String?)? {
        guard let originalID = hangout.remixedFromID,
              let original = try? await hangouts.hangout(id: originalID) else { return nil }
        let author = try? await profiles.profile(id: original.authorID)
        return (await card(for: original, authorName: author?.displayName),
                author.map { HangoutDetailText.remixedFrom($0.username) })
    }

    private func item(for remix: Hangout) async -> RemixTreeContent.RemixItem {
        let author = try? await profiles.profile(id: remix.authorID)
        return RemixTreeContent.RemixItem(
            card: await card(for: remix, authorName: nil), authorName: author?.displayName,
            authorUsername: author.map { "@\($0.username)" }, authorPhotoURL: author?.photo.flatMap(photos.url(for:)))
    }

    /// A compact card; the cover is the first Spot's first photo (the `HangoutCardData` rule).
    private func card(for hangout: Hangout, authorName: String?) async -> HangoutCardData {
        var coverURL: URL?
        if let first = hangout.spots.first, let place = try? await places.place(id: first.placeID) {
            coverURL = place.photos.first.flatMap(photos.url(for:))
        }
        return HangoutCardData(hangout, coverURL: coverURL, isSaved: library.isSaved(hangout.id),
                               authorName: authorName)
    }
}

/// The Remix tree's text, read from HangoutDetailFeature's own catalog (`bundle: #bundle`, task X-3).
enum RemixTreeText {
    static var title: String { String(localized: "hangoutDetail.remixTree.title", bundle: #bundle) }
    static var remixedFromHeader: String {
        String(localized: "hangoutDetail.remixTree.remixedFromHeader", bundle: #bundle)
    }
    static var remixesHeader: String { String(localized: "hangoutDetail.remixTree.remixesHeader", bundle: #bundle) }
    static var empty: String { String(localized: "hangoutDetail.remixTree.empty", bundle: #bundle) }

    /// "Done 40×"
    static func done(_ count: String) -> String {
        String(localized: "hangoutDetail.remixTree.done \(count)", bundle: #bundle)
    }

    /// "Remixed 12×"
    static func remixed(_ count: String) -> String {
        String(localized: "hangoutDetail.remixTree.remixed \(count)", bundle: #bundle)
    }
}
