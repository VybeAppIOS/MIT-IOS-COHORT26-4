import Components
import Design
import SwiftUI

/// Layout only: every value comes from `FeedViewModel`, every tap goes to it.
struct FeedView: View {
    @State private var viewModel: FeedViewModel

    init(viewModel: FeedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in feed(content) },
            placeholder: { FeedSkeleton() },
            empty: { emptyState })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .toolbar { topBar }
        .background(Theme.Color.surface)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
    }

    // MARK: Pieces

    private func feed(_ content: FeedContent) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                if !content.picks.isEmpty { picks(content.picks) }
                if content.posts.isEmpty { emptyState }
                ForEach(content.posts) { post in
                    PostCard(post, actions: actions(for: post))
                        .task { await viewModel.loadMoreIfNeeded(after: post) }
                }
                if viewModel.isLoadingMore { ProgressView().frame(maxWidth: .infinity) }
                NavRow(verbatim: viewModel.trendingTitle, systemImage: "flame") { viewModel.trendingTapped() }
            }
            .padding(.horizontal, Theme.Spacing.large)
        }
    }

    private func picks(_ picks: [HangoutCardData]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(verbatim: viewModel.picksTitle)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Theme.Spacing.medium) {
                    ForEach(picks) { pick in
                        HangoutCard(pick, style: .featured) { viewModel.pickTapped(pick.id) }
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.6 }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "person.2", message: viewModel.emptyMessage, actionTitle: viewModel.emptyAction,
            action: { viewModel.friendsTapped() })
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
            report: { viewModel.reportTapped(post) })
    }

    @ToolbarContentBuilder private var topBar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { viewModel.friendsTapped() } label: { Image(systemName: "person.2") }
                .accessibilityLabel(Text(verbatim: viewModel.friendsLabel))
            Button { viewModel.activityTapped() } label: {
                Image(systemName: viewModel.hasUnseenActivity ? "bell.badge" : "bell")
            }
            .accessibilityLabel(Text(verbatim: viewModel.activityLabel))
            Button { viewModel.chatsTapped() } label: {
                Image(systemName: viewModel.unreadChatCount > 0 ? "bubble.left.and.bubble.right.fill"
                      : "bubble.left.and.bubble.right")
            }
            .accessibilityLabel(Text(verbatim: viewModel.chatsLabel))
        }
    }
}

/// The loading look: grey blocks where the Picks strip and a first card will be.
private struct FeedSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonBlock().frame(height: 160)
            SkeletonLine()
            SkeletonBlock().frame(height: 200)
            SkeletonLine()
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
