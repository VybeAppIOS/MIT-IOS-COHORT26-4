import SwiftUI

extension View {
    /// Hides the tab bar on a screen you are *inside of* (a conversation, a Hangout, a settings page). The tab bar
    /// stays on the four browse roots: the Discover map, the Community feed, Profile and Search. Call this on the
    /// pushed screen's own view, never on a stack. Sheets and covers already hide the bar by themselves.
    public func hidesTabBar() -> some View {
        toolbarVisibility(.hidden, for: .tabBar)
    }
}
