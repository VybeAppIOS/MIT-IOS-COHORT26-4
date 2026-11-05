import Components
import Core
import Design
import Foundation
import Models
import Observation

/// One result line, ready to draw.
struct SearchRowData: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
}

/// A group of results under one header.
struct SearchGroup: Identifiable, Equatable {
    enum Kind: Equatable {
        case saved
        case hangouts
        case places
        case people
    }

    let kind: Kind
    let title: String
    let rows: [SearchRowData]
    /// More results than shown: the header offers "See all".
    let hasMore: Bool

    var id: String { title }
}

/// What the screen shows: Picks and recent searches before anything is typed, or grouped results.
enum SearchContent: Equatable {
    case idle(suggestions: [SearchRowData], recents: [String])
    case results([SearchGroup])
}

/// Search (SC-S1): results grouped Hangouts, Places and People. Which group comes first depends on the tab the
/// person came from, read when a query runs. Typing is debounced; blocked people never appear.
/// Recent searches are kept in settings through the session.
@MainActor @Observable
final class SearchViewModel {
    static let rowsPerGroup = 3
    static let recentLimit = 5

    private(set) var state: LoadState<SearchContent> = .loading
    var query = ""

    private let search: any SearchRepository
    private let hangouts: any HangoutRepository
    private let libraryStore: LibraryStore
    private let session: SessionStore
    private let router: Router
    private let debounce: Duration
    private var picks: [Hangout] = []
    private var shown: SearchResults = SearchResults()

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(
        search: any SearchRepository, hangouts: any HangoutRepository, libraryStore: LibraryStore,
        session: SessionStore, router: Router, debounce: Duration = .milliseconds(250)
    ) {
        self.search = search
        self.hangouts = hangouts
        self.libraryStore = libraryStore
        self.session = session
        self.router = router
        self.debounce = debounce
    }

    // MARK: Words

