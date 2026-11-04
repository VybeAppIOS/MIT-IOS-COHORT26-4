import SwiftUI

/// A row with a switch, for settings.
public struct ToggleRow: View {
    private let title: VybeText
    private let subtitle: String?
    @Binding private var isOn: Bool

    public init(_ title: LocalizedStringResource, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = .fixed(title)
        self.subtitle = subtitle
        self._isOn = isOn
    }

    public init(verbatim title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = .verbatim(title)
        self.subtitle = subtitle
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                title.text.font(Theme.Font.body)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .font(Theme.Font.subheadline)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .tint(Theme.Color.accent)
        .foregroundStyle(Theme.Color.textPrimary)
        .frame(minHeight: Theme.Size.minTapTarget)
    }
}

private struct ToggleRowDemo: View {
    @State private var showInSearch = true
    @State private var commentsOn = false

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            ToggleRow(verbatim: "Show me in search", isOn: $showInSearch)
            ToggleRow(
                verbatim: "Allow comments",
                subtitle: "Only friends from your Kothrud group can comment on your Hangouts",
                isOn: $commentsOn
            )
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
    }
}

#Preview("ToggleRow") {
    ToggleRowDemo()
}

#Preview("ToggleRow, large text") {
    ToggleRowDemo()
        .dynamicTypeSize(.accessibility3)
}
