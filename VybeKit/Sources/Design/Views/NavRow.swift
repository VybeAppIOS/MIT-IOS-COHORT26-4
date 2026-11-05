import SwiftUI

/// A tappable row that opens another screen: title, optional subtitle and icon, and a chevron.
public struct NavRow: View {
    private let title: VybeText
    private let subtitle: String?
    private let value: String?
    private let systemImage: String?
    private let action: () -> Void
    /// Icons differ in width, so each gets the same width and the titles line up.
    @ScaledMetric private var iconWidth: CGFloat = 28

    public init(
        _ title: LocalizedStringResource, subtitle: String? = nil, value: String? = nil, systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = .fixed(title)
        self.subtitle = subtitle
        self.value = value
        self.systemImage = systemImage
        self.action = action
    }

    public init(
        verbatim title: String, subtitle: String? = nil, value: String? = nil, systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = .verbatim(title)
        self.subtitle = subtitle
        self.value = value
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(Theme.Color.accent)
                        .frame(width: iconWidth)
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
                if let value {
                    Text(verbatim: value)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Theme.Spacing.small)
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
