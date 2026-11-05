import Core
import SwiftUI

/// The only public type in DiscoverFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. D1 is built; D2 and D3 join it inside the map screen.
public enum DiscoverScreens {
    @ViewBuilder
    public static func root(_ deps: AppDependencies) -> some View {
        DiscoverMapView(viewModel: DiscoverMapViewModel(
            hangouts: deps.hangouts, places: deps.places, photos: deps.photos, library: deps.libraryStore,
            network: deps.network, router: deps.router, now: deps.now))
    }
}
