import Core
import Design
import Models
import SwiftUI

/// The only public type in ModerationFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum ModerationScreens {
    @ViewBuilder
    public static func view(for route: ModerationRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .report: ScreenPlaceholder(id: "R1", name: "Report")
        case .admin(.reports): ScreenPlaceholder(id: "AD1", name: "Reports queue")
        case .admin(.placeSuggestions): ScreenPlaceholder(id: "AD2", name: "Place suggestions")
        case .admin(.users): ScreenPlaceholder(id: "AD3", name: "Users")
        }
    }

    @ViewBuilder
    public static func reportSheet(_ target: ReportTarget, _ deps: AppDependencies) -> some View {
        ScreenPlaceholder(id: "R1", name: "Report")
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
