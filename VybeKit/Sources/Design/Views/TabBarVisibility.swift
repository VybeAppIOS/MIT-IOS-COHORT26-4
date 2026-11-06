import SwiftUI

extension View {
    /// Hides the tab bar on a screen you are *inside of* (a conversation, a Hangout, a settings page). The tab bar
    /// stays on the four browse roots: the Discover map, the Community feed, Profile and Search. Call this on the
    /// pushed screen's own view, never on a stack. Sheets and covers already hide the bar by themselves.
    public func hidesTabBar() -> some View {
        toolbarVisibility(.hidden, for: .tabBar)
    }
}

extension View {
    /// Lists and forms draw the system grey behind their rows. This swaps it for the app's own surface colour (warm
    /// cream in light, near-black in dark), so every screen has the same background.
    public func vybeListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.Color.surface)
    }
}
