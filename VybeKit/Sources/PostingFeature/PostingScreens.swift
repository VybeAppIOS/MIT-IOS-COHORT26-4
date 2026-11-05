import Core
import Models
import SwiftUI

/// The only public type in PostingFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum PostingScreens {
    @ViewBuilder
    public static func view(for route: PostingRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .compose(let id):
            ComposerView(viewModel: ComposerViewModel(
                runID: id, libraryStore: deps.libraryStore, session: deps.session, photos: deps.photos,
                router: deps.router, now: deps.now))
        }
    }

    @ViewBuilder
    public static func editPostSheet(_ id: RunID, _ deps: AppDependencies) -> some View {
        EditPostView(viewModel: EditPostViewModel(
            runID: id, libraryStore: deps.libraryStore, places: deps.places, photos: deps.photos,
            session: deps.session, router: deps.router))
    }
}
