import SwiftUI

/// A tappable row that opens another screen: title, optional subtitle and icon, and a chevron.
public struct NavRow: View {
    private let title: VybeText
    private let subtitle: String?
    private let systemImage: String?
    private let action: () -> Void

    public init(
        _ title: LocalizedStringResource, subtitle: String? = nil, systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = .fixed(title)
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.action = action
    }

    public init(
        verbatim title: String, subtitle: String? = nil, systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = .verbatim(title)
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(Theme.Color.accent)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                    title.text.font(Theme.Font.body)
                    if let subtitle {
                        Text(verbatim: subtitle)
                            .font(Theme.Font.subheadline)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.Color.textPrimary)
    }
}

#Preview("NavRow") {
    VStack(spacing: Theme.Spacing.small) {
        NavRow(verbatim: "Saved Hangouts") {}
        NavRow(verbatim: "Area", subtitle: "Kothrud", systemImage: "mappin.and.ellipse") {}
        NavRow(
            verbatim: "A very long row title that has to wrap onto a second line near Paud Road and Karve Road",
            subtitle: "Erandwane", systemImage: "map"
        ) {}
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("NavRow, large text") {
    NavRow(verbatim: "Area", subtitle: "Kothrud", systemImage: "mappin.and.ellipse") {}
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
        .dynamicTypeSize(.accessibility3)
}
