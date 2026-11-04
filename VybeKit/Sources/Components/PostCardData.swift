import Design
import Foundation
import Models

/// Everything a feed card shows, already as display text. Build it with `init(_:…)` from the **public** post fields
/// only: it never takes `RunTimes`, so a card can never show when someone was where (`docs/RISKS.md` 3).
public struct PostCardData: Hashable, Sendable, Identifiable {
    public let id: RunID
    public var title: String
    public var caption: String?
    public var coverURL: URL?
    /// The visited Places in order, for the route drawing when there is no photo (straight lines, never GPS).
    public var routePoints: [Coordinate]
    public var authorName: String
    public var username: String
    public var avatarURL: URL?
    /// "3 of 5 Spots"
    public var visitedSummary: String
    public var budgetText: String
    /// "about 3 h"; nil while the run has no rounded length.
    public var durationText: String?
    /// "5 Nov": the day only, never a clock time.
    public var dayText: String?
    public var likeCount: Int
    public var commentCount: Int
    public var remixCount: Int
    public var isPick: Bool
    public var isLiked: Bool
    public var isSaved: Bool

    public init(
        id: RunID, title: String, authorName: String, username: String, visitedSummary: String, budgetText: String,
        caption: String? = nil, coverURL: URL? = nil, routePoints: [Coordinate] = [], avatarURL: URL? = nil,
        durationText: String? = nil, dayText: String? = nil, likeCount: Int = 0, commentCount: Int = 0,
        remixCount: Int = 0, isPick: Bool = false, isLiked: Bool = false, isSaved: Bool = false
    ) {
        self.id = id
        self.title = title
        self.caption = caption
        self.coverURL = coverURL
        self.routePoints = routePoints
        self.authorName = authorName
        self.username = username
        self.avatarURL = avatarURL
        self.visitedSummary = visitedSummary
        self.budgetText = budgetText
        self.durationText = durationText
        self.dayText = dayText
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.remixCount = remixCount
        self.isPick = isPick
        self.isLiked = isLiked
        self.isSaved = isSaved
    }

    /// The card for a posted run. `coverURL` and `avatarURL` come from the feature's `PhotoStore`; `routePoints` are
    /// the visited Places' coordinates in visit order; `isPick` is true for posts by the Vybe account.
    public init(
        _ post: HangoutRun, coverURL: URL?, avatarURL: URL?, routePoints: [Coordinate], remixCount: Int,
        isPick: Bool, isLiked: Bool, isSaved: Bool
    ) {
        self.init(
            id: post.id, title: post.title ?? post.card.hangoutTitle, authorName: post.card.runnerDisplayName,
            username: "@\(post.card.runnerUsername)",
            visitedSummary: ComponentStrings.visitedSpots(post.visits.count, of: post.card.totalSpots),
            budgetText: post.card.budgetPerPerson.formattedPerPerson, caption: post.caption, coverURL: coverURL,
            routePoints: routePoints, avatarURL: avatarURL,
            durationText: post.durationMinutes.map { DisplayFormat.roundedDuration(minutes: $0) },
            dayText: post.postedAt.map(Self.dayText), likeCount: post.likeCount, commentCount: post.commentCount,
            remixCount: remixCount, isPick: isPick, isLiked: isLiked, isSaved: isSaved)
    }

    /// "5 Nov" in Pune's conventions: a day, never a time.
    static func dayText(_ date: Date) -> String {
        var style = Date.FormatStyle.dateTime.day().month(.abbreviated).locale(DisplayFormat.locale)
        style.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return date.formatted(style)
    }

    /// "3 of 5 Spots · ₹150–400 · about 3 h"
    public var factsText: String {
        [visitedSummary, budgetText, durationText].compactMap(\.self).joined(separator: " · ")
    }

    /// "1.2K": the short counts on the buttons.
    static func compact(_ count: Int) -> String { DisplayFormat.compactCount(count) }
}

#if DEBUG
public extension PostCardData {
    /// Built from the sample posts (`SampleSocialData`): fake people, EXAMPLE places.
    static var previewPick: PostCardData {
        PostCardData(SampleSocialData.posts[0], coverURL: nil, avatarURL: nil,
                     routePoints: SampleData.places.map(\.coordinate), remixCount: 12, isPick: true,
                     isLiked: true, isSaved: false)
    }

    static var previewFriend: PostCardData {
        PostCardData(SampleSocialData.posts[2], coverURL: nil, avatarURL: nil,
                     routePoints: Array(SampleData.places.map(\.coordinate).reversed()), remixCount: 0, isPick: false,
                     isLiked: false, isSaved: true)
    }
}
#endif
