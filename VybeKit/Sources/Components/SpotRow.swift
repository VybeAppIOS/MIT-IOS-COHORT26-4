import Design
import Models
import SwiftUI

/// One Spot in a Hangout: a numbered marker (a checkmark once visited), a thumbnail, the Place name and details,
/// and any warning. The state always shows as an icon and words, never colour alone. The editor variant adds a
/// reorder handle. The row is one VoiceOver element: "Spot 2 of 4, Name, Café · 45 min, Visited".
public struct SpotRow: View {
    private let data: SpotRowData
    private let showsReorderHandle: Bool
    @ScaledMetric(relativeTo: .body) private var thumbnailSize = 56.0

    public init(_ data: SpotRowData, showsReorderHandle: Bool = false) {
        self.data = data
        self.showsReorderHandle = showsReorderHandle
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            SpotMarker(order: data.order, state: data.state)
            PlaceImage(url: data.thumbnailURL, aspectRatio: 1)
                .frame(width: thumbnailSize)
                .clipShape(.rect(cornerRadius: Theme.Radius.small))
            details
            if showsReorderHandle {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(Theme.Color.textSecondary)
                    .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            }
        }
        .frame(minHeight: Theme.Size.minTapTarget)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: data.accessibilityText))
        .accessibilityHint(showsReorderHandle ? Text(verbatim: ComponentStrings.spotReorder) : Text(verbatim: ""))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            Text(verbatim: data.placeName)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text(verbatim: data.detailText)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            if let note = data.note {
                Text(verbatim: note)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            stateLabel
            if data.hasDuplicateWarning {
                Label {
                    Text(verbatim: ComponentStrings.spotDuplicate)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.Color.warning)
                }
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.Color.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var stateLabel: some View {
        switch data.state {
        case .normal:
            EmptyView()
        case .visited:
            Label {
                Text(verbatim: ComponentStrings.spotVisited)
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.Color.positive)
            }
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.Color.textPrimary)
        case .current:
            Label {
                Text(verbatim: ComponentStrings.spotCurrent)
            } icon: {
                Image(systemName: "location.fill").foregroundStyle(Theme.Color.accent)
            }
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.Color.textPrimary)
        case .closedByAuthorities:
            ClosedBadge()
        }
    }
}

/// The circle on the left: the Spot's number, or a checkmark once visited.
private struct SpotMarker: View {
    let order: Int
    let state: SpotRowData.State
    @ScaledMetric(relativeTo: .body) private var diameter = 32.0

    var body: some View {
        ZStack {
            Circle().fill(fill)
            if state == .visited {
                Image(systemName: "checkmark")
            } else {
                Text(order, format: .number)
            }
        }
        .font(Theme.Font.subheadline.weight(.semibold))
        .foregroundStyle(onFill)
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }

    /// A visited Spot's circle turns lime (a bright tint, so its checkmark is dark ink, not white); the current Spot's
    /// is the accent; the others are plain.
    private var fill: Color {
        switch state {
        case .visited: Theme.Color.lime
        case .current: Theme.Color.accent
        default: Theme.Color.surfaceRaised
        }
    }

    /// Text on the circle: dark ink on lime, light on the accent, the normal text colour on the plain one.
    private var onFill: Color {
        switch state {
        case .visited: Theme.Color.ink
        case .current: Theme.Color.onAccent
        default: Theme.Color.textPrimary
        }
    }
}

// MARK: - Previews

#if DEBUG
private func previewRow(_ state: SpotRowData.State, order: Int = 1, duplicate: Bool = false) -> SpotRowData {
    let spot = SampleData.evening.spots[0]
    return SpotRowData(spot: spot, place: SampleData.cafe, order: order, total: 4, state: state,
                       hasDuplicateWarning: duplicate)
}

#Preview("Every state") {
    ScrollView {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SpotRow(previewRow(.normal, order: 1))
            SpotRow(previewRow(.visited, order: 2))
            SpotRow(previewRow(.current, order: 3))
            SpotRow(previewRow(.closedByAuthorities, order: 4))
            SpotRow(previewRow(.normal, order: 2, duplicate: true), showsReorderHandle: true)
        }
        .padding(Theme.Spacing.large)
    }
    .background(Theme.Color.surface)
}

#Preview("Large text") {
    VStack(spacing: Theme.Spacing.large) {
        SpotRow(previewRow(.visited, order: 2))
        SpotRow(previewRow(.normal, duplicate: true), showsReorderHandle: true)
    }
    .padding(Theme.Spacing.large)
    .dynamicTypeSize(.accessibility3)
}
#endif
