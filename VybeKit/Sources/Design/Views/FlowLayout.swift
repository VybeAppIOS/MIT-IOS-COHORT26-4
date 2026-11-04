import SwiftUI

/// Places children left to right and wraps onto a new line when a row is full. Used for tag chips.
public struct FlowLayout: Layout {
    public var spacing: CGFloat
    public var lineSpacing: CGFloat

    /// Pass `Theme.Spacing` tokens. Layouts are not main-actor, so they cannot read Theme themselves.
    public init(spacing: CGFloat, lineSpacing: CGFloat) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews: subviews, maxWidth: proposal.width ?? .infinity).size
    }

    public func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        let arrangement = arrange(subviews: subviews, maxWidth: bounds.width)
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var rowX: CGFloat = 0
        var rowY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            // A child wider than the row is asked to fit the row, so long text wraps instead of overflowing.
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth.isFinite ? maxWidth : nil, height: nil))
            if rowX > 0, rowX + size.width > maxWidth {
                rowY += rowHeight + lineSpacing
                rowX = 0
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: rowX, y: rowY), size: size))
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, rowX - spacing)
        }
        return (frames, CGSize(width: widest, height: rowY + rowHeight))
    }
}

/// Keeps reading text from stretching across a very wide window.
/// The maximum width is a design decision that has not been made yet: until `Theme.Size.readableContentMaxWidth`
/// has a value, or a caller passes one, the content simply fills the width.
public struct ReadableContent<Content: View>: View {
    private let maxWidth: CGFloat?
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.init(maxWidth: Theme.Size.readableContentMaxWidth, content: content)
    }

    public init(maxWidth: CGFloat?, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: maxWidth ?? .infinity)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

private let sampleTags = [
    "Café", "Street food", "Chai/tapri", "Restaurant", "Dessert", "Juice/shakes", "Trek", "Fort",
    "Viewpoint/hill", "Lake/dam", "Park/garden", "Camping", "Gaming/arcade", "Bowling", "Go-karting",
    "Trampoline", "Escape room", "Board-game café", "Karaoke", "Cinema", "Comedy/open mic", "Live music",
    "Museum", "Heritage/temple", "Art gallery", "Theatre", "Bookstore/library", "Street market", "Thrift",
    "Study café"
]

private struct SampleChips: View {
    let tags: [String]

    var body: some View {
        FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
            ForEach(tags, id: \.self) { tag in
                Text(verbatim: tag)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .background(Theme.Color.surfaceRaised, in: .capsule)
            }
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
    }
}

#Preview("3 chips") {
    SampleChips(tags: Array(sampleTags.prefix(3)))
}

#Preview("30 chips") {
    ScrollView { SampleChips(tags: sampleTags) }
}

#Preview("30 chips, narrow") {
    ScrollView { SampleChips(tags: sampleTags) }
        .frame(width: 220)
}

#Preview("30 chips, large text") {
    ScrollView { SampleChips(tags: sampleTags) }
        .dynamicTypeSize(.accessibility3)
}

#Preview("ReadableContent, 300 pt limit") {
    ReadableContent(maxWidth: 300) {
        Text(verbatim: "Kothrud Hangouts: a calm evening with chai and a short walk. The preview sets the limit.")
            .font(Theme.Font.body)
    }
    .padding(Theme.Spacing.large)
}
