import SwiftUI

/// The app's entry point. `@main` tells iOS to start here.
@main
struct VybeApp: App {
    var body: some Scene {
        // A WindowGroup is the app's main window; it shows RootView.
        WindowGroup {
            RootView()
        }
    }
}
