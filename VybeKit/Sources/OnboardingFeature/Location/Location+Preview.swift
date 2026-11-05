#if DEBUG
import Core
import SwiftUI

/// A location service that always gives the same answer (previews only).
private struct PreviewLocation: LocationService {
    let authorization: LocationAuthorization
    func updates() -> AsyncStream<LocationSample> { AsyncStream { $0.finish() } }
    func requestWhenInUse() {}
}

extension LocationViewModel {
    /// The real ViewModel on the stubs. Previews can never show the system prompt.
    static func preview(_ authorization: LocationAuthorization = .notDetermined) -> LocationViewModel {
        let deps = AppDependencies.preview()
        return LocationViewModel(
            location: PreviewLocation(authorization: authorization), hangouts: deps.hangouts, places: deps.places,
            session: deps.session, router: deps.router)
    }
}

private func screen(_ viewModel: LocationViewModel) -> some View {
    NavigationStack { LocationView(viewModel: viewModel) }
}

#Preview("Explain") { screen(.preview()) }
#Preview("Pick an area") {
    let viewModel = LocationViewModel.preview()
    screen(viewModel).onAppear { viewModel.notNowTapped() }
}
#Preview("Pick an area, could not ask") {
    let viewModel = LocationViewModel.preview()
    screen(viewModel).task { await viewModel.allowTapped() }      // no prompt in previews: the note appears
}
#Preview("Large text") { screen(.preview()).dynamicTypeSize(.accessibility3) }
#endif
