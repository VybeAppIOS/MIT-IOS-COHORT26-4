import SwiftUI

/// A small capsule button for an action inside a row or a card: Add, Cancel, Accept, Ignore, Retry.
/// Use `PrimaryButton` and `SecondaryButton` for the one main action at the bottom of a screen.
///
/// It is about 44 to 46 pt tall at the normal text size (the 44 pt floor is on the button, never inside the label),
/// grows with the text size, and wraps onto more lines instead of turning into a circle or cutting words off.
public struct PillButton: View {
    /// Filled with the accent colour, or a quiet grey fill.
    public enum Style: Sendable {
        case prominent
        case bordered
    }

    private let title: VybeText
    private let style: Style
    private let role: ButtonRole?
    private let fillsWidth: Bool
    private let action: () -> Void
    // On top of the system padding of a regular button; scales with the text so the pill keeps its shape.
    @ScaledMetric(relativeTo: .subheadline) private var verticalPadding = (Theme.Spacing.small + Theme.Spacing.tiny) / 2

    public init(
        _ title: LocalizedStringResource, style: Style = .bordered, role: ButtonRole? = nil,
        fillsWidth: Bool = false, action: @escaping () -> Void
    ) {
        self.title = .fixed(title)
        self.style = style
        self.role = role
        self.fillsWidth = fillsWidth
        self.action = action
    }

    public init(
        verbatim title: String, style: Style = .bordered, role: ButtonRole? = nil,
        fillsWidth: Bool = false, action: @escaping () -> Void
    ) {
        self.title = .verbatim(title)
        self.style = style
        self.role = role
        self.fillsWidth = fillsWidth
        self.action = action
    }

    public var body: some View {
        styledButton
            .buttonBorderShape(.capsule)
            .controlSize(.regular)
            // The style adds its own padding, so the 44 pt floor goes on the button, not inside the label.
            .frame(minHeight: Theme.Size.minTapTarget)
            .tint(role == .destructive ? Theme.Color.critical : Theme.Color.accent)
    }

    private var button: some View {
        Button(role: role, action: action) {
            title.text
                .font(Theme.Font.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
        }
    }

    @ViewBuilder private var styledButton: some View {
        switch style {
        case .prominent: button.buttonStyle(.borderedProminent)
        case .bordered: button.buttonStyle(.bordered)
        }
    }
}

#Preview("PillButton states") {
    VStack(alignment: .leading, spacing: Theme.Spacing.large) {
        HStack(spacing: Theme.Spacing.small) {
            PillButton(verbatim: "Accept", style: .prominent, fillsWidth: true) {}
            PillButton(verbatim: "Ignore", fillsWidth: true) {}
        }
        HStack {
            Text(verbatim: "Sample Aarav").font(Theme.Font.body)
            Spacer()
            PillButton(verbatim: "Add", style: .prominent) {}
        }
        HStack {
            Text(verbatim: "Sample Isha").font(Theme.Font.body)
            Spacer()
            PillButton(verbatim: "Cancel request") {}
        }
        PillButton(verbatim: "Add", style: .prominent) {}.disabled(true)
        PillButton(verbatim: "Remove", role: .destructive) {}
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("PillButton, large text") {
    VStack(alignment: .leading, spacing: Theme.Spacing.large) {
        HStack(spacing: Theme.Spacing.small) {
            PillButton(verbatim: "Accept", style: .prominent, fillsWidth: true) {}
            PillButton(verbatim: "Ignore", fillsWidth: true) {}
        }
        PillButton(verbatim: "Cancel request") {}
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
    .dynamicTypeSize(.accessibility3)
}
