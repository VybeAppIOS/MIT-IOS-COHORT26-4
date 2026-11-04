import Foundation

/// One Place inside a Hangout, with its order (the position in `Hangout.spots`), time and note.
public struct Spot: Codable, Hashable, Sendable, Identifiable {
    /// Unique inside its Hangout, for example `s1`.
    public let id: SpotID
    public var placeID: PlaceID
    public var minutes: Int?
    public var note: String?

    public init(id: SpotID, placeID: PlaceID, minutes: Int? = nil, note: String? = nil) {
        self.id = id
        self.placeID = placeID
        self.minutes = minutes
        self.note = note
    }
}
