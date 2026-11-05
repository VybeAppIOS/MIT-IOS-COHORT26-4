import Core
import Design
import Models
import SwiftUI

/// The only public type in CommunityFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum CommunityScreens {
    @ViewBuilder
    public static func root(_ deps: AppDependencies) -> some View {
        FeedView(viewModel: FeedViewModel(
            feed: deps.feed, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            libraryStore: deps.libraryStore, badges: deps.badges, router: deps.router))
    }

    @ViewBuilder
    public static func view(for route: CommunityRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .post: ScreenPlaceholder(id: "CM2", name: "Post detail")
        case .trending: ScreenPlaceholder(id: "CM4", name: "Trending")
        case .activity: ScreenPlaceholder(id: "CM5", name: "Activity")
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
