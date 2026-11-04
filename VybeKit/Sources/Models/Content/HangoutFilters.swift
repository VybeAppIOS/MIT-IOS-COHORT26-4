import Foundation

/// What the Discover filter sheet (D3) asks for. Held by the screen; not stored on disk and not part of a Route.
public struct HangoutFilters: Codable, Hashable, Sendable {
    /// Keep Hangouts whose budget range fits inside this one.
    public var budget: RupeeRange?
    public var maxMinutes: Int?
    /// Keep Hangouts that include a Place of one of these categories.
    public var categories: Set<PlaceCategory>
    public var tags: Set<String>
    public var vibeTags: Set<String>
    public var goodForGroups: Bool

    public init(
        budget: RupeeRange? = nil, maxMinutes: Int? = nil, categories: Set<PlaceCategory> = [],
        tags: Set<String> = [], vibeTags: Set<String> = [], goodForGroups: Bool = false
    ) {
        self.budget = budget
        self.maxMinutes = maxMinutes
        self.categories = categories
        self.tags = tags
        self.vibeTags = vibeTags
        self.goodForGroups = goodForGroups
    }
}
