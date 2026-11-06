import Design
import SwiftUI

/// One Spot of a Hangout on the Discover map: a numbered dot. The dots of one Hangout are joined by a line, so the
/// map shows a route, not a single place. The selected Hangout's dots grow a little; a Pick's dots are accent-coloured.
struct RouteSpotPin: View {
    let title: String
    let number: Int
    let total: Int
    let isPick: Bool
    let isSelected: Bool

    @ScaledMetric(relativeTo: .body) private var diameter = 26.0

    var body: some View {
        Text(number, format: .number)
            .font(Theme.Font.caption.weight(.bold))
            .foregroundStyle(isPick ? Theme.Color.onAccent : Theme.Color.textPrimary)
            .frame(width: diameter, height: diameter)
            .background(isPick ? Theme.Color.accent : Theme.Color.surface, in: Circle())
            .overlay(Circle().strokeBorder(isPick ? Theme.Color.surface : Theme.Color.accent, lineWidth: 2.5))
            .scaleEffect(isSelected ? 1.25 : 1)
            .vybeAnimation(Theme.Motion.standard, value: isSelected)
            .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            .contentShape(.circle)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: label))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// "Coffee and Books Crawl, Spot 2 of 3"
    private var label: String {
        String(format: String(localized: "discover.map.spot.label", bundle: #bundle), title, number, total)
    }
}

#Preview("Route dots") {
    HStack(spacing: Theme.Spacing.large) {
        RouteSpotPin(title: "Coffee and Books Crawl", number: 1, total: 3, isPick: true, isSelected: false)
        RouteSpotPin(title: "Coffee and Books Crawl", number: 2, total: 3, isPick: true, isSelected: true)
        RouteSpotPin(title: "Friend's Hangout", number: 3, total: 3, isPick: false, isSelected: false)
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surfaceRaised)
}
