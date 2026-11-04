import Foundation

/// Every `NavigationStack` has an ID: one per tab, one for onboarding, one inside each full-screen cover,
/// and one inside the sheet that is up (ADR 003).
public enum StackID: Hashable, Codable, Sendable {
    case onboarding
    case tab(AppTab)
    case live
    case editor
    case sheet
}
