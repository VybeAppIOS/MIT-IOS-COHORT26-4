import Foundation
import Models
import Design

public struct HangoutCardData: Equatable, Sendable, Identifiable {
    public let id: HangoutID
    public let title: String
    public let coverURL: URL?
    public let spotCount: Int
    public let budgetText: String
    public let durationText: String
    public let tags: [String]
    public let isPick: Bool
    public var isSaved: Bool
    public let authorName: String?

    public init(
        id: HangoutID,
        title: String,
        coverURL: URL?,
        spotCount: Int,
        budgetText: String,
        durationText: String,
        tags: [String],
        isPick: Bool,
        isSaved: Bool,
        authorName: String?
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

    /// Convenience initializer mapping a raw `Hangout` model into card-ready display values.
    public init(_ hangout: Hangout, coverURL: URL?, isSaved: Bool, authorName: String? = nil) {
        self.id = hangout.id
        self.title = hangout.title
        self.coverURL = coverURL
        self.spotCount = hangout.spots.count
        self.budgetText = hangout.budgetPerPerson.formattedPerPerson
        self.durationText = Formatting.formatDuration(minutes: hangout.estimatedMinutes)
        self.tags = hangout.tags
        self.isPick = hangout.isPick
        self.isSaved = isSaved
        self.authorName = authorName
    }
}
