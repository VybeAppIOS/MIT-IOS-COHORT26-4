import Models
import SwiftUI

/// A failed first load: the error's friendly message (`AppError.message`) and a Retry button.
/// Retry appears only when `onRetry` is given. Built on `ContentUnavailableView`, so VoiceOver reads the message
/// and the button, and it wraps at large text sizes.
public struct ErrorView: View {
    private let error: AppError
    private let onRetry: (() -> Void)?

    public init(_ error: AppError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text(error.message)
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.Color.textPrimary)
            } icon: {
                Image(systemName: error == .offline ? "wifi.slash" : "exclamationmark.triangle")
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        } actions: {
            if let onRetry {
                Button(StateViewText.retry, action: onRetry)
                    .font(Theme.Font.headline)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Theme.Color.accent)
            }
        }
    }
}

#if DEBUG
#Preview("Unknown error") { ErrorView(.unknown, onRetry: {}) }
#Preview("Offline") { ErrorView(.offline, onRetry: {}) }
#Preview("Not found, no retry") { ErrorView(.notFound) }
#Preview("Large text") { ErrorView(.unknown, onRetry: {}).dynamicTypeSize(.accessibility3) }
#endif
