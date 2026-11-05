import Core
import Design
import SwiftUI

/// The only public type in EditorFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum EditorScreens {
    @ViewBuilder
    public static func editorCover(_ start: EditorStart, _ deps: AppDependencies) -> some View {
        EditorView(viewModel: EditorViewModel(
            start: start, hangouts: deps.hangouts, places: deps.places, profiles: deps.profiles, photos: deps.photos,
            libraryStore: deps.libraryStore, session: deps.session, router: deps.router, now: deps.now,
            makeID: { UUID().uuidString.lowercased() }))
    }

    @ViewBuilder
    public static func view(for route: EditorRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .suggestPlace: ScreenPlaceholder(id: "E3", name: "Suggest a Place")
        }
    }

    @ViewBuilder
    public static func suggestPlaceSheet(_ deps: AppDependencies) -> some View {
        ScreenPlaceholder(id: "E3", name: "Suggest a Place")
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
