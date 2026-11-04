import SwiftUI

/// A heading above a group of rows. VoiceOver lists it as a heading so people can jump between sections.
public struct SectionHeader: View {
    private let title: VybeText

    public init(_ title: LocalizedStringResource) {
        self.title = .fixed(title)
    }

    public init(verbatim title: String) {
        self.title = .verbatim(title)
    }

    public var body: some View {
        title.text
            .font(Theme.Font.headline)
            .foregroundStyle(Theme.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview("SectionHeader") {
    VStack(spacing: Theme.Spacing.large) {
        SectionHeader(verbatim: "Nearby in Kothrud")
        SectionHeader(verbatim: "A long section title that wraps at larger text sizes around Erandwane")
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("SectionHeader, large text") {
    SectionHeader(verbatim: "Nearby in Kothrud")
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
        .dynamicTypeSize(.accessibility3)
}
