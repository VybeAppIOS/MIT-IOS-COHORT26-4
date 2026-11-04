import Foundation

/// A price per person in whole rupees. Never a `Double`.
/// (`lower`/`upper`, not `min`/`max`, which shadow Swift's functions.)
public struct RupeeRange: Codable, Hashable, Sendable {
    public var lower: Int
    public var upper: Int

    public init(lower: Int, upper: Int) {
        self.lower = lower
        self.upper = upper
    }

    /// "₹150–400" (one value when both ends are equal). Indian digit grouping, no paise.
    public var formattedPerPerson: String { DisplayFormat.rupeeRange(lower: lower, upper: upper) }
}
