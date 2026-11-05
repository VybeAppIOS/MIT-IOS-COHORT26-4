import SwiftUI

/// The zoom from a card to its detail screen (a card on Discover opening a Hangout).
///
/// A zoom needs both ends to share one `Namespace`. The App's navigation host creates it once per stack and puts it in
/// the environment (`vybeZoomNamespace`). A screen then marks the two ends and never sees the namespace:
///
///     card.vybeZoomSource(id: hangout.id)              // on the card that is tapped
///     detail.vybeZoomDestination(sourceID: hangout.id) // on the screen that opens
///
/// With no namespace in the environment (previews, tests) both do nothing. Reduce Motion is handled by the system.
public extension EnvironmentValues {
    @Entry var vybeZoomNamespace: Namespace.ID?
}

public extension View {
    /// Marks this view as where a zoom starts. `id` must be the same value the destination uses.
    func vybeZoomSource(id: some Hashable & Sendable) -> some View {
        modifier(ZoomSourceModifier(id: id))
    }

    /// Makes this screen open with a zoom from the source that used the same `sourceID`.
    func vybeZoomDestination(sourceID: some Hashable & Sendable) -> some View {
        modifier(ZoomDestinationModifier(sourceID: sourceID))
    }
}

private struct ZoomSourceModifier<ID: Hashable & Sendable>: ViewModifier {
    let id: ID
    @Environment(\.vybeZoomNamespace) private var namespace

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

private struct ZoomDestinationModifier<ID: Hashable & Sendable>: ViewModifier {
    let sourceID: ID
    @Environment(\.vybeZoomNamespace) private var namespace

    func body(content: Content) -> some View {
        if let namespace {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
    }
}
