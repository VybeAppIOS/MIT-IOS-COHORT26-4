import Core
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
        case .suggestPlace: SuggestPlaceView(viewModel: makeSuggestPlace(.pushed, deps))
        }
    }

    @ViewBuilder
    public static func suggestPlaceSheet(_ deps: AppDependencies) -> some View {
        SuggestPlaceView(viewModel: makeSuggestPlace(.sheet, deps))
    }

    /// There is no repository call for suggestions yet (see WO-3 report), so sending only logs that it happened.
    @MainActor
    private static func makeSuggestPlace(
        _ presentation: SuggestPlacePresentation, _ deps: AppDependencies
    ) -> SuggestPlaceViewModel {
        SuggestPlaceViewModel(
            presentation: presentation, session: deps.session, router: deps.router,
            submit: { _ in Log.app.info("Place suggestion sent (stub)") },
            now: deps.now, makeID: { UUID().uuidString.lowercased() })
    }
}
