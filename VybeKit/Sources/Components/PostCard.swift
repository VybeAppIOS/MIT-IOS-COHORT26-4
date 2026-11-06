import Design
import SwiftUI

/// What a `PostCard` can ask its screen to do. The card never decides anything itself.
public struct PostCardActions {
    public var open: () -> Void
    public var openAuthor: () -> Void
    public var like: () -> Void
    public var comment: () -> Void
    public var remix: () -> Void
    public var share: () -> Void
    public var save: () -> Void
    /// When set, the ••• menu appears with a Report item that calls this.
    public var report: (() -> Void)?

    public init(
        open: @escaping () -> Void, openAuthor: @escaping () -> Void = {}, like: @escaping () -> Void = {},
        comment: @escaping () -> Void = {}, remix: @escaping () -> Void = {}, share: @escaping () -> Void = {},
        save: @escaping () -> Void = {}, report: (() -> Void)? = nil
    ) {
        self.open = open
        self.openAuthor = openAuthor
        self.like = like
        self.comment = comment
        self.remix = remix
        self.share = share
        self.save = save
        self.report = report
    }
}

/// A posted Hangout in the feed: who did it, a photo (or the route drawing), the title and caption, "3 of 5 Spots ·
/// ₹150–400 · about 3 h", and Like / Comment / Remix / Share. A Picks post has the Picks badge and the verified ring
/// but the same actions. It never shows a clock time (`docs/RISKS.md` 3).
public struct PostCard: View {
    private let data: PostCardData
    private let actions: PostCardActions

