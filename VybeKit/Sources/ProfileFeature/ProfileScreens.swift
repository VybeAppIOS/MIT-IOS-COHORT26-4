import Core
import Design
import SwiftUI

/// The only public type in ProfileFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum ProfileScreens {
    @ViewBuilder
    public static func root(_ deps: AppDependencies) -> some View {
        ScreenPlaceholder(id: "PR1", name: "My profile")
    }

    @ViewBuilder
    public static func view(for route: ProfileRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .saved: ScreenPlaceholder(id: "PR4", name: "Saved")
        case .drafts: ScreenPlaceholder(id: "PR5", name: "Drafts")
        case .readyToPost: ScreenPlaceholder(id: "PR8", name: "Ready to post")
        case .settings: ScreenPlaceholder(id: "PR2", name: "Settings")
        case .settingsPage(let page): settingsPage(page)
        case .deleteAccount: ScreenPlaceholder(id: "ST8", name: "Delete account")
        }
    }

    @ViewBuilder
    private static func settingsPage(_ page: SettingsPage) -> some View {
        switch page {
        case .account: ScreenPlaceholder(id: "ST1", name: "Account")
        case .privacy: ScreenPlaceholder(id: "ST2", name: "Privacy")
        case .blocked: ScreenPlaceholder(id: "ST3", name: "Blocked")
        case .notifications: ScreenPlaceholder(id: "ST4", name: "Notifications")
        case .help: ScreenPlaceholder(id: "ST5", name: "Help and contact")
        case .placeSuggestions: ScreenPlaceholder(id: "ST6", name: "My Place suggestions")
        case .about: ScreenPlaceholder(id: "ST7", name: "About and credits")
        }
    }
}

/// Stands in for a screen until its task replaces the `case` in this feature's `Screens` (task F-16).
/// Developer-only text, so it is not localized.
private struct ScreenPlaceholder: View {
    let id: String
    let name: String

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            Text(verbatim: id).font(Theme.Font.largeTitle)
            Text(verbatim: name).font(Theme.Font.headline)
            Text(verbatim: "Placeholder until this screen's task replaces it")
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: name))
    }
}
