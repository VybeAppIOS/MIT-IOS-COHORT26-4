import Design
import Foundation
import Models

/// Everything a Hangout card shows, already as display text. Build it with `init(_:coverURL:isSaved:authorName:)`
/// so Discover, Search, Profile, Community and Chat all write "3 Spots · ₹150–400 · about 2 h" the same way
/// (a feature never formats these itself).
public struct HangoutCardData: Hashable, Sendable, Identifiable {
    public let id: HangoutID
    public var title: String
    public var coverURL: URL?
    public var spotCount: Int
    public var budgetText: String
    public var durationText: String
    public var tags: [String]
    public var isPick: Bool
    public var isSaved: Bool
    public var authorName: String?

    public init(
        id: HangoutID, title: String, spotCount: Int, budgetText: String, durationText: String,
        coverURL: URL? = nil, tags: [String] = [], isPick: Bool = false, isSaved: Bool = false,
        authorName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.coverURL = coverURL
        self.spotCount = spotCount
        self.budgetText = budgetText
        self.durationText = durationText
        self.tags = tags
        self.isPick = isPick
        self.isSaved = isSaved
        self.authorName = authorName
    }

    /// The card for a Hangout. `coverURL` comes from the feature's `PhotoStore` (the first Spot's first photo).
    public init(_ hangout: Hangout, coverURL: URL?, isSaved: Bool, authorName: String? = nil) {
        self.init(
            id: hangout.id, title: hangout.title, spotCount: hangout.spots.count,
            budgetText: hangout.budgetPerPerson.formattedPerPerson,
            durationText: DisplayFormat.roundedDuration(minutes: hangout.estimatedMinutes),
            coverURL: coverURL, tags: hangout.tags, isPick: hangout.isPick, isSaved: isSaved, authorName: authorName)
    }

    /// "3 Spots"
    public var spotsText: String { ComponentStrings.spotCount(spotCount) }

    /// "3 Spots · ₹150–400 · about 2 h"
    public var factsText: String { [spotsText, budgetText, durationText].joined(separator: " · ") }

    /// What VoiceOver reads for the whole card: "Hangout: title, 3 Spots, ₹150–400, about 2 h, Picks, Saved".
    public var accessibilityText: String {
        var parts = [title, spotsText, budgetText, durationText]
        if let authorName { parts.append(authorName) }
        if isPick { parts.append(SharedStrings.badgePicks) }
        if isSaved { parts.append(SharedStrings.badgeSaved) }
        return ComponentStrings.cardAccessibility(parts.joined(separator: ", "))
    }
}

#if DEBUG
public extension HangoutCardData {
    /// The EXAMPLE Hangouts from `SampleData`, for previews (never invented venues).
    static var previewPick: HangoutCardData { HangoutCardData(SampleData.evening, coverURL: nil, isSaved: true) }
    static var previewRegular: HangoutCardData {
        HangoutCardData(SampleData.morning, coverURL: nil, isSaved: false, authorName: "Sample Friend")
    }
}
#endif
