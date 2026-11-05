import Foundation
import Models

// The choices the filters sheet (D3) offers, as data. The views only lay these out; they never list values
// themselves. Display names come from the String Catalog.

/// The time choices. `HangoutFilters` can only hold a maximum (`maxMinutes`), so "3 h or more" is applied by the
/// Discover ViewModel after the repository answers (Lohitaksh: a `minMinutes` in `HangoutFilters` would move it
/// to the repository and the server).
enum TimeChoice: CaseIterable, Sendable {
    case any
    case upToOneHour
    case upToTwoHours
    case threeHoursOrMore

    /// Sent to the repository as `HangoutFilters.maxMinutes`.
    var maxMinutes: Int? {
        switch self {
        case .upToOneHour: 60
        case .upToTwoHours: 120
        case .any, .threeHoursOrMore: nil
        }
    }

    /// Applied by the ViewModel: Hangouts shorter than this are left out.
    var minMinutes: Int? { self == .threeHoursOrMore ? 180 : nil }

    var title: String {
        switch self {
        case .any: FiltersText.timeAny
        case .upToOneHour: FiltersText.timeUpTo(Self.hours(1))
        case .upToTwoHours: FiltersText.timeUpTo(Self.hours(2))
        case .threeHoursOrMore: FiltersText.timeAtLeast(Self.hours(3))
        }
    }

    /// "1 hr", formatted by the system so the unit follows the person's language (never typed by hand).
    private static func hours(_ count: Int) -> String {
        Duration.seconds(count * 3_600).formatted(.units(allowed: [.hours], width: .abbreviated))
    }
}

/// The budget slider's range and step: ₹0 to ₹1,000 (task SC-D3). The full range means "any budget".
enum BudgetRange {
    static let lowest = 0
    static let highest = 1_000
    static let step = 50
}

/// The 30 interests on the "Find your Vybe" page. Each one is a filter value:
/// - most are `PlaceCategory` cases from `Models`;
/// - eight have no `Models` type yet, so they are vibe tags (plain words in `HangoutFilters.vibeTags`), written
///   once here. Lohitaksh: Misal, Bakery, Drives, Pool, Bouldering, Rooftop, Midnight and Retro need a home in
///   `Models` (new `PlaceCategory` cases or a typed vibe-tag list). Until content uses these words, they match
///   nothing, so choosing one shows 0 results.
/// Two interests can share a value (Diner and Bistros are both restaurants; Gaming and Arcade are both arcades):
/// choosing one then lights up the other too, because they filter the same thing.
enum VybeInterest: String, CaseIterable, Sendable {
    // Food, Drinks & Cravings
    case cafe, chai, streetfood, desserts, misal, bakery, diner, bistros
    // Outdoors, Views & Nature
    case trek, sunsets, parks, drives, lakeside
    // Games, Sports & Action
    case gaming, arcade, pool, turf, boardgames, bouldering
    // Chill, Indie & Culture
    case books, study, museums, gigs, workshops, cinema
    // Retail & Vibe Tags
    case shopping, thrifting, rooftop, midnight, retro

    /// The Place categories this interest filters by.
    var categories: Set<PlaceCategory> {
        switch self {
        case .cafe: [.cafe]
        case .chai: [.chaiTapri]
        case .streetfood: [.streetFood]
        case .desserts: [.dessert]
        case .diner, .bistros: [.restaurant]
        case .trek: [.trek]
        case .sunsets: [.viewpointHill]
        case .parks: [.parkGarden]
        case .lakeside: [.lakeDam]
        case .gaming, .arcade: [.gamingArcade]
        case .turf: [.sportsTurf]
        case .boardgames: [.boardGameCafe]
        case .books: [.bookstoreLibrary]
        case .study: [.studyCafe]
        case .museums: [.museum]
        case .gigs: [.liveMusic]
        case .workshops: [.events]
        case .cinema: [.cinema]
        case .shopping: [.mall, .streetMarket]
        case .thrifting: [.thrift]
        case .misal, .bakery, .drives, .pool, .bouldering, .rooftop, .midnight, .retro: []
        }
    }

    /// The vibe tags this interest filters by (only for interests with no `Models` category yet).
    var vibeTags: Set<String> {
        switch self {
        case .misal, .bakery, .drives, .pool, .bouldering, .rooftop, .midnight, .retro: [rawValue]
        default: []
        }
    }

    var title: String { FiltersText.interest(self) }
}

/// The five sections of the "Find your Vybe" page, in order.
enum VybeSection: CaseIterable, Sendable {
    case food
    case outdoors
    case games
    case culture
    case retail

    var interests: [VybeInterest] {
        switch self {
        case .food: [.cafe, .chai, .streetfood, .desserts, .misal, .bakery, .diner, .bistros]
        case .outdoors: [.trek, .sunsets, .parks, .drives, .lakeside]
        case .games: [.gaming, .arcade, .pool, .turf, .boardgames, .bouldering]
        case .culture: [.books, .study, .museums, .gigs, .workshops, .cinema]
        case .retail: [.shopping, .thrifting, .rooftop, .midnight, .retro]
        }
    }

    var title: String {
        switch self {
        case .food: FiltersText.sectionFood
        case .outdoors: FiltersText.sectionOutdoors
        case .games: FiltersText.sectionGames
        case .culture: FiltersText.sectionCulture
        case .retail: FiltersText.sectionRetail
        }
    }
}

/// The main sheet's short vibe list: the vibe-tag interests from the "Retail & Vibe Tags" section.
enum MainSheetVibes {
    static let interests: [VybeInterest] = [.rooftop, .midnight, .retro]
}
