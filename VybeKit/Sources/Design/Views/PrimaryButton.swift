import SwiftUI

/// The one main action on a screen: large, full width, with loading and disabled states.
/// It wraps onto more lines at large text sizes instead of cutting the words off.
public struct PrimaryButton: View {
    private let title: VybeText
    private let isLoading: Bool
    private let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    public init(_ title: LocalizedStringResource, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = .fixed(title)
        self.isLoading = isLoading
        self.action = action
    }

    public init(verbatim title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = .verbatim(title)
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.small) {
                if isLoading {
                    ProgressView().tint(Theme.Color.onAccent)
                }
                title.text
                    .font(Theme.Font.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isEnabled ? Theme.Color.onAccent : Theme.Color.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: Theme.Radius.medium))
        .controlSize(.large)
        // The style adds its own padding, so the 44 pt floor goes on the button, not inside the label.
        .frame(minHeight: Theme.Size.minTapTarget)
        .tint(Theme.Color.accent)
        .disabled(isLoading)
        .accessibilityValue(isLoading ? Text("Loading", bundle: .module) : Text(verbatim: ""))
    }
}

#Preview("PrimaryButton states") {
    VStack(spacing: Theme.Spacing.large) {
        PrimaryButton(verbatim: "Start Hangout") {}
        PrimaryButton(verbatim: "Start Hangout", isLoading: true) {}
        PrimaryButton(verbatim: "Start Hangout") {}.disabled(true)
        PrimaryButton(verbatim: "Start Hangout with everyone you saved from the Kothrud café list") {}
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("PrimaryButton, large text") {
    PrimaryButton(verbatim: "Start Hangout") {}
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
        .dynamicTypeSize(.accessibility3)
}
