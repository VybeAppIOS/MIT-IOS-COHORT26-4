import Foundation
import Models

/// How long after a Hangout ends a post may appear (PO1: "post in 30 min / 2 h / tomorrow").
public enum PostDelay: Hashable, Sendable, CaseIterable {
    case thirtyMinutes
    case twoHours
    /// 9:00 the next calendar day.
    case nextDay
}

/// The product rules for Hangouts, as pure functions (`docs/PRODUCT.md` 4). Time is always a parameter: nothing here
/// calls `Date()`, so every rule is easy to test at its edges.
public enum HangoutRules {
    public static let minimumSpots = 2
    public static let maximumSpots = 10
    /// A Remix must keep at least this share (in percent) of the original's Places.
    public static let remixKeepPercent = 70
    public static let minimumVisitedToPost = 2
    public static let photosPerVisitedSpot = 2
    /// The earliest a post may appear after the Hangout ends.
    public static let minimumPostDelay: TimeInterval = 30 * 60
    /// "Tomorrow" posts appear at this hour of the next day.
    public static let nextDayHour = 9

    /// A Hangout has 2 to 10 Spots.
    public static func isValidSpotCount(_ count: Int) -> Bool {
        (minimumSpots...maximumSpots).contains(count)
    }

    /// The same Place twice in one Hangout is allowed, with a warning in the editor.
    public static func hasDuplicatePlace(_ spots: [Spot]) -> Bool {
        Set(spots.map(\.placeID)).count < spots.count
    }

    /// A Remix keeps at least 70% of the original's Places. Counted by Place (not by Spot), so a Place used twice
    /// counts once. An original with no Places cannot be Remixed.
    public static func remixKeepsEnough(original: [PlaceID], remix: [PlaceID]) -> Bool {
        let originalPlaces = Set(original)
        guard !originalPlaces.isEmpty else { return false }
        let kept = originalPlaces.intersection(remix).count
        return kept * 100 >= originalPlaces.count * remixKeepPercent
    }

    /// A Hangout can be posted once at least 2 Spots were visited.
    public static func canPost(visitedCount: Int) -> Bool {
        visitedCount >= minimumVisitedToPost
    }

    /// A post may carry 2 photos for each visited Spot.
    public static func maxPhotos(visitedCount: Int) -> Int {
        photosPerVisitedSpot * max(0, visitedCount)
    }

    /// The earliest time a post may appear. 30 minutes and 2 hours are counted from when the Hangout ended;
    /// "next day" is 9:00 the day after, in the given calendar's time zone.
    public static func earliestPostTime(
        endedAt: Date, delay: PostDelay = .thirtyMinutes, calendar: Calendar = .current
    ) -> Date {
        switch delay {
        case .thirtyMinutes:
            return endedAt.addingTimeInterval(minimumPostDelay)
        case .twoHours:
            return endedAt.addingTimeInterval(2 * 60 * 60)
        case .nextDay:
            let startOfEndDay = calendar.startOfDay(for: endedAt)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfEndDay) ?? startOfEndDay
            return calendar.date(bySettingHour: nextDayHour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        }
    }

    /// "about 3 h": a rounded length for posts and cards (the same words everywhere, from `DisplayFormat`).
    public static func roundedDuration(_ minutes: Int) -> String {
        DisplayFormat.roundedDuration(minutes: minutes)
    }
}
