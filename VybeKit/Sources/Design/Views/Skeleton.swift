import SwiftUI

/// A grey rounded rectangle that stands in for a picture or card while content loads.
/// It does not move, so Reduce Motion needs nothing. Give it a size with `.frame` or `.aspectRatio`.
public struct SkeletonBlock: View {
    private let cornerRadius: CGFloat

    public init() {
        self.init(cornerRadius: Theme.Radius.medium)
    }

    public init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Theme.Color.separator)
            .accessibilityHidden(true)
    }
}

/// A grey bar that stands in for one line of text. Its height follows the text size.
/// `widthFraction` (0 to 1) is the share of the available width it fills.
public struct SkeletonLine: View {
    @ScaledMetric(relativeTo: .body) private var height = Theme.Spacing.medium
    private let widthFraction: CGFloat

    public init(widthFraction: CGFloat = 1) {
        self.widthFraction = min(max(widthFraction, 0), 1)
    }

    public var body: some View {
        FractionalWidth(fraction: widthFraction) {
            Capsule()
                .fill(Theme.Color.separator)
                .frame(height: height)
        }
        .accessibilityHidden(true)
    }
}

/// Sizes its single child to a share of the width it is offered, left aligned.
private struct FractionalWidth: Layout {
    let fraction: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let width = proposal.width.map { $0 * fraction }
        let size = child.sizeThatFits(ProposedViewSize(width: width, height: proposal.height))
        return CGSize(width: proposal.width ?? size.width, height: size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let child = subviews.first else { return }
        let width = bounds.width * fraction
        let childProposal = ProposedViewSize(width: width, height: bounds.height)
        child.place(at: bounds.origin, anchor: .topLeading, proposal: childProposal)
    }
}

// MARK: - Previews

private struct SkeletonCardSample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SkeletonBlock()
                .aspectRatio(16 / 9, contentMode: .fit)
            SkeletonLine()
            SkeletonLine(widthFraction: 0.6)
        }
        .padding(Theme.Spacing.large)
        .background(Theme.Color.surface)
    }
}

#Preview("Skeleton card") {
    SkeletonCardSample()
}

#Preview("Skeleton card, large text") {
    SkeletonCardSample()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Skeleton card, narrow") {
    SkeletonCardSample()
        .frame(width: 200)
}
