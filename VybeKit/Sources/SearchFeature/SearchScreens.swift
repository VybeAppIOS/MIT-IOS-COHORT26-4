import Core
import SwiftUI

/// The only public type in SearchFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum SearchScreens {
    @ViewBuilder
    public static func root(_ deps: AppDependencies) -> some View {
        SearchView(viewModel: SearchViewModel(
            search: deps.search, hangouts: deps.hangouts, libraryStore: deps.libraryStore, session: deps.session,
            router: deps.router))
    }

    @ViewBuilder
    public static func view(for route: SearchRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .seeAll(let kind):
            SeeAllView(viewModel: SeeAllViewModel(
                kind: kind, hangouts: deps.hangouts, places: deps.places, friends: deps.friends,
                session: deps.session, router: deps.router))
        }
    }
}
