#if DEBUG
import Core
import Foundation
import Models
import SwiftUI

extension DiscoverMapViewModel {
    /// The real ViewModel on the stub repositories. `now` defaults to the preview clock (November: no monsoon note).
    static func preview(
        _ mode: StubMode = .loaded, offline: Bool = false, now: (@Sendable () -> Date)? = nil
    ) -> DiscoverMapViewModel {
        let deps = AppDependencies.preview(mode)
        deps.network.forceOffline(offline)
        return DiscoverMapViewModel(
            hangouts: deps.hangouts, places: deps.places, photos: deps.photos, library: deps.libraryStore,
            network: deps.network, router: deps.router, now: now ?? deps.now)
    }

    /// 15 July 2026 in Pune, for the monsoon preview.
    static let previewMonsoonDay: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 12)) ?? SampleData.day
    }()
}

private func discover(_ viewModel: DiscoverMapViewModel) -> some View {
    NavigationStack { DiscoverMapView(viewModel: viewModel) }
}

#Preview("Loaded") { discover(.preview()) }
#Preview("Loading") { discover(.preview(.neverReturns)) }
#Preview("Empty") { discover(.preview(.empty)) }
#Preview("Error") { discover(.preview(.failing)) }
#Preview("Offline") { discover(.preview(offline: true)) }
#Preview("Monsoon") {
    let july = DiscoverMapViewModel.previewMonsoonDay      // a plain Date, safe to capture in the clock closure
    discover(.preview(now: { july }))
}
#Preview("Large text") { discover(.preview()).dynamicTypeSize(.accessibility3) }
#endif
