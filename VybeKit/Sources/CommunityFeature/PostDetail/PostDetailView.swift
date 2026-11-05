import Components
import Design
import SwiftUI

/// Layout only: every value comes from `PostDetailViewModel`, every tap goes to it.
struct PostDetailView: View {
    @State private var viewModel: PostDetailViewModel

    init(viewModel: PostDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in detail(content) },
            placeholder: { PostDetailSkeleton() },
            empty: { EmptyStateView(systemImage: "eye.slash", message: viewModel.unavailableMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.Color.surface)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .sheet(isPresented: $viewModel.isShowingComments) { CommentsPlaceholder() }
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
    }

    // MARK: Pieces

    private func detail(_ content: PostDetailContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                author(content)
                PhotoGallery(photos: content.gallery)
                    .clipShape(.rect(cornerRadius: Theme.Radius.large))
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    texts(content.post)
                    if let stats = content.pickStatsText {
                        Text(verbatim: stats).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
                    }
                    if content.isFriendsOnly {
                        Label { Text(verbatim: viewModel.friendsOnlyNote) } icon: { Image(systemName: "person.2") }
                            .font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    actions(content)
                }
                if !content.spots.isEmpty { spots(content.spots) }
                comments(content)
            }
            .padding(Theme.Spacing.large)
        }
    }

    private func author(_ content: PostDetailContent) -> some View {
        Button { viewModel.openAuthor() } label: {
            HStack(spacing: Theme.Spacing.small) {
                Avatar(
                    url: content.post.avatarURL, name: content.post.authorName, size: .small,
                    isVerifiedVybe: content.post.isPick)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: content.post.authorName).font(Theme.Font.subheadline.weight(.semibold))
                    Text(verbatim: [content.post.username, content.relationshipText, content.post.dayText]
                        .compactMap(\.self).joined(separator: " · "))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer(minLength: 0)
                if content.post.isPick { PickBadge() }
            }
            .foregroundStyle(Theme.Color.textPrimary)
            .frame(minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func more(_ content: PostDetailContent) -> some View {
        Menu {
            if content.isOwn {
                Button { viewModel.editTapped() } label: {
                    Label { Text(verbatim: viewModel.editLabel) } icon: { Image(systemName: "pencil") }
                }
            } else {
                Button(role: .destructive) { viewModel.reportTapped() } label: {
                    Label { Text(verbatim: viewModel.reportLabel) } icon: { Image(systemName: "flag") }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Theme.Color.textPrimary)
                .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
        }
        .accessibilityLabel(Text(verbatim: viewModel.moreLabel))
    }

    private func texts(_ post: PostCardData) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: post.title).font(Theme.Font.title3.weight(.bold)).foregroundStyle(Theme.Color.textPrimary)
            Text(verbatim: post.factsText).font(Theme.Font.subheadline).foregroundStyle(Theme.Color.textSecondary)
            if let caption = post.caption {
                Text(verbatim: caption).font(Theme.Font.body).foregroundStyle(Theme.Color.textPrimary)
            }
        }
    }

    private func actions(_ content: PostDetailContent) -> some View {
        let post = content.post
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Spacing.tiny) {
                reactions(post)
                Spacer(minLength: Theme.Spacing.small)
                utilities(content)
            }
            VStack(alignment: .leading, spacing: 0) {
                reactions(post)
                utilities(content)
            }
        }
    }

    private func reactions(_ post: PostCardData) -> some View {
        HStack(spacing: Theme.Spacing.tiny) {
            countButton(
                post.isLiked ? "heart.fill" : "heart", count: post.likeCount,
                label: post.isLiked ? ComponentStrings.unlike : ComponentStrings.like,
                tint: post.isLiked ? Theme.Color.critical : nil) { Task { await viewModel.likeTapped() } }
            countButton("bubble.left", count: post.commentCount, label: ComponentStrings.comment) {
                viewModel.commentsTapped()
            }
            countButton("arrow.triangle.branch", count: post.remixCount, label: ComponentStrings.remix) {
                viewModel.remixTapped()
            }
        }
    }

    private func utilities(_ content: PostDetailContent) -> some View {
        let post = content.post
        return HStack(spacing: 0) {
            countButton("square.and.arrow.up", count: 0, label: ComponentStrings.share) { viewModel.shareTapped() }
            countButton(
                post.isSaved ? "bookmark.fill" : "bookmark", count: 0,
                label: viewModel.saveLabel(isSaved: post.isSaved)) {
                Task { await viewModel.saveTapped() }
            }
            more(content)
        }
    }

    private func countButton(
        _ systemImage: String, count: Int, label: String, tint: Color? = nil, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.tiny) {
                Image(systemName: systemImage).imageScale(.medium).foregroundStyle(tint ?? Theme.Color.textPrimary)
                if count > 0 {
                    Text(verbatim: count.formatted(.number.notation(.compactName)))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .font(Theme.Font.subheadline)
            .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityValue(Text(verbatim: count > 0 ? count.formatted() : ""))
    }

    private func spots(_ rows: [SpotRowData]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(verbatim: viewModel.spotsTitle)
            SpotTimeline(rows: rows)
        }
    }

    private func comments(_ content: PostDetailContent) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(verbatim: viewModel.commentsTitle)
            if content.comments.isEmpty {
                Text(verbatim: viewModel.noComments).font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            ForEach(content.comments) { comment in
                CommentRow(comment, actions: CommentRowActions(
                    reply: { viewModel.commentsTapped() }, report: { viewModel.reportComment(comment.id) }))
            }
            if content.hasMoreComments {
                Button { viewModel.commentsTapped() } label: {
                    Text(verbatim: viewModel.viewAllComments).font(Theme.Font.subheadline.weight(.semibold))
                        .frame(minHeight: Theme.Size.minTapTarget)
                }
            }
        }
    }
}

/// The loading look: a grey photo block and a few lines.
private struct PostDetailSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.5)
            SkeletonBlock().frame(height: 220)
            SkeletonLine()
            SkeletonLine(widthFraction: 0.7)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// Stands in for the Comments sheet until SC-CM3 exists. Developer-only text, so it is not localized.
private struct CommentsPlaceholder: View {
    var body: some View {
        Text(verbatim: "CM3 Comments: placeholder until that screen is built")
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.Color.textSecondary)
            .padding(Theme.Spacing.large)
            .presentationDetents([.medium])
    }
}
