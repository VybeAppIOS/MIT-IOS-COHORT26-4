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

    public init(
        open: @escaping () -> Void, openAuthor: @escaping () -> Void = {}, like: @escaping () -> Void = {},
        comment: @escaping () -> Void = {}, remix: @escaping () -> Void = {}, share: @escaping () -> Void = {}
    ) {
        self.open = open
        self.openAuthor = openAuthor
        self.like = like
        self.comment = comment
        self.remix = remix
        self.share = share
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
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            media.clipShape(.rect(cornerRadius: Theme.Radius.large))
            Text(verbatim: data.title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text(verbatim: data.factsText)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            if let caption = data.caption {
                Text(verbatim: caption)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var media: some View {
        if data.coverURL != nil || data.routePoints.count < 2 {
            PlaceImage(url: data.coverURL, aspectRatio: 4 / 3)
        } else {
            RouteMiniMap(points: data.routePoints).aspectRatio(4 / 3, contentMode: .fit)
        }
    }
}

/// Like, Comment, Remix and Share, each with its count. Every button has a spoken label with its number.
private struct PostActionBar: View {
    let data: PostCardData
    let actions: PostCardActions

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            CountButton(
                systemImage: data.isLiked ? "heart.fill" : "heart", count: data.likeCount,
                label: data.isLiked ? ComponentStrings.unlike : ComponentStrings.like,
                value: ComponentStrings.likeCount(data.likeCount), tint: data.isLiked ? Theme.Color.critical : nil,
                action: actions.like)
            CountButton(systemImage: "bubble.left", count: data.commentCount, label: ComponentStrings.comment,
                        value: ComponentStrings.commentCount(data.commentCount), action: actions.comment)
            CountButton(systemImage: "arrow.triangle.branch", count: data.remixCount, label: ComponentStrings.remix,
                        value: ComponentStrings.remixCount(data.remixCount), action: actions.remix)
            Spacer(minLength: 0)
            IconButton(systemImage: "square.and.arrow.up", verbatimLabel: ComponentStrings.share,
                       action: actions.share)
        }
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
                Image(systemName: systemImage).foregroundStyle(tint ?? Theme.Color.textPrimary)
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
            PostCard(.previewPick, actions: PostCardActions(open: {}))
            PostCard(.previewFriend, actions: PostCardActions(open: {}))
            PostCard(longCaption, actions: PostCardActions(open: {}))
        }
        .padding(Theme.Spacing.large)
    }
    .background(Theme.Color.surface)
}

#Preview("Large text") {
    ScrollView {
        PostCard(.previewPick, actions: PostCardActions(open: {}))
            .padding(Theme.Spacing.large)
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
