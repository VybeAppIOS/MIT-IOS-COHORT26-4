import Core
import Models
import SwiftUI

/// The only public type in CommunityFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum CommunityScreens {
    @ViewBuilder
    public static func root(_ deps: AppDependencies) -> some View {
        FeedView(viewModel: FeedViewModel(
            feed: deps.feed, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            libraryStore: deps.libraryStore, badges: deps.badges, session: deps.session, router: deps.router,
            makeComments: commentsFactory(deps)))
    }

    /// Builds the Comments sheet for a post. The Feed and Post detail share it.
    private static func commentsFactory(_ deps: AppDependencies) -> CommentsFactory {
        { runID, onExit in
            CommentsViewModel(
                runID: runID, feed: deps.feed, profiles: deps.profiles, session: deps.session, network: deps.network,
                now: deps.now, makeID: { UUID().uuidString }, onExit: onExit)
        }
    }

    @ViewBuilder
    public static func view(for route: CommunityRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .post(let id):
            PostDetailView(viewModel: PostDetailViewModel(
                runID: id, feed: deps.feed, hangouts: deps.hangouts, places: deps.places, profiles: deps.profiles,
                friends: deps.friends, photos: deps.photos, libraryStore: deps.libraryStore, session: deps.session,
                router: deps.router, now: deps.now, makeComments: commentsFactory(deps)))
        case .trending:
            TrendingView(viewModel: TrendingViewModel(
                feed: deps.feed, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
                libraryStore: deps.libraryStore, session: deps.session, router: deps.router,
                makeComments: commentsFactory(deps)))
        case .activity:
            ActivityView(viewModel: ActivityViewModel(
                feed: deps.feed, friends: deps.friends, profiles: deps.profiles, badges: deps.badges,
                router: deps.router, now: deps.now))
        }
    }
}
