import Core
import Foundation
import Models

/// H4: the bar above the tab bar while a Hangout is live but its screen is closed (minimised). It names the current
/// Spot and shows the elapsed time; a tap brings the live screen back. It disappears when the run ends.
@MainActor @Observable
final class MiniBarViewModel {
    /// Spot names in the Hangout's order, loaded for the live run's Hangout.
    private(set) var spots: [(id: SpotID, name: String)] = []

    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let liveStore: LiveHangoutStore
    private let router: Router
    private var loadedFor: HangoutID?

    /// Cheap: no loading here (ADR 005).
    init(hangouts: any HangoutRepository, places: any PlaceRepository, liveStore: LiveHangoutStore, router: Router) {
        self.hangouts = hangouts
        self.places = places
        self.liveStore = liveStore
        self.router = router
    }

    /// A run is live and its full-screen cover is not up.
    var isVisible: Bool { liveStore.isLive && router.cover == nil }

    /// The live run's Hangout, so the View reloads the Spot names when it changes.
    var liveHangoutID: HangoutID? { liveStore.run?.hangoutID }

    /// Loads the Spot names of the live run's Hangout (once per Hangout).
    func loadSpots() async {
        guard let id = liveHangoutID, id != loadedFor else { return }
        guard let hangout = try? await hangouts.hangout(id: id),
              let found = try? await places.spots(for: hangout) else { return }
        let names = Dictionary(found.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        spots = hangout.spots.compactMap { spot in names[spot.placeID].map { (spot.id, $0) } }
        loadedFor = id
    }

    /// The first Spot not visited yet.
    var currentSpotName: String? {
        let visited = Set(liveStore.run?.visits.map(\.spotID) ?? [])
        return spots.first { !visited.contains($0.id) }?.name
    }

    var hangoutTitle: String { liveStore.run?.card.hangoutTitle ?? "" }

    var startedAt: Date? { liveStore.times?.startedAt }

    /// "Live Hangout, EXAMPLE Café, tap to return"
    var accessibilityLabel: String { MiniBarText.accessibility(currentSpotName ?? hangoutTitle) }

    /// Brings the live screen back.
    func tapped() {
        guard let id = liveHangoutID else { return }
        liveStore.expand()
        router.presentCover(.live(id))
    }
}

/// H4's text, read from LiveFeature's own catalog (`bundle: #bundle`, task X-3).
enum MiniBarText {
    /// "Live Hangout, EXAMPLE Café, tap to return"
    static func accessibility(_ name: String) -> String {
        String(localized: "live.miniBar.accessibility \(name)", bundle: #bundle)
    }
}
