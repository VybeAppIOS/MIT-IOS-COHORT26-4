import SwiftUI

/// A quieter button for the second action on a screen (for example Cancel next to a PrimaryButton).
public struct SecondaryButton: View {
    private let title: VybeText
    private let action: () -> Void

    public init(_ title: LocalizedStringResource, action: @escaping () -> Void) {
        self.title = .fixed(title)
        self.action = action
    }

    public init(verbatim title: String, action: @escaping () -> Void) {
        self.title = .verbatim(title)
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            title.text
                .font(Theme.Font.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: Theme.Radius.medium))
        .controlSize(.large)
        .tint(Theme.Color.accent)
    }
}

#Preview("SecondaryButton states") {
    VStack(spacing: Theme.Spacing.large) {
        SecondaryButton(verbatim: "Save for later") {}
        SecondaryButton(verbatim: "Save for later") {}.disabled(true)
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
