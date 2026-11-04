import Foundation

public extension IDTag {
    enum PlaceSuggestion {}
}

public typealias PlaceSuggestionID = ID<IDTag.PlaceSuggestion>

/// Credit for a Remix: only the direct parent gets it, once per person per original. Server only.
public struct RemixCredit: Codable, Hashable, Sendable {
    public var originalHangoutID: HangoutID
    public var remixerID: UserID
    public var remixHangoutID: HangoutID
    public var runID: RunID
    public var createdAt: Date

    public init(
        originalHangoutID: HangoutID, remixerID: UserID, remixHangoutID: HangoutID, runID: RunID, createdAt: Date
    ) {
        self.originalHangoutID = originalHangoutID
        self.remixerID = remixerID
        self.remixHangoutID = remixHangoutID
        self.runID = runID
        self.createdAt = createdAt
    }
}

/// "I'm in" from the public web page, without an account. Guests never appear in friend lists or chats.
public struct GuestResponse: Codable, Hashable, Sendable {
    public var hangoutID: HangoutID
    /// Typed by the guest.
    public var displayName: String
    public var reminderEmail: String?
    public var createdAt: Date

    public init(hangoutID: HangoutID, displayName: String, reminderEmail: String? = nil, createdAt: Date) {
        self.hangoutID = hangoutID
        self.displayName = displayName
        self.reminderEmail = reminderEmail
        self.createdAt = createdAt
    }
}

public enum PlaceSuggestionStatus: String, Codable, Hashable, Sendable {
    case pending
    case approved
    case rejected
}

/// A Place a person suggests (E3). The team reviews it; residential addresses are rejected.
public struct PlaceSuggestion: Codable, Hashable, Sendable, Identifiable {
    public let id: PlaceSuggestionID
    public var submitterID: UserID
    public var name: String
    public var coordinate: Coordinate
    public var category: PlaceCategory
    public var note: String?
    public var photo: Photo?
    public var status: PlaceSuggestionStatus
    public var reviewNote: String?
    /// The Place made from it, once approved.
    public var approvedPlaceID: PlaceID?
    public var createdAt: Date
    public var reviewedAt: Date?

    public init(
        id: PlaceSuggestionID, submitterID: UserID, name: String, coordinate: Coordinate, category: PlaceCategory,
        note: String? = nil, photo: Photo? = nil, status: PlaceSuggestionStatus = .pending, reviewNote: String? = nil,
        approvedPlaceID: PlaceID? = nil, createdAt: Date, reviewedAt: Date? = nil
    ) {
        self.id = id
        self.submitterID = submitterID
        self.name = name
        self.coordinate = coordinate
        self.category = category
        self.note = note
        self.photo = photo
        self.status = status
        self.reviewNote = reviewNote
        self.approvedPlaceID = approvedPlaceID
        self.createdAt = createdAt
        self.reviewedAt = reviewedAt
    }
}
