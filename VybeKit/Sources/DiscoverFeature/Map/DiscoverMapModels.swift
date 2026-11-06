import Components
import Core
import Foundation
import Models

/// One Hangout on the map: where its pin goes and what its pin and card show.
struct DiscoverPin: Equatable, Sendable, Identifiable {
    let id: HangoutID
    let title: String
    /// The first Spot's category: the pin's symbol when there is no photo.
    let category: PlaceCategory
    /// The first Spot's position (where the Hangout clusters with others when the map is zoomed out).
    let coordinate: Coordinate
    /// Every Spot's position in visiting order: the map draws them as numbered stops joined by a line, so a
    /// multi-Spot Hangout never looks like a single place.
    let route: [Coordinate]
    let photoURL: URL?
    let isPick: Bool
    /// The card shown when the pin is selected.
    let card: HangoutCardData
}

/// Everything the map shows once loaded.
struct DiscoverMapContent: Equatable, Sendable {
    let pins: [DiscoverPin]
    /// The Picks strip at the bottom.
    let picks: [HangoutCardData]
}

/// The choices above the Discover map.
extension DiscoverMapViewModel {
    /// The quick category chips above the map. "More filters" (SC-D3) has everything else.
    enum Chip: CaseIterable, Sendable {
        case food
        case outdoors
        case games

        var categories: Set<PlaceCategory> {
            switch self {
            case .food: [.cafe, .streetFood, .chaiTapri, .restaurant, .dessert, .juiceShakes]
            case .outdoors: [.parkGarden, .viewpointHill, .lakeDam, .fort, .trek, .waterfall]
            case .games: [.gamingArcade, .bowling, .goKarting, .trampoline, .escapeRoom, .boardGameCafe]
            }
        }

        var title: String {
            switch self {
            case .food: DiscoverMapText.chipFood
            case .outdoors: DiscoverMapText.chipOutdoors
            case .games: DiscoverMapText.chipGames
            }
        }
    }

    /// The one-choice row above the map: which Hangouts to show.
    enum Scope: CaseIterable, Sendable {
        case picks
        case publicAll
        case friends

        var title: String {
            switch self {
            case .picks: DiscoverMapText.scopePicks
            case .publicAll: DiscoverMapText.scopePublic
            case .friends: DiscoverMapText.scopeFriends
            }
        }
    }
}

/// The Discover map's text, read from DiscoverFeature's own catalog (`bundle: #bundle`, task X-3).
enum DiscoverMapText {
    static var chipFood: String { String(localized: "discover.map.chip.food", bundle: #bundle) }
    static var chipOutdoors: String { String(localized: "discover.map.chip.outdoors", bundle: #bundle) }
    static var chipGames: String { String(localized: "discover.map.chip.games", bundle: #bundle) }
    static var moreFilters: String { String(localized: "discover.map.moreFilters", bundle: #bundle) }
    static var filtersLabel: String { String(localized: "discover.map.filters.label", bundle: #bundle) }
    static var scopePicks: String { String(localized: "discover.map.scope.picks", bundle: #bundle) }
    static var scopePublic: String { String(localized: "discover.map.scope.public", bundle: #bundle) }
    static var scopeFriends: String { String(localized: "discover.map.scope.friends", bundle: #bundle) }
    static var emptyFriends: String { String(localized: "discover.map.empty.friends", bundle: #bundle) }
    static var empty: String { String(localized: "discover.map.empty", bundle: #bundle) }
    static var monsoon: String { String(localized: "discover.map.monsoon", bundle: #bundle) }
    static var picksHeader: String { String(localized: "discover.map.picksHeader", bundle: #bundle) }
}
