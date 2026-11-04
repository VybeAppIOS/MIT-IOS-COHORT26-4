import Design
import SwiftUI

/// Tags laid out left to right, wrapping onto new lines. The tags are display text shown as given.
public struct TagRow: View {
    private let tags: [String]

    public init(tags: [String]) {
        self.tags = tags
    }

    public var body: some View {
        FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
            // Offsets are the IDs, so a repeated tag cannot confuse SwiftUI.
            ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                Text(verbatim: tag)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.horizontal, Theme.Spacing.small)
                    .padding(.vertical, Theme.Spacing.tiny)
                    .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.medium))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Color.separator))
            }
        }
        // FlowLayout is only as wide as its widest row; this keeps a few short tags at the leading edge.
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

private let twoTags = ["Café", "Board-game café"]
private let twelveTags = [
    "Café", "Street food", "Chai/tapri", "Dessert", "Park/garden", "Viewpoint/hill",
    "Gaming/arcade", "Bowling", "Cinema", "Museum", "Heritage/temple", "Study café"
]

private struct TagRowSample: View {
    let tags: [String]

    var body: some View {
        TagRow(tags: tags)
            .padding(Theme.Spacing.large)
            .background(Theme.Color.surface)
    }
}

#Preview("TagRow, 2 tags") {
    TagRowSample(tags: twoTags)
}

#Preview("TagRow, 12 tags") {
    TagRowSample(tags: twelveTags)
}

#Preview("TagRow, narrow") {
    TagRowSample(tags: twelveTags)
        .frame(width: 220)
}

#Preview("TagRow, large text") {
    ScrollView { TagRowSample(tags: twelveTags) }
        .dynamicTypeSize(.accessibility3)
}
