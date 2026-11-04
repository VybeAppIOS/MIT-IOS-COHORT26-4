import Foundation

/// What kind of Place it is. The list is the proposal in `docs/OPEN-QUESTIONS.md` (still to be confirmed by the team).
/// String-backed with an `unknown` fallback (ADR 004): a category added later never crashes an older app.
/// Raw values are the kebab-case words used in the content files.
public enum PlaceCategory: String, Codable, Hashable, Sendable, CaseIterable {
    // Food and drink
    case cafe
    case streetFood = "street-food"
    case chaiTapri = "chai-tapri"
    case restaurant
    case dessert
    case juiceShakes = "juice-shakes"
    // Outdoors
    case trek
    case fort
    case viewpointHill = "viewpoint-hill"
    case lakeDam = "lake-dam"
    case waterfall
    case parkGarden = "park-garden"
    case camping
    // Fun
    case gamingArcade = "gaming-arcade"
    case bowling
    case goKarting = "go-karting"
    case trampoline
    case escapeRoom = "escape-room"
    case boardGameCafe = "board-game-cafe"
    case karaoke
    // Entertainment
    case cinema
    case comedyOpenMic = "comedy-open-mic"
    case liveMusic = "live-music"
    case events
    // Culture
    case museum
    case heritageTemple = "heritage-temple"
    case artGallery = "art-gallery"
    case theatre
    case bookstoreLibrary = "bookstore-library"
    // Shopping
    case streetMarket = "street-market"
    case thrift
    case mall
    // Active
    case sportsTurf = "sports-turf"
    case swimming
    case cycling
    // Chill and study
    case studyCafe = "study-cafe"
    case library
    /// Any value this app version does not know.
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PlaceCategory(rawValue: raw) ?? .unknown
    }
}
