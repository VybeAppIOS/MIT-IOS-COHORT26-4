import Core
import Design
import Models
import SwiftUI

/// The only public type in HangoutDetailFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum HangoutDetailScreens {
    @ViewBuilder
    public static func view(for route: HangoutDetailRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .detail(let id):
            HangoutDetailView(viewModel: HangoutDetailViewModel(
                id: id, hangouts: deps.hangouts, places: deps.places, profiles: deps.profiles, photos: deps.photos,
                library: deps.libraryStore, liveStore: deps.liveStore, network: deps.network, router: deps.router))
        case .remixTree: ScreenPlaceholder(id: "HD3", name: "Remix tree")
        }
    }

    @ViewBuilder
    public static func spotSheet(_ id: PlaceID, _ deps: AppDependencies) -> some View {
        SpotSheetView(viewModel: SpotSheetViewModel(
            id: id, places: deps.places, hangouts: deps.hangouts, photos: deps.photos, library: deps.libraryStore,
            router: deps.router, now: deps.now))
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
