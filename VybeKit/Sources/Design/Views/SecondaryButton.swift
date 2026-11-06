import SwiftUI

/// A quieter button, about 48 pt tall, for the second action on a screen (for example Cancel next to a PrimaryButton).
public struct SecondaryButton: View {
    private let title: VybeText
    private let role: ButtonRole?
    private let action: () -> Void
    // On top of the system padding of a regular button: about 48 pt at the normal text size, grows with text.
    @ScaledMetric(relativeTo: .headline) private var verticalPadding = Theme.Spacing.small

    public init(_ title: LocalizedStringResource, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = .fixed(title)
        self.role = role
        self.action = action
    }

    public init(verbatim title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = .verbatim(title)
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            title.text
                .font(Theme.Font.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle(
            look: .tinted, tint: role == .destructive ? Theme.Color.critical : Theme.Color.accent,
            cornerRadius: Theme.Radius.medium))
        // The style adds its own padding, so the 44 pt floor goes on the button, not inside the label.
        .frame(minHeight: Theme.Size.minTapTarget)
    }
}

#Preview("SecondaryButton states") {
    VStack(spacing: Theme.Spacing.large) {
        SecondaryButton(verbatim: "Save for later") {}
        SecondaryButton(verbatim: "Save for later") {}.disabled(true)
        SecondaryButton(verbatim: "Leave and block", role: .destructive) {}
        SecondaryButton(verbatim: "Share this Hangout with friends near Karve Road") {}
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("SecondaryButton, large text") {
    SecondaryButton(verbatim: "Save for later") {}
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
        .dynamicTypeSize(.accessibility3)
}
