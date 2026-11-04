import Design
import SwiftUI

/// The mark on an official Vybe Hangout. Icon and word together, never colour alone.
public struct PickBadge: View {
    public init() {}

    public var body: some View {
        BadgeLabel(systemImage: "star.fill", tint: Theme.Color.accent, text: SharedStrings.badgePicks)
    }
}

/// Where a Hangout is in its life: saved, a draft, scheduled, live or done.
public struct StatusBadge: View {
    public enum Status: Sendable, CaseIterable {
        case saved, draft, scheduled, live, done

        /// The words shown (and read by VoiceOver) for this status.
        var title: String {
            switch self {
            case .saved: SharedStrings.badgeSaved
            case .draft: SharedStrings.badgeDraft
            case .scheduled: SharedStrings.badgeScheduled
            case .live: SharedStrings.badgeLive
            case .done: SharedStrings.badgeDone
            }
        }

        /// A different symbol per status, so the state is never colour alone.
        var systemImage: String {
            switch self {
            case .saved: "bookmark.fill"
            case .draft: "pencil"
            case .scheduled: "calendar"
            case .live: "location.fill"
            case .done: "checkmark.circle.fill"
            }
        }
    }

    private let status: Status

    public init(_ status: Status) {
        self.status = status
    }

    public var body: some View {
        BadgeLabel(systemImage: status.systemImage, tint: tint, text: status.title)
    }

    private var tint: Color {
        switch status {
        case .saved, .scheduled: Theme.Color.accent
        case .draft: Theme.Color.textSecondary
        case .live, .done: Theme.Color.positive
        }
    }
}

/// Shown on a Place that the authorities have closed.
public struct ClosedBadge: View {
    public init() {}

    public var body: some View {
        BadgeLabel(
            systemImage: "exclamationmark.triangle.fill",
            tint: Theme.Color.warning,
            text: SharedStrings.badgeClosed
        )
    }
}

private struct BadgeLabel: View {
    let systemImage: String
    let tint: Color
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.tiny) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(verbatim: text)
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .font(Theme.Font.caption)
        .padding(.horizontal, Theme.Spacing.small)
        .padding(.vertical, Theme.Spacing.tiny)
        // A rounded rectangle, not a capsule: the label can wrap onto several lines at large text sizes.
        .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Color.separator))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

private struct BadgesSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            PickBadge()
            ClosedBadge()
            ForEach(StatusBadge.Status.allCases, id: \.self) { status in
                StatusBadge(status)
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.surface)
    }
}

#Preview("Badges") {
    BadgesSample()
}

#Preview("Badges, large text") {
    BadgesSample()
        .dynamicTypeSize(.accessibility3)
}
