import Foundation
import Models

// Small payloads carried by routes, sheets and covers. IDs and small enums only (ADR 003).

/// How the editor cover starts (E1).
public enum EditorStart: Hashable, Codable, Sendable {
    case new
    case draft(HangoutID)
    case remix(HangoutID)
}

/// The pages of Settings (ST1 to ST7). ST8 (delete account) has its own route.
public enum SettingsPage: Hashable, Codable, Sendable, CaseIterable {
    case account
    case privacy
    case blocked
    case notifications
    case help
    case placeSuggestions
    case about
}

/// The hidden admin pages (AD1 to AD3), shown to team accounts only.
public enum AdminPage: Hashable, Codable, Sendable, CaseIterable {
    case reports
    case placeSuggestions
    case users
}

/// Which group "See all" shows in Search (S2).
public enum SearchKind: Hashable, Codable, Sendable, CaseIterable {
    case hangouts
    case places
    case people
}

/// What the Share sheet (CH5) shares.
public enum ShareItem: Hashable, Codable, Sendable {
    case hangout(HangoutID)
    case post(RunID)
}
