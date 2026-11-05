import Design
import SwiftUI

/// The app's entry point. `@main` tells iOS to start here.
@main
struct VybeApp: App {
    var body: some Scene {
        // A WindowGroup is the app's main window; it shows RootView.
        WindowGroup {
            RootView()
                // One accent for the whole app: the tab bar, links, toggles and every system control.
                .tint(Theme.Color.accent)
        }
    }
}
