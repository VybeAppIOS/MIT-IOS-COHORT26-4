import Foundation

/// A real venue on the map. A `Spot` points to a Place.
public struct Place: Codable, Hashable, Sendable, Identifiable {
    public let id: PlaceID
    public var name: String
    public var category: PlaceCategory
    public var city: String
    public var area: String
    public var address: String
    public var coordinate: Coordinate
    public var costPerPerson: RupeeRange
    /// Opening hours in Pune time. Empty when unknown; see `hoursNote`.
    public var hours: [OpeningPeriod]
    public var hoursNote: String?
    public var photos: [Photo]
    /// Apple's Place ID. Storing it is allowed; copying Apple Maps data is not (`AGENTS.md` 4).
    public var applePlaceID: String?
    public var status: PlaceStatus
    public var trekInfo: TrekInfo?
    public var verifiedAt: Date

    public init(
        id: PlaceID, name: String, category: PlaceCategory, city: String, area: String, address: String,
        coordinate: Coordinate, costPerPerson: RupeeRange, hours: [OpeningPeriod] = [], hoursNote: String? = nil,
        photos: [Photo] = [], applePlaceID: String? = nil, status: PlaceStatus = .approved,
        trekInfo: TrekInfo? = nil, verifiedAt: Date
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.city = city
        self.area = area
        self.address = address
        self.coordinate = coordinate
        self.costPerPerson = costPerPerson
        self.hours = hours
        self.hoursNote = hoursNote
        self.photos = photos
        self.applePlaceID = applePlaceID
        self.status = status
        self.trekInfo = trekInfo
        self.verifiedAt = verifiedAt
    }
}

/// One opening window. `weekday` is 1 = Sunday ... 7 = Saturday (like Apple's Calendar);
/// times are "HH:mm" in Pune time.
public struct OpeningPeriod: Codable, Hashable, Sendable {
    public var weekday: Int
    public var open: String
    public var close: String

    public init(weekday: Int, open: String, close: String) {
        self.weekday = weekday
        self.open = open
        self.close = close
    }
}

public enum PlaceStatus: String, Codable, Hashable, Sendable {
    case approved
    case hidden
    /// Shown with a warning, for example a fort closed in the monsoon by the authorities.
    case closedByAuthorities
}

/// Extra facts for treks (`Place.category == .trek` and similar).
public struct TrekInfo: Codable, Hashable, Sendable {
    public var difficulty: TrekDifficulty
    /// Free text, for example "October to February".
    public var season: String
    public var startPoint: String
    public var safetyNote: String

    public init(difficulty: TrekDifficulty, season: String, startPoint: String, safetyNote: String) {
        self.difficulty = difficulty
        self.season = season
        self.startPoint = startPoint
        self.safetyNote = safetyNote
    }
}

public enum TrekDifficulty: String, Codable, Hashable, Sendable, CaseIterable {
    case easy
    case moderate
    case hard
    case unknown

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TrekDifficulty(rawValue: raw) ?? .unknown
    }
}
