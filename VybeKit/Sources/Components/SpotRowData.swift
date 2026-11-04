import Design
import Foundation
import Models

/// Everything a Spot row shows, already as display text. Build it with `init(spot:place:order:total:state:…)` so
/// Hangout detail, the live screen and the editor all write a Spot the same way.
public struct SpotRowData: Hashable, Sendable, Identifiable {
    public enum State: Hashable, Sendable {
        case normal
        case visited
        /// The Spot the person is heading to during a live Hangout.
        case current
        case closedByAuthorities
    }

    public let id: SpotID
    /// 1, 2, 3 … the position in the Hangout.
    public var order: Int
    public var total: Int
    public var placeName: String
    public var categoryText: String
    /// "45 min", nil when the Hangout gives no time for this Spot.
    public var minutesText: String?
    public var note: String?
    public var thumbnailURL: URL?
    public var state: State
    public var hasDuplicateWarning: Bool

    public init(
        id: SpotID, order: Int, total: Int, placeName: String, categoryText: String, minutesText: String? = nil,
        note: String? = nil, thumbnailURL: URL? = nil, state: State = .normal, hasDuplicateWarning: Bool = false
    ) {
        self.id = id
        self.order = order
        self.total = total
        self.placeName = placeName
        self.categoryText = categoryText
        self.minutesText = minutesText
        self.note = note
        self.thumbnailURL = thumbnailURL
        self.state = state
        self.hasDuplicateWarning = hasDuplicateWarning
    }

    /// The row for a Spot of a Hangout. A Place closed by the authorities always shows as closed, whatever `state`
    /// says. `thumbnailURL` comes from the feature's `PhotoStore` (the Place's first photo).
    public init(
        spot: Spot, place: Place, order: Int, total: Int, state: State = .normal, thumbnailURL: URL? = nil,
        hasDuplicateWarning: Bool = false
    ) {
        self.init(
            id: spot.id, order: order, total: total, placeName: place.name,
            categoryText: ComponentStrings.categoryName(place.category),
            minutesText: spot.minutes.map(Self.minutesText), note: spot.note, thumbnailURL: thumbnailURL,
            state: place.status == .closedByAuthorities ? .closedByAuthorities : state,
            hasDuplicateWarning: hasDuplicateWarning)
    }

    /// "45 min", "1 hr, 30 min" (system formatting, so the units follow the person's language).
    static func minutesText(_ minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    /// "Café · 45 min"
    public var detailText: String { [categoryText, minutesText].compactMap(\.self).joined(separator: " · ") }

    /// What VoiceOver reads: "Spot 2 of 4, Name, Café · 45 min, Visited".
    public var accessibilityText: String {
        var parts = [ComponentStrings.spotPosition(order, of: total), placeName, detailText]
        switch state {
        case .normal: break
        case .visited: parts.append(ComponentStrings.spotVisited)
        case .current: parts.append(ComponentStrings.spotCurrent)
        case .closedByAuthorities: parts.append(SharedStrings.badgeClosed)
        }
        if hasDuplicateWarning { parts.append(ComponentStrings.spotDuplicate) }
        if let note { parts.append(note) }
        return parts.joined(separator: ", ")
    }
}