    public init(_ data: PostCardData, actions: PostCardActions) {
        self.data = data
        self.actions = actions
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            header
            Button(action: actions.open) { content }
                .buttonStyle(.plain)
            PostActionBar(data: data, actions: actions)
        }
        .padding(.vertical, Theme.Spacing.small)
    }

    private var header: some View {
        Button(action: actions.openAuthor) {
            HStack(spacing: Theme.Spacing.small) {
                Avatar(url: data.avatarURL, name: data.authorName, size: .small, isVerifiedVybe: data.isPick)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: data.authorName).font(Theme.Font.subheadline.weight(.semibold))
                    Text(verbatim: [data.username, data.dayText].compactMap(\.self).joined(separator: " · "))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer(minLength: 0)
                if data.isPick { PickBadge() }
            }
            .foregroundStyle(Theme.Color.textPrimary)
            .frame(minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            media
                .overlay(alignment: .bottomLeading) { if titleOnMedia { titleOverlay } }
                .clipShape(.rect(cornerRadius: Theme.Radius.extraLarge, style: .continuous))
            if !titleOnMedia { titleBelow }
            Text(verbatim: data.factsText)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
                .lineSpacing(lineSpacing)
                .padding(.top, Theme.Spacing.small)
            if let caption = data.caption {
                Text(verbatim: caption)
                    .font(Theme.Font.body.weight(.regular))
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineSpacing(lineSpacing)
                    .lineLimit(3)
                    .padding(.top, Theme.Spacing.medium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    /// A little extra space between wrapped lines (half of the smallest spacing token).
    private var lineSpacing: CGFloat { Theme.Spacing.tiny / 2 }

    private var hasPhoto: Bool { data.coverURL != nil }
    private var hasRoute: Bool { data.routePoints.count >= 2 }
    /// The title sits on the photo (or on the tinted picture when there is no photo). A route drawing keeps the title
    /// underneath, so the words never cover the dots.
    private var titleOnMedia: Bool { hasPhoto || !hasRoute }

    /// Photo: white title on a bottom scrim. No photo: dark ink on the bright tint (white on a bright fill fails).
    private var titleOverlay: some View {
        Text(verbatim: data.title)
            .font(Theme.Font.display)
            .minimumScaleFactor(0.6)
            .lineLimit(3)
            .foregroundStyle(hasPhoto ? Theme.Color.onPhoto : Theme.Color.ink)
            .padding(Theme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if hasPhoto {
                    LinearGradient(colors: [.clear, Theme.Color.scrim, Theme.Color.scrim],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
    }

    private var titleBelow: some View {
        Text(verbatim: data.title)
            .font(Theme.Font.title3.weight(.bold))
            .foregroundStyle(Theme.Color.textPrimary)
            .lineSpacing(lineSpacing)
            .padding(.top, Theme.Spacing.medium)
    }

    @ViewBuilder private var media: some View {
        if hasPhoto {
            PlaceImage(url: data.coverURL, aspectRatio: 4 / 3)
        } else if hasRoute {
            RouteMiniMap(points: data.routePoints).aspectRatio(4 / 3, contentMode: .fit)
        } else {
            // No photo and no route: a warm tinted picture with a big symbol, never a grey box.
            LinearGradient(colors: [Theme.Color.sunset, Theme.Color.sun], startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "map.fill")
                        .font(Theme.Font.display)
                        .imageScale(.large)
                        .foregroundStyle(Theme.Color.ink.opacity(0.25))
                        .padding(Theme.Spacing.large)
                        .accessibilityHidden(true)
                }
        }
    }
}

/// One row under the post: Like, Comment and Remix with their counts on the left; Share, Save and ••• on the right.
/// At very large text sizes the two groups stack, so nothing is cut off. Every button has a spoken label.
private struct PostActionBar: View {
    let data: PostCardData
    let actions: PostCardActions

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                reactions
                Spacer(minLength: Theme.Spacing.small)
                utilities
            }
            VStack(alignment: .leading, spacing: 0) {
                reactions
                utilities
            }
        }
        .padding(.vertical, Theme.Spacing.small)
    }

    private var reactions: some View {
        HStack(spacing: Theme.Spacing.tiny) {
            CountButton(
                systemImage: data.isLiked ? "heart.fill" : "heart", count: data.likeCount,
                label: data.isLiked ? ComponentStrings.unlike : ComponentStrings.like,
                value: ComponentStrings.likeCount(data.likeCount), tint: data.isLiked ? Theme.Color.critical : nil,
                action: actions.like)
            CountButton(systemImage: "bubble.left", count: data.commentCount, label: ComponentStrings.comment,
                        value: ComponentStrings.commentCount(data.commentCount), action: actions.comment)
            CountButton(systemImage: "arrow.triangle.branch", count: data.remixCount, label: ComponentStrings.remix,
                        value: ComponentStrings.remixCount(data.remixCount), action: actions.remix)
        }
    }

    private var utilities: some View {
        HStack(spacing: 0) {
            ActionButton(
                systemImage: "square.and.arrow.up", label: ComponentStrings.share, action: actions.share)
            ActionButton(
                systemImage: data.isSaved ? "bookmark.fill" : "bookmark",
                label: data.isSaved ? ComponentStrings.unsave : ComponentStrings.save, action: actions.save)
            if let report = actions.report {
                Menu {
                    Button(role: .destructive, action: report) {
                        Label { Text(verbatim: ComponentStrings.report) } icon: { Image(systemName: "flag") }
                    }
                } label: {
                    ActionIcon(systemImage: "ellipsis")
                        .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                        .contentShape(.rect)
                }
                .accessibilityLabel(Text(verbatim: ComponentStrings.moreOptions))
            }
        }
    }
}

/// Every icon in the action bar: the same font, weight, scale and box, so none looks bigger or heavier.
/// The box grows with Dynamic Type.
private struct ActionIcon: View {
    let systemImage: String
    var tint: Color?
    @ScaledMetric(relativeTo: .body) private var box: CGFloat = 24

    var body: some View {
        Image(systemName: systemImage)
            .font(Theme.Font.body.weight(.regular))
            .imageScale(.medium)
            .foregroundStyle(tint ?? Theme.Color.textPrimary)
            .frame(width: box, height: box)
    }
}

/// A plain icon button, 44 pt, with a spoken label.
private struct ActionButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ActionIcon(systemImage: systemImage)
                .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
    }
}

/// An icon with a short count ("1.2K"), 44 pt tall. The heart is filled when liked, so it is never colour alone.
private struct CountButton: View {
    let systemImage: String
    let count: Int
    let label: String
    let value: String
    var tint: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.tiny) {
                ActionIcon(systemImage: systemImage, tint: tint)
                if count > 0 {
                    Text(verbatim: PostCardData.compact(count)).foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .font(Theme.Font.subheadline)
            .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityValue(Text(verbatim: value))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#if DEBUG
private var longCaption: PostCardData {
    var data = PostCardData.previewFriend
    data.caption = "EXAMPLE A long caption about the evening: chai first, then the park, then a long walk back. "
        + "It goes on so the card shows how three lines are cut with an ellipsis."
    return data
}

#Preview("Feed") {
    ScrollView {
        VStack(spacing: Theme.Spacing.extraLarge) {
            PostCard(.previewPick, actions: PostCardActions(open: {}, report: {}))
            PostCard(.previewFriend, actions: PostCardActions(open: {}, report: {}))
            PostCard(longCaption, actions: PostCardActions(open: {}, report: {}))
        }
        .padding(Theme.Spacing.large)
    }
    .background(Theme.Color.surface)
}

#Preview("Large text") {
    ScrollView {
        PostCard(.previewPick, actions: PostCardActions(open: {}, report: {}))
            .padding(Theme.Spacing.large)
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
