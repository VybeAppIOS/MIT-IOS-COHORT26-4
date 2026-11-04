import SwiftUI

/// "You're offline. Showing what you last saw." (IA X1, PRODUCT 4 Offline).
/// `LoadStateView` shows it whenever the content is stale (`isStale == true`), whatever made it stale,
/// so the text says "offline" even when old content is shown for another reason.
/// VoiceOver reads it as one sentence; the icon is decorative.
public struct OfflineBanner: View {
    public init() {}

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.small) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(Theme.Color.warning)
                .accessibilityHidden(true)
            Text(StateViewText.offlineBanner)
                .foregroundStyle(Theme.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(Theme.Font.footnote)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.surfaceRaised)
        .accessibilityElement(children: .combine)
    }
}

public extension View {
    /// Makes the controls inside read-only while offline (PRODUCT 4: "read-only, with no actions").
    /// Screens decide where to apply it; `LoadStateView` does not apply it by itself.
    func offlineReadOnly(_ isOffline: Bool) -> some View {
        disabled(isOffline)
    }
}

#if DEBUG
#Preview("Banner") { OfflineBanner() }
#Preview("Large text") { OfflineBanner().dynamicTypeSize(.accessibility3) }
#endif
