import Core
import Models
import SwiftUI

/// The only public type in LiveFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum LiveScreens {
    @ViewBuilder
    public static func liveCover(_ id: HangoutID, _ deps: AppDependencies) -> some View {
        LiveView(viewModel: LiveViewModel(
            id: id, hangouts: deps.hangouts, places: deps.places, photos: deps.photos, liveStore: deps.liveStore,
            location: deps.location, router: deps.router))
    }

    /// The live mini-bar (H4) for the App's `TabView`: `.modifier(LiveScreens.miniBarAccessory(deps))`. It shows only
    /// while a run is live and its screen is closed.
    public static func miniBarAccessory(_ deps: AppDependencies) -> some ViewModifier {
        MiniBarAccessory(viewModel: MiniBarViewModel(
            hangouts: deps.hangouts, places: deps.places, liveStore: deps.liveStore, router: deps.router))
    }

    @ViewBuilder
    public static func view(for route: LiveRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .summary(let runID):
            SummaryView(viewModel: SummaryViewModel(
                runID: runID, library: deps.libraryStore, places: deps.places, photos: deps.photos,
                router: deps.router))
        }
    }
}
