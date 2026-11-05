#if DEBUG
import Core
import Models
import SwiftUI

extension LiveViewModel {
    /// The real ViewModel on the stubs with a live run of the EXAMPLE Evening Hangout, walking the simulated route.
    static func preview(visited: Int = 0, location: (any LocationService)? = nil) -> LiveViewModel {
        let deps = AppDependencies.preview()
        let viewModel = LiveViewModel(
            id: SampleData.evening.id, hangouts: deps.hangouts, places: deps.places, photos: deps.photos,
            liveStore: deps.liveStore, location: location ?? SimulatedLocationService.examplePreview,
            router: deps.router)
        Task {
            _ = try? await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
            for spot in SampleData.evening.spots.prefix(visited) { deps.liveStore.markVisited(spotID: spot.id) }
        }
        return viewModel
    }
}

/// A location service with no permission (previews only).
private struct NoLocation: LocationService {
    var authorization: LocationAuthorization { .denied }
    func updates() -> AsyncStream<LocationSample> { AsyncStream { $0.finish() } }
    func requestWhenInUse() {}
}

private func screen(_ viewModel: LiveViewModel) -> some View {
    NavigationStack { LiveView(viewModel: viewModel) }
}

#Preview("Walking") { screen(.preview()) }
#Preview("One Spot visited") { screen(.preview(visited: 1)) }
#Preview("Every Spot visited") { screen(.preview(visited: 2)) }
#Preview("Location denied") { screen(.preview(location: NoLocation())) }
#Preview("Largest text") { screen(.preview()).dynamicTypeSize(.accessibility5) }
#endif
