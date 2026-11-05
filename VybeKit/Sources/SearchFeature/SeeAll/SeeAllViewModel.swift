import Components
import Core
import Design
import Foundation
import Models
import Observation

/// The view-ready values of the See all screen (never a raw model).
struct SeeAllContent: Equatable {
    var rows: [SearchRowData]
    var hasMore: Bool
}

/// See all (SC-S2): the whole list for one group. The route carries only the group, not what was typed, so this
/// lists everything in the group; it is paged 20 at a time as the last row comes into view.
@MainActor @Observable
final class SeeAllViewModel {
    static let pageSize = 20
    /// The launch area (Kothrud) for the Places list.
    static let area = "Kothrud"

    private(set) var state: LoadState<SeeAllContent> = .loading

    let kind: SearchKind
    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let friends: any FriendsRepository
    private let session: SessionStore
    private let router: Router
    private var all: [SearchRowData] = []
    private var shownCount = 0
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        kind: SearchKind, hangouts: any HangoutRepository, places: any PlaceRepository,
        friends: any FriendsRepository, session: SessionStore, router: Router
    ) {
        self.kind = kind
        self.hangouts = hangouts
        self.places = places
        self.friends = friends
        self.session = session
        self.router = router
    }

    var title: String {
        switch kind {
        case .hangouts: String(localized: "search.seeAll.hangouts", bundle: #bundle)
        case .places: String(localized: "search.seeAll.places", bundle: #bundle)
        case .people: String(localized: "search.seeAll.people", bundle: #bundle)
        }
    }

    var emptyMessage: String { String(localized: "search.seeAll.empty", bundle: #bundle) }

    // MARK: Loading

    /// Called by `.task`. Runs once; `.task` runs again whenever the screen reappears.
    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    /// Pull to refresh and the Retry button.
    func reload() async { await fetch() }

    private func fetch() async {
        do {
            all = try await loadAll()
            shownCount = min(Self.pageSize, all.count)
            publish()
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))   // only a first load can fail
            }
        }
    }

    private func loadAll() async throws -> [SearchRowData] {
        switch kind {
        case .hangouts:
            return try await hangouts.hangouts(near: nil, filters: HangoutFilters()).map {
                let card = HangoutCardData($0, coverURL: nil, isSaved: false)
                return SearchRowData(id: $0.id.rawValue, title: $0.title, subtitle: card.factsText,
                                     leading: .symbol("map"))
            }
        case .places:
            return try await places.places(in: Self.area).map {
                SearchRowData(
                    id: $0.id.rawValue, title: $0.name,
                    subtitle: [ComponentStrings.categoryName($0.category), $0.area].joined(separator: " · "),
                    leading: .symbol("mappin.and.ellipse"))
            }
        case .people:
            return try await friends.friends().filter { !session.isBlocked($0.id) }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                .map {
                    SearchRowData(id: $0.id.rawValue, title: $0.displayName, subtitle: "@\($0.username)",
                                  leading: .person(name: $0.displayName))
                }
        }
    }

    private func publish() {
        let rows = Array(all.prefix(shownCount))
        state = rows.isEmpty ? .empty : .loaded(SeeAllContent(rows: rows, hasMore: shownCount < all.count))
    }

    /// Called when a row scrolls into view: the last row shows the next page.
    func loadMoreIfNeeded(after row: SearchRowData) {
        guard case .loaded(let content, _) = state, content.hasMore, content.rows.last?.id == row.id else { return }
        shownCount = min(shownCount + Self.pageSize, all.count)
        publish()
    }

    // MARK: Taps

    func rowTapped(_ row: SearchRowData) {
        switch kind {
        case .hangouts: router.open(.hangout(HangoutID(row.id)))
        case .places: router.present(.spot(PlaceID(row.id)))
        case .people: router.open(.profile(UserID(row.id)))
        }
    }
}
