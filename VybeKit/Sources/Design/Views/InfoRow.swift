import SwiftUI

/// A read-only row: a label and its value. At the largest text sizes the value drops under the label.
public struct InfoRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let title: VybeText
    private let value: String

    public init(_ title: LocalizedStringResource, value: String) {
        self.title = .fixed(title)
        self.value = value
    }

    public init(verbatim title: String, value: String) {
        self.title = .verbatim(title)
        self.value = value
    }

    public var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.tiny))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.medium))
        layout {
            title.text
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: value)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
        }
        .frame(minHeight: Theme.Size.minTapTarget)
        .accessibilityElement(children: .combine)
    }
}

#Preview("InfoRow") {
    VStack(spacing: Theme.Spacing.small) {
        InfoRow(verbatim: "Area", value: "Kothrud")
        InfoRow(verbatim: "Nearest landmark", value: "Karve Road, close to the Paud Road junction")
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("InfoRow, large text") {
    InfoRow(verbatim: "Area", value: "Kothrud")
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
        .dynamicTypeSize(.accessibility3)
}
