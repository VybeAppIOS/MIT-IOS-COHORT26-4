import Design
import SwiftUI

/// The mark on an official Vybe Hangout. Icon and word together, never colour alone.
public struct PickBadge: View {
    public init() {}

    public var body: some View {
        BadgeLabel(systemImage: "star.fill", tint: Theme.Color.accent) {
            Text("Picks")
        }
    }
}

/// Where a Hangout is in its life: saved, a draft, scheduled, live or done.
public struct StatusBadge: View {
    public enum Status: Sendable, CaseIterable {
        case saved, draft, scheduled, live, done
    }

    private let status: Status

    public init(_ status: Status) {
        self.status = status
    }

    public var body: some View {
        BadgeLabel(systemImage: systemImage, tint: tint) { label }
    }

    private var label: Text {
        switch status {
        case .saved: Text("Saved")
        case .draft: Text("Draft")
        case .scheduled: Text("Scheduled")
        case .live: Text("Live")
        case .done: Text("Done")
        }
    }

    private var systemImage: String {
        switch status {
        case .saved: "bookmark.fill"
        case .draft: "pencil"
        case .scheduled: "calendar"
        case .live: "location.fill"
        case .done: "checkmark.circle.fill"
        }
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
        BadgeLabel(systemImage: "exclamationmark.triangle.fill", tint: Theme.Color.warning) {
            Text("Closed by authorities")
        }
    }
}

private struct BadgeLabel: View {
    let systemImage: String
    let tint: Color
    let text: Text

    init(systemImage: String, tint: Color, @ViewBuilder text: () -> Text) {
        self.systemImage = systemImage
        self.tint = tint
        self.text = text()
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.tiny) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            text
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .font(Theme.Font.caption)
        .padding(.horizontal, Theme.Spacing.small)
        .padding(.vertical, Theme.Spacing.tiny)
        .background(Theme.Color.surfaceRaised, in: .capsule)
        .overlay(Capsule().stroke(Theme.Color.separator))
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
