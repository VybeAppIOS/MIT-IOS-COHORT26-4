import Foundation

/// The tabs, in bar order: Discover, Community, Profile, then Search as a separate search-role tab at the trailing end.
public enum AppTab: Hashable, Codable, Sendable, CaseIterable {
    case discover
    case community
    case profile
    case search
}
