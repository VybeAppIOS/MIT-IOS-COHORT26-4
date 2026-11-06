import SwiftUI

/// A button that shows only an icon. The spoken label is required, so an icon button can never be silent.
public struct IconButton: View {
    private let systemImage: String
    private let label: VybeText
    private let action: () -> Void

    public init(systemImage: String, accessibilityLabel: LocalizedStringResource, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.label = .fixed(accessibilityLabel)
        self.action = action
    }

    public init(systemImage: String, verbatimLabel: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.label = .verbatim(verbatimLabel)
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Theme.Font.title3)
                .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle(look: .plain))
        .foregroundStyle(Theme.Color.textPrimary)
        .accessibilityLabel(label.plain)
    }
}

#Preview("IconButton") {
    HStack(spacing: Theme.Spacing.large) {
        IconButton(systemImage: "bookmark", verbatimLabel: "Save Hangout") {}
        IconButton(systemImage: "square.and.arrow.up", verbatimLabel: "Share Hangout") {}
        IconButton(systemImage: "xmark", verbatimLabel: "Close") {}.disabled(true)
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("IconButton, large text") {
    IconButton(systemImage: "bookmark", verbatimLabel: "Save Hangout") {}
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
        .dynamicTypeSize(.accessibility3)
}
