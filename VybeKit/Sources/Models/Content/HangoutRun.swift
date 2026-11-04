import Foundation

public enum RunState: String, Codable, Hashable, Sendable {
    case live
    case done
    case scheduled
    case posted
}

/// Who may see a post. Used for the person's choice (`HangoutRun.visibility`) and for who can really see it
/// (`HangoutRun.audience`, which becomes friends-only when the profile is private).
public enum Visibility: String, Codable, Hashable, Sendable {
    case `public`
    case friends
}

/// A Spot the person has been to. Carries the order, never a time (times live in `RunTimes`).
public struct Visit: Codable, Hashable, Sendable {
    public var spotID: SpotID
    /// Copied, so a post never changes if the Hangout is edited later.
    public var placeID: PlaceID
    /// 1, 2, 3 ... what a post shows instead of times.
    public var order: Int

    public init(spotID: SpotID, placeID: PlaceID, order: Int) {
        self.spotID = spotID
        self.placeID = placeID
        self.order = order
    }
}

/// Exact times. **Owner-only**: never sent to other people and never shown on a post (ADR 004 and 006).
public struct RunTimes: Codable, Hashable, Sendable {
    public var startedAt: Date
    public var endedAt: Date?
    public var visitedAt: [SpotID: Date]

    public init(startedAt: Date, endedAt: Date? = nil, visitedAt: [SpotID: Date] = [:]) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.visitedAt = visitedAt
    }
}

/// The public words and numbers a post card needs, copied when the run starts,
/// so a card never has to load anything else.
public struct RunCardCopy: Codable, Hashable, Sendable {
    public var hangoutTitle: String
    public var totalSpots: Int
    public var budgetPerPerson: RupeeRange
    public var runnerUsername: String
    public var runnerDisplayName: String
    public var runnerPhoto: Photo?

    public init(
        hangoutTitle: String, totalSpots: Int, budgetPerPerson: RupeeRange,
        runnerUsername: String, runnerDisplayName: String, runnerPhoto: Photo? = nil
    ) {
        self.hangoutTitle = hangoutTitle
        self.totalSpots = totalSpots
        self.budgetPerPerson = budgetPerPerson
        self.runnerUsername = runnerUsername
        self.runnerDisplayName = runnerDisplayName
        self.runnerPhoto = runnerPhoto
    }
}

/// One person doing a Hangout: live, done, scheduled to post, or posted. It holds no exact times (see `RunTimes`).
public struct HangoutRun: Codable, Hashable, Sendable, Identifiable {
    public let id: RunID
    public var hangoutID: HangoutID
    public var runnerID: UserID
    public var state: RunState
    /// When a scheduled post becomes visible. At least 30 minutes after the run ended.
    public var postAt: Date?
    public var visits: [Visit]
    /// A rounded length, for example 170. Nil until the run has ended.
    public var durationMinutes: Int?
    public var photos: [Photo]
    public var title: String?
    public var caption: String?
    public var coverPhotoID: PhotoID?
    public var tags: [String]
    /// The person's choice.
    public var visibility: Visibility
    /// Who can really see it.
    public var audience: Visibility
    public var card: RunCardCopy
    public var likeCount: Int
    public var commentCount: Int
    public var postedAt: Date?

    public init(
        id: RunID, hangoutID: HangoutID, runnerID: UserID, state: RunState, postAt: Date? = nil,
        visits: [Visit] = [], durationMinutes: Int? = nil, photos: [Photo] = [], title: String? = nil,
        caption: String? = nil, coverPhotoID: PhotoID? = nil, tags: [String] = [],
        visibility: Visibility = .friends, audience: Visibility = .friends, card: RunCardCopy,
        likeCount: Int = 0, commentCount: Int = 0, postedAt: Date? = nil
    ) {
        self.id = id
        self.hangoutID = hangoutID
        self.runnerID = runnerID
        self.state = state
        self.postAt = postAt
        self.visits = visits
        self.durationMinutes = durationMinutes
        self.photos = photos
        self.title = title
        self.caption = caption
        self.coverPhotoID = coverPhotoID
        self.tags = tags
        self.visibility = visibility
        self.audience = audience
        self.card = card
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.postedAt = postedAt
    }
}
