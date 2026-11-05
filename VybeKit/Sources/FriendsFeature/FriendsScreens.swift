import Core
import Design
import SwiftUI

/// The only public type in FriendsFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum FriendsScreens {
    @ViewBuilder
    public static func view(for route: FriendsRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .hub:
            HubView(viewModel: HubViewModel(
                friends: deps.friends, profiles: deps.profiles, session: deps.session, router: deps.router,
                now: deps.now))
        case .profile(let id):
            OtherProfileView(viewModel: OtherProfileViewModel(
                userID: id, profiles: deps.profiles, friends: deps.friends, feed: deps.feed, places: deps.places,
                photos: deps.photos, session: deps.session, router: deps.router))
        case .mutualFriends: ScreenPlaceholder(id: "PR7", name: "Mutual friends")
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
