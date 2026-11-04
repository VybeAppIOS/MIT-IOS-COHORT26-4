import SwiftUI

/// "Nothing here yet": an icon, one friendly line in our tone, and an optional action button.
/// Built on `ContentUnavailableView`, so VoiceOver reads the line and the button, and it wraps at large text sizes.
/// `message` and `actionTitle` are display text the ViewModel already localized (`String(localized:)`).
public struct EmptyStateView: View {
    private let systemImage: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(systemImage: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text(message)
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.Color.textPrimary)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Theme.Font.headline)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Theme.Color.accent)
            }
        }
    }
}

#if DEBUG
#Preview("With action") {
    EmptyStateView(systemImage: "bookmark", message: "No saved Hangouts yet.",
                   actionTitle: "Find a Hangout", action: {})
}
#Preview("No action") {
    EmptyStateView(systemImage: "bookmark", message: "No saved Hangouts yet.")
}
#Preview("Large text") {
    EmptyStateView(systemImage: "bookmark", message: "No saved Hangouts yet.",
                   actionTitle: "Find a Hangout", action: {})
        .dynamicTypeSize(.accessibility3)
}
#endif
