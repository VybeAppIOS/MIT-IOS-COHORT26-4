import Design
import SwiftUI

/// Everything a comment row shows, already as display text (the ViewModel builds `relativeTimeText`, for example
/// "2 d", with `.formatted(...)`).
public struct CommentRowData: Hashable, Sendable, Identifiable {
    public let id: String
    public var authorName: String
    public var username: String
    public var avatarURL: URL?
    public var text: String
    public var relativeTimeText: String
    public var likeCount: Int
    public var isLiked: Bool
    /// 0 for a top-level comment, 1 for a reply, 2 for a reply to a reply. Deeper replies are drawn at depth 2.
    public var depth: Int
    public var isDeleted: Bool
    /// The author, or the owner of the post, may delete it.
    public var canDelete: Bool
    /// False for your own comment: you cannot report yourself.
    public var canReport: Bool

    public init(
        id: String, authorName: String, username: String, text: String, relativeTimeText: String,
        avatarURL: URL? = nil, likeCount: Int = 0, isLiked: Bool = false, depth: Int = 0, isDeleted: Bool = false,
        canDelete: Bool = false, canReport: Bool = true
    ) {
        self.id = id
        self.authorName = authorName
        self.username = username
        self.avatarURL = avatarURL
        self.text = text
        self.relativeTimeText = relativeTimeText
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.depth = depth
        self.isDeleted = isDeleted
        self.canDelete = canDelete
        self.canReport = canReport
    }

    /// Only two levels are indented; deeper threads show "View more replies" instead.
    public static let maxVisibleDepth = 2
}

/// What a `CommentRow` can ask its screen to do.
public struct CommentRowActions {
    public var like: () -> Void
    public var reply: () -> Void
    public var report: () -> Void
    public var delete: () -> Void
    public var openAuthor: () -> Void

    public init(
        like: @escaping () -> Void = {}, reply: @escaping () -> Void = {}, report: @escaping () -> Void = {},
        delete: @escaping () -> Void = {}, openAuthor: @escaping () -> Void = {}
    ) {
        self.like = like
        self.reply = reply
        self.report = report
        self.delete = delete
        self.openAuthor = openAuthor
    }
}

/// One comment in a thread: indented by depth, with Like, Reply and a ••• menu (Report, and Delete when allowed).
/// A deleted comment keeps its place in the thread as "This comment was deleted".
public struct CommentRow: View {
    private let data: CommentRowData
    private let actions: CommentRowActions
    @ScaledMetric(relativeTo: .body) private var indentStep = 32.0

    public init(_ data: CommentRowData, actions: CommentRowActions) {
        self.data = data
        self.actions = actions
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.small) {
            Avatar(url: data.isDeleted ? nil : data.avatarURL, name: data.isDeleted ? "" : data.authorName,
                   size: .small)
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                if data.isDeleted {
                    Text(verbatim: ComponentStrings.commentDeleted)
                        .font(Theme.Font.body.italic())
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    authorLine
                    Text(verbatim: data.text)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    toolbar
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, CGFloat(min(data.depth, CommentRowData.maxVisibleDepth)) * indentStep)
    }

    private var authorLine: some View {
        Button(action: actions.openAuthor) {
            Text(verbatim: "\(data.authorName) · \(data.relativeTimeText)")
                .font(Theme.Font.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private var toolbar: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Button(action: actions.like) {
                Label {
                    Text(verbatim: data.likeCount > 0 ? PostCardData.compact(data.likeCount) : "")
                } icon: {
                    Image(systemName: data.isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(data.isLiked ? Theme.Color.critical : Theme.Color.textSecondary)
                }
                .frame(minHeight: Theme.Size.minTapTarget)
            }
            .accessibilityLabel(Text(verbatim: data.isLiked ? ComponentStrings.unlike : ComponentStrings.like))
            .accessibilityValue(Text(verbatim: ComponentStrings.likeCount(data.likeCount)))
            Button(ComponentStrings.reply, action: actions.reply)
                .frame(minHeight: Theme.Size.minTapTarget)
            Spacer(minLength: 0)
            if data.canReport || data.canDelete {
                Menu {
                    if data.canReport {
                        Button(ComponentStrings.report, systemImage: "flag", action: actions.report)
                    }
                    if data.canDelete {
                        Button(ComponentStrings.delete, systemImage: "trash", role: .destructive,
                               action: actions.delete)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                        .contentShape(.rect)
                }
                .accessibilityLabel(Text(verbatim: ComponentStrings.moreOptions))
            }
        }
        .buttonStyle(.plain)
        .font(Theme.Font.footnote)
        .foregroundStyle(Theme.Color.textSecondary)
    }
}

/// "View more replies", under a thread deeper than two levels.
public struct MoreRepliesButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(ComponentStrings.moreReplies, action: action)
            .font(Theme.Font.footnote.weight(.semibold))
            .foregroundStyle(Theme.Color.accent)
            .frame(minHeight: Theme.Size.minTapTarget)
    }
}

// MARK: - Previews

#if DEBUG
private let sampleComments = [
    CommentRowData(id: "c1", authorName: "Sample Isha", username: "@sample.isha",
                   text: "EXAMPLE The chai break was the best part!", relativeTimeText: "2 d", likeCount: 3),
    CommentRowData(id: "c2", authorName: "Sample Aarav", username: "@sample.aarav",
                   text: "EXAMPLE Agreed, going again on Sunday.", relativeTimeText: "1 d", isLiked: true, depth: 1,
                   canDelete: true, canReport: false),
    CommentRowData(id: "c3", authorName: "Sample Meera", username: "@sample.meera",
                   text: "EXAMPLE A much longer reply that wraps onto several lines so the row can be checked at "
                       + "every text size without cutting any words.", relativeTimeText: "5 h", depth: 2),
    CommentRowData(id: "c4", authorName: "", username: "", text: "", relativeTimeText: "", depth: 1, isDeleted: true)
]

#Preview("Thread") {
    ScrollView {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            ForEach(sampleComments) { CommentRow($0, actions: CommentRowActions()) }
            MoreRepliesButton {}
        }
        .padding(Theme.Spacing.large)
    }
}

#Preview("Large text") {
    CommentRow(sampleComments[1], actions: CommentRowActions())
        .padding(Theme.Spacing.large)
        .dynamicTypeSize(.accessibility3)
}
#endif
