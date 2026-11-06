import Design
import SwiftUI

/// A photo-led card for one Hangout, in three styles:
/// - `.regular`: lists (Search, Saved, Profile);
/// - `.compact`: the map preview card and a Hangout shared in chat;
/// - `.featured`: the Picks row, with the title over the photo.
/// The whole card is one button and one VoiceOver element ("Hangout: title, 3 Spots, ₹150–400, about 2 h, Picks").
public struct HangoutCard: View {
    public enum Style: Sendable {
        case regular
        case compact
        case featured
    }

    private let data: HangoutCardData
    private let style: Style
    private let action: () -> Void

    public init(_ data: HangoutCardData, style: Style = .regular, action: @escaping () -> Void) {
        self.data = data
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            card
                .contentShape(.rect(cornerRadius: Theme.Radius.large))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: data.accessibilityText))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder private var card: some View {
        switch style {
        case .regular: RegularCard(data: data)
        case .compact: CompactCard(data: data)
        case .featured: FeaturedCard(data: data)
        }
    }
}

// MARK: - Styles

private struct RegularCard: View {
    let data: HangoutCardData

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            PlaceImage(url: data.coverURL, aspectRatio: 16 / 9)
                .overlay(alignment: .topLeading) { CardMarks(data: data).padding(Theme.Spacing.small) }
                .clipShape(.rect(cornerRadius: Theme.Radius.large))
            Text(verbatim: data.title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(2)
            Text(verbatim: data.factsText)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            if let authorName = data.authorName {
                Text(verbatim: authorName)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CompactCard: View {
    let data: HangoutCardData
    @ScaledMetric(relativeTo: .body) private var thumbnailSize = 72.0

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            PlaceImage(url: data.coverURL, aspectRatio: 1)
                .frame(width: thumbnailSize)
                .clipShape(.rect(cornerRadius: Theme.Radius.medium))
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                CardMarks(data: data)
                Text(verbatim: data.title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(2)
                Text(verbatim: data.factsText)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.large))
    }
}

private struct FeaturedCard: View {
    let data: HangoutCardData

    var body: some View {
        // Wider than tall, so the strip stays short and the next card peeks in from the side. The row is already
        // headed "Picks", so the card leaves out the Picks badge and shows only the saved mark.
        PlaceImage(url: data.coverURL, aspectRatio: 4 / 3)
            .overlay(alignment: .bottomLeading) { caption }
            .overlay(alignment: .topTrailing) {
                CardMarks(data: data, showsPick: false).padding(Theme.Spacing.small)
            }
            .clipShape(.rect(cornerRadius: Theme.Radius.large))
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            Text(verbatim: data.title)
                .font(Theme.Font.headline)
                .lineLimit(2)
            Text(verbatim: data.factsText)
                .font(Theme.Font.caption)
                .lineLimit(1)
        }
        .foregroundStyle(Theme.Color.onAccent)
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.scrim)
    }
}

/// The Picks badge (icon and word) and the Saved mark (a bookmark icon only; the card's VoiceOver text already says
/// "Saved").
private struct CardMarks: View {
    let data: HangoutCardData
    var showsPick = true
    @ScaledMetric(relativeTo: .body) private var markSize = 28.0

    var body: some View {
        HStack(spacing: Theme.Spacing.tiny) {
            if data.isPick && showsPick { PickBadge() }
            if data.isSaved {
                Image(systemName: "bookmark.fill")
                    .font(Theme.Font.caption.weight(.semibold))
                    .foregroundStyle(Theme.Color.accent)
                    .frame(width: markSize, height: markSize)
                    .background(Theme.Color.surface, in: Circle())
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
private var longTitle: HangoutCardData {
    var data = HangoutCardData.previewRegular
    data.title = "EXAMPLE A very long Hangout title that has to wrap onto more than two lines on a small phone"
    return data
}

#Preview("Regular") {
    ScrollView {
        VStack(spacing: Theme.Spacing.extraLarge) {
            HangoutCard(.previewPick) {}
            HangoutCard(.previewRegular) {}
            HangoutCard(longTitle) {}
        }
        .padding(Theme.Spacing.large)
    }
    .background(Theme.Color.surface)
}

#Preview("Compact") {
    VStack(spacing: Theme.Spacing.large) {
        HangoutCard(.previewPick, style: .compact) {}
        HangoutCard(longTitle, style: .compact) {}
    }
    .padding(Theme.Spacing.large)
    .background(Theme.Color.surface)
}

#Preview("Featured") {
    ScrollView(.horizontal) {
        HStack(spacing: Theme.Spacing.medium) {
            HangoutCard(.previewPick, style: .featured) {}
                .containerRelativeFrame(.horizontal, count: 3, span: 2, spacing: Theme.Spacing.medium)
            HangoutCard(.previewRegular, style: .featured) {}
                .containerRelativeFrame(.horizontal, count: 3, span: 2, spacing: Theme.Spacing.medium)
        }
        .padding(Theme.Spacing.large)
    }
}

#Preview("Large text") {
    ScrollView {
        VStack(spacing: Theme.Spacing.large) {
            HangoutCard(.previewPick) {}
            HangoutCard(.previewPick, style: .compact) {}
        }
        .padding(Theme.Spacing.large)
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
