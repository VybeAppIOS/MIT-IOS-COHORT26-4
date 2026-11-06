import Core
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
        case .mutualFriends(let id):
            MutualFriendsView(viewModel: MutualFriendsViewModel(
                userID: id, friends: deps.friends, session: deps.session, router: deps.router))
        }
    }
}
