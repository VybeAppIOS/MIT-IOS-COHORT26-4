import Foundation

/// The filters sheet's text, read from DiscoverFeature's own catalog (`bundle: #bundle`, task X-3).
enum FiltersText {
    static var title: String { String(localized: "discover.filters.title", bundle: #bundle) }
    static var budget: String { String(localized: "discover.filters.budget", bundle: #bundle) }
    static var budgetMinimum: String { String(localized: "discover.filters.budgetMinimum", bundle: #bundle) }
    static var budgetMaximum: String { String(localized: "discover.filters.budgetMaximum", bundle: #bundle) }
    static var time: String { String(localized: "discover.filters.time", bundle: #bundle) }
    static var timeAny: String { String(localized: "discover.filters.timeAny", bundle: #bundle) }
    static var categories: String { String(localized: "discover.filters.categories", bundle: #bundle) }
    static var vibes: String { String(localized: "discover.filters.vibes", bundle: #bundle) }
    static var goodForGroups: String { String(localized: "discover.filters.goodForGroups", bundle: #bundle) }
    /// "Find your Vybe". For now in Discover's catalog; switch to a shared app-name string in Design
    /// (`SharedStrings.appName`) once Lohitaksh adds it, so "Vybe" is spelled in one place.
    static var findYourVybe: String { String(localized: "discover.filters.findYourVybe", bundle: #bundle) }
    static var reset: String { String(localized: "discover.filters.reset", bundle: #bundle) }
    static var applyCounting: String { String(localized: "discover.filters.applyCounting", bundle: #bundle) }
    static var sectionFood: String { String(localized: "discover.vybe.section.food", bundle: #bundle) }
    static var sectionOutdoors: String { String(localized: "discover.vybe.section.outdoors", bundle: #bundle) }
    static var sectionGames: String { String(localized: "discover.vybe.section.games", bundle: #bundle) }
    static var sectionCulture: String { String(localized: "discover.vybe.section.culture", bundle: #bundle) }
    static var sectionRetail: String { String(localized: "discover.vybe.section.retail", bundle: #bundle) }

    /// "Up to 2 hr"
    static func timeUpTo(_ length: String) -> String {
        String(localized: "discover.filters.timeUpTo \(length)", bundle: #bundle)
    }

    /// "3 hr or more"
    static func timeAtLeast(_ length: String) -> String {
        String(localized: "discover.filters.timeAtLeast \(length)", bundle: #bundle)
    }

    /// "Apply (12 results)", with the plural from the catalog.
    static func apply(_ count: Int) -> String {
        String(localized: "discover.filters.apply \(count)", bundle: #bundle)
    }

    /// An interest's display name. One literal catalog key per interest (a key built from a variable would be
    /// invisible to the String Catalog), split by section so each function stays small.
    static func interest(_ interest: VybeInterest) -> String {
        foodName(interest) ?? outdoorsName(interest) ?? gamesName(interest) ?? cultureName(interest)
            ?? retailName(interest) ?? interest.rawValue
    }

    private static func foodName(_ interest: VybeInterest) -> String? {
        switch interest {
        case .cafe: String(localized: "discover.vybe.interest.cafe", bundle: #bundle)
        case .chai: String(localized: "discover.vybe.interest.chai", bundle: #bundle)
        case .streetfood: String(localized: "discover.vybe.interest.streetfood", bundle: #bundle)
        case .desserts: String(localized: "discover.vybe.interest.desserts", bundle: #bundle)
        case .misal: String(localized: "discover.vybe.interest.misal", bundle: #bundle)
        case .bakery: String(localized: "discover.vybe.interest.bakery", bundle: #bundle)
        case .diner: String(localized: "discover.vybe.interest.diner", bundle: #bundle)
        case .bistros: String(localized: "discover.vybe.interest.bistros", bundle: #bundle)
        default: nil
        }
    }

    private static func outdoorsName(_ interest: VybeInterest) -> String? {
        switch interest {
        case .trek: String(localized: "discover.vybe.interest.trek", bundle: #bundle)
        case .sunsets: String(localized: "discover.vybe.interest.sunsets", bundle: #bundle)
        case .parks: String(localized: "discover.vybe.interest.parks", bundle: #bundle)
        case .drives: String(localized: "discover.vybe.interest.drives", bundle: #bundle)
        case .lakeside: String(localized: "discover.vybe.interest.lakeside", bundle: #bundle)
        default: nil
        }
    }

    private static func gamesName(_ interest: VybeInterest) -> String? {
        switch interest {
        case .gaming: String(localized: "discover.vybe.interest.gaming", bundle: #bundle)
        case .arcade: String(localized: "discover.vybe.interest.arcade", bundle: #bundle)
        case .pool: String(localized: "discover.vybe.interest.pool", bundle: #bundle)
        case .turf: String(localized: "discover.vybe.interest.turf", bundle: #bundle)
        case .boardgames: String(localized: "discover.vybe.interest.boardgames", bundle: #bundle)
        case .bouldering: String(localized: "discover.vybe.interest.bouldering", bundle: #bundle)
        default: nil
        }
    }

    private static func cultureName(_ interest: VybeInterest) -> String? {
        switch interest {
        case .books: String(localized: "discover.vybe.interest.books", bundle: #bundle)
        case .study: String(localized: "discover.vybe.interest.study", bundle: #bundle)
        case .museums: String(localized: "discover.vybe.interest.museums", bundle: #bundle)
        case .gigs: String(localized: "discover.vybe.interest.gigs", bundle: #bundle)
        case .workshops: String(localized: "discover.vybe.interest.workshops", bundle: #bundle)
        case .cinema: String(localized: "discover.vybe.interest.cinema", bundle: #bundle)
        default: nil
        }
    }

    private static func retailName(_ interest: VybeInterest) -> String? {
        switch interest {
        case .shopping: String(localized: "discover.vybe.interest.shopping", bundle: #bundle)
        case .thrifting: String(localized: "discover.vybe.interest.thrifting", bundle: #bundle)
        case .rooftop: String(localized: "discover.vybe.interest.rooftop", bundle: #bundle)
        case .midnight: String(localized: "discover.vybe.interest.midnight", bundle: #bundle)
        case .retro: String(localized: "discover.vybe.interest.retro", bundle: #bundle)
        default: nil
        }
    }
}
