import Foundation

/// The interests offered on O3, from the task (SC-O3: "a fixed list of about 14 interests"). They are saved into the
/// onboarding draft (and later the profile) as these stable slugs; the names shown come from the String Catalog.
/// `UserProfile.interests` is `[String]`, so there is no `Models` type for them yet.
enum InterestOption: String, CaseIterable, Sendable {
    case cafes
    case streetFood = "street-food"
    case treks
    case gaming
    case liveMusic = "live-music"
    case movies
    case boardGames = "board-games"
    case studySpots = "study-spots"
    case sports
    case artAndCulture = "art-and-culture"
    case thrift
    case photography
    case sunsets
    case budgetEats = "budget-eats"

    var title: String {
        switch self {
        case .cafes: String(localized: "onboarding.interests.cafes", bundle: #bundle)
        case .streetFood: String(localized: "onboarding.interests.streetFood", bundle: #bundle)
        case .treks: String(localized: "onboarding.interests.treks", bundle: #bundle)
        case .gaming: String(localized: "onboarding.interests.gaming", bundle: #bundle)
        case .liveMusic: String(localized: "onboarding.interests.liveMusic", bundle: #bundle)
        case .movies: String(localized: "onboarding.interests.movies", bundle: #bundle)
        case .boardGames: String(localized: "onboarding.interests.boardGames", bundle: #bundle)
        case .studySpots: String(localized: "onboarding.interests.studySpots", bundle: #bundle)
        case .sports: String(localized: "onboarding.interests.sports", bundle: #bundle)
        case .artAndCulture: String(localized: "onboarding.interests.artAndCulture", bundle: #bundle)
        case .thrift: String(localized: "onboarding.interests.thrift", bundle: #bundle)
        case .photography: String(localized: "onboarding.interests.photography", bundle: #bundle)
        case .sunsets: String(localized: "onboarding.interests.sunsets", bundle: #bundle)
        case .budgetEats: String(localized: "onboarding.interests.budgetEats", bundle: #bundle)
        }
    }
}