    var title: String { String(localized: "search.title", bundle: #bundle) }
    var prompt: String { String(localized: "search.prompt", bundle: #bundle) }
    var suggestionsTitle: String { String(localized: "search.suggestions", bundle: #bundle) }
    var recentsTitle: String { String(localized: "search.recents", bundle: #bundle) }
    var seeAllLabel: String { String(localized: "search.seeAll", bundle: #bundle) }
    var noResultsText: String { String(localized: "search.noResults", bundle: #bundle) }
    var suggestPlaceLabel: String { String(localized: "search.suggestPlace", bundle: #bundle) }

    // MARK: Loading

    /// Called by `.task` when the screen appears: the Picks to suggest before anything is typed.
    func load() async {
        do {
            picks = try await hangouts.picks()
            if query.trimmingCharacters(in: .whitespaces).isEmpty { showIdle() }
        } catch is CancellationError {
            return
        } catch {
            if query.trimmingCharacters(in: .whitespaces).isEmpty { state = .failed(AppError(error)) }
        }
    }

    private func showIdle() {
        let suggestions = picks.prefix(Self.rowsPerGroup).map { row(for: $0) }
        state = .loaded(.idle(suggestions: suggestions, recents: session.recentSearches))
    }

    // MARK: Searching

    /// Called by `.task(id: query)`: each new letter cancels the one before, so only the last pause really searches.
    func queryChanged() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showIdle()
            return
        }
        do {
            try await Task.sleep(for: debounce)
            let found = try await search.search(text: text, scope: Set(SearchKind.allCases))
            shown = SearchResults(
                hangouts: found.hangouts, places: found.places,
                people: found.people.filter { !session.isBlocked($0.id) })
            await libraryStore.ensureLoaded()
            let groups = makeGroups(from: shown, previousTab: router.lastNonSearchTab)
            state = groups.isEmpty ? .empty : .loaded(.results(groups))
            remember(text)
        } catch is CancellationError {
            return   // a newer query took over
        } catch {
            if case .loaded = state { return }   // a failed search keeps what is on screen
            state = .failed(AppError(error))
        }
    }

    /// Retry after an error.
    func retry() async {
        if query.trimmingCharacters(in: .whitespaces).isEmpty { await load() } else { await queryChanged() }
    }

    private func remember(_ text: String) {
        var recents = session.recentSearches
        recents.removeAll { $0.caseInsensitiveCompare(text) == .orderedSame }
        recents.insert(text, at: 0)
        session.recentSearches = Array(recents.prefix(Self.recentLimit))
    }

    // MARK: Grouping

    /// The group order depends on the tab the person came from: Discover, Hangouts first; Community, People first;
    /// Profile, their own Saved Hangouts first.
    func makeGroups(from results: SearchResults, previousTab: AppTab) -> [SearchGroup] {
        let isFromProfile = previousTab == .profile
        let saved = isFromProfile ? results.hangouts.filter { libraryStore.isSaved($0.id) } : []
        let rest = isFromProfile ? results.hangouts.filter { !libraryStore.isSaved($0.id) } : results.hangouts
        let hangoutGroup = group(.hangouts, rest.map(row(for:)))
        let placeGroup = group(.places, results.places.map(row(for:)))
        let peopleGroup = group(.people, results.people.map(row(for:)))
        let savedGroup = group(.saved, saved.map(row(for:)))
        let order: [SearchGroup?]
        switch previousTab {
        case .community: order = [peopleGroup, hangoutGroup, placeGroup]
        case .profile: order = [savedGroup, hangoutGroup, placeGroup, peopleGroup]
        default: order = [hangoutGroup, placeGroup, peopleGroup]
        }
        return order.compactMap { $0 }
    }

    private func group(_ kind: SearchGroup.Kind, _ rows: [SearchRowData]) -> SearchGroup? {
        guard !rows.isEmpty else { return nil }
        let title: String
        switch kind {
        case .saved: title = String(localized: "search.group.saved", bundle: #bundle)
        case .hangouts: title = String(localized: "search.group.hangouts", bundle: #bundle)
        case .places: title = String(localized: "search.group.places", bundle: #bundle)
        case .people: title = String(localized: "search.group.people", bundle: #bundle)
        }
        return SearchGroup(
            kind: kind, title: title, rows: Array(rows.prefix(Self.rowsPerGroup)),
            hasMore: rows.count > Self.rowsPerGroup)
    }

    private func row(for hangout: Hangout) -> SearchRowData {
        let card = HangoutCardData(hangout, coverURL: nil, isSaved: libraryStore.isSaved(hangout.id))
        return SearchRowData(id: hangout.id.rawValue, title: hangout.title, subtitle: card.factsText)
    }

    private func row(for place: Place) -> SearchRowData {
        SearchRowData(
            id: place.id.rawValue, title: place.name,
            subtitle: [ComponentStrings.categoryName(place.category), place.area].joined(separator: " · "))
    }

    private func row(for person: UserProfile) -> SearchRowData {
        SearchRowData(id: person.id.rawValue, title: person.displayName, subtitle: "@\(person.username)")
    }

    // MARK: Taps

    /// A row opens its Hangout, Place or person. Hangouts and people push; a Place opens its sheet.
    func rowTapped(_ row: SearchRowData, in kind: SearchGroup.Kind) {
        switch kind {
        case .hangouts, .saved: router.open(.hangout(HangoutID(row.id)))
        case .places: router.present(.spot(PlaceID(row.id)))
        case .people: router.open(.profile(UserID(row.id)))
        }
    }

    func suggestionTapped(_ row: SearchRowData) { router.open(.hangout(HangoutID(row.id))) }
    func recentTapped(_ text: String) { query = text }
    func clearRecents() {
        session.recentSearches = []
        showIdle()
    }

    func seeAllTapped(_ kind: SearchGroup.Kind) {
        switch kind {
        case .hangouts, .saved: router.open(.searchSeeAll(.hangouts))
        case .places: router.open(.searchSeeAll(.places))
        case .people: router.open(.searchSeeAll(.people))
        }
    }

    func suggestPlaceTapped() { router.present(.suggestPlace) }
}
