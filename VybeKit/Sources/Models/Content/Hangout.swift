import Foundation

public enum HangoutStatus: String, Codable, Hashable, Sendable {
    /// Visible to its author only.
    case draft
    case published
}

/// The blueprint: 2 to 10 ordered Spots. Counts (done, Remix credits, saves) are kept by the server and are not part
/// of this type (they are read through `HangoutRepository.stats(for:)`).
public struct Hangout: Codable, Hashable, Sendable, Identifiable {
    public let id: HangoutID
    public var title: String
    public var summary: String
    /// Ordered; 2 to 10 (checked by `HangoutRules`, not here).
    public var spots: [Spot]
    public var budgetPerPerson: RupeeRange
    public var estimatedMinutes: Int
    public var bestTimes: [String]
    public var tags: [String]
    public var vibeTags: [String]
    public var authorID: UserID
    public var isPick: Bool
    public var status: HangoutStatus
    public var remixedFromID: HangoutID?
    /// Saved at Remix time, for the 70% rule.
    public var remixedFromPlaceIDs: [PlaceID]?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: HangoutID, title: String, summary: String, spots: [Spot], budgetPerPerson: RupeeRange,
        estimatedMinutes: Int, bestTimes: [String] = [], tags: [String] = [], vibeTags: [String] = [],
        authorID: UserID, isPick: Bool = false, status: HangoutStatus = .published,
        remixedFromID: HangoutID? = nil, remixedFromPlaceIDs: [PlaceID]? = nil, createdAt: Date, updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.spots = spots
        self.budgetPerPerson = budgetPerPerson
        self.estimatedMinutes = estimatedMinutes
        self.bestTimes = bestTimes
        self.tags = tags
        self.vibeTags = vibeTags
        self.authorID = authorID
        self.isPick = isPick
        self.status = status
        self.remixedFromID = remixedFromID
        self.remixedFromPlaceIDs = remixedFromPlaceIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
