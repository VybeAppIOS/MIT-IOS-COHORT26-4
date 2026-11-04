import Core
import Design
import Models
import SwiftUI

/// The only public type in LiveFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum LiveScreens {
    @ViewBuilder
    public static func liveCover(_ id: HangoutID, _ deps: AppDependencies) -> some View {
        ScreenPlaceholder(id: "H1", name: "Hangout live")
    }

    @ViewBuilder
    public static func view(for route: LiveRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .summary: ScreenPlaceholder(id: "H3", name: "Summary")
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
