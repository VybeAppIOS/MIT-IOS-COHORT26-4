import Core
import Design
import SwiftUI

/// The app's entry point. `@main` tells iOS to start here.
@main
struct VybeApp: App {
    /// Settings > Appearance. Read straight from `UserDefaults` so a change in Settings applies at once.
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppearanceChoice.system.rawValue

    var body: some Scene {
        // A WindowGroup is the app's main window; it shows RootView.
        WindowGroup {
            RootView()
                // One accent for the whole app: the tab bar, links, toggles and every system control.
                .tint(Theme.Color.accent)
                .preferredColorScheme(colorScheme)
        }
    }

    /// nil follows the phone.
    private var colorScheme: ColorScheme? {
        switch AppearanceChoice(rawValue: appearance) ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
