import Components
import Design
import SwiftUI

/// Layout only: every value comes from `TrendingViewModel`, every tap goes to it.
struct TrendingView: View {
    @State private var viewModel: TrendingViewModel

    init(viewModel: TrendingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in list(content) },
            placeholder: { TrendingSkeleton() },
            empty: { EmptyStateView(systemImage: "flame", message: viewModel.emptyMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .background(Theme.Color.surface)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .sheet(
            isPresented: Binding(
                get: { viewModel.commentsRunID != nil }, set: { if !$0 { viewModel.commentsRunID = nil } }),
            onDismiss: { Task { await viewModel.commentsDismissed() } },
            content: { commentsSheet })
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
        .hidesTabBar()
    }

    @ViewBuilder private var commentsSheet: some View {
        if let id = viewModel.commentsRunID { CommentsView(viewModel: viewModel.makeCommentsViewModel(for: id)) }
    }

    private func list(_ content: TrendingContent) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                Text(verbatim: viewModel.subtitle)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
                ForEach(content.posts) { post in
                    PostCard(post, actions: actions(for: post))
                        .task { await viewModel.loadMoreIfNeeded(after: post) }
                }
            }
            .padding(.horizontal, Theme.Spacing.large)
        }
    }

    private func actions(for post: PostCardData) -> PostCardActions {
        PostCardActions(
            open: { viewModel.openPost(post) },
            openAuthor: { viewModel.openAuthor(of: post) },
            like: { Task { await viewModel.likeTapped(post) } },
            comment: { viewModel.commentTapped(post) },
            remix: { viewModel.remixTapped(post) },
            share: { viewModel.shareTapped(post) },
            save: { Task { await viewModel.saveTapped(post) } },
            report: viewModel.canReport(post) ? { viewModel.reportTapped(post) } : nil)
    }
}

/// The loading look: grey blocks where the first cards will be.
private struct TrendingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.5)
            SkeletonBlock().frame(height: 200)
            SkeletonLine()
            SkeletonLine(widthFraction: 0.7)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
