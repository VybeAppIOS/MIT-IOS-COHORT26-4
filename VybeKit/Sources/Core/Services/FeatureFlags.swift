import Foundation

/// Switches for areas that are not finished, so `main` can always ship: an unfinished area shows "Coming soon".
public struct FeatureFlags: Hashable, Sendable {
    public var communityEnabled: Bool
    public var friendsEnabled: Bool
    public var chatEnabled: Bool
    public var postingEnabled: Bool
    public var editorEnabled: Bool

    public init(
        communityEnabled: Bool, friendsEnabled: Bool, chatEnabled: Bool, postingEnabled: Bool, editorEnabled: Bool
    ) {
        self.communityEnabled = communityEnabled
        self.friendsEnabled = friendsEnabled
        self.chatEnabled = chatEnabled
        self.postingEnabled = postingEnabled
        self.editorEnabled = editorEnabled
    }

    public static let allOn = FeatureFlags(
        communityEnabled: true, friendsEnabled: true, chatEnabled: true, postingEnabled: true, editorEnabled: true)

    public static let allOff = FeatureFlags(
        communityEnabled: false, friendsEnabled: false, chatEnabled: false, postingEnabled: false, editorEnabled: false)

    /// Everything on in DEBUG builds; off in release builds until an area is finished.
    public static var current: FeatureFlags {
        #if DEBUG
        allOn
        #else
        allOff
        #endif
    }
}
