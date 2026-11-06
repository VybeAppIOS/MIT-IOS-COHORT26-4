import Components
import Design
import SwiftUI

/// Layout only: every value comes from `OtherProfileViewModel`, every tap goes to it.
struct OtherProfileView: View {
    @State private var viewModel: OtherProfileViewModel

    init(viewModel: OtherProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in profile(content) },
            placeholder: { PersonListSkeleton() },
            empty: { EmptyStateView(systemImage: "person.slash", message: viewModel.unavailableMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .background(Theme.Color.surface)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .confirmationDialog(
            Text(verbatim: viewModel.removeTitle), isPresented: $viewModel.isConfirmingRemove, titleVisibility: .visible
        ) {
            Button(role: .destructive) { Task { await viewModel.confirmRemove() } } label: {
                Text(verbatim: viewModel.removeLabel)
            }
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.cancelLabel) }
        }
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        if case .loaded(let content, _) = viewModel.state, content.relationship != .blocked {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if content.canMessage {
                    Button { viewModel.messageTapped() } label: { Image(systemName: "bubble.left") }
                        .accessibilityLabel(Text(verbatim: viewModel.messageLabel))
                }
                if content.relationship != .own {
                    Menu {
                        Button(role: .destructive) { viewModel.reportTapped() } label: {
                            Label { Text(verbatim: viewModel.reportLabel) } icon: { Image(systemName: "flag") }
                        }
                        Button(role: .destructive) { viewModel.blockTapped() } label: {
                            Label { Text(verbatim: viewModel.blockLabel) } icon: { Image(systemName: "hand.raised") }
                        }
                    } label: { Image(systemName: "ellipsis") }
                    .accessibilityLabel(Text(verbatim: viewModel.moreLabel))
                }
            }
        }
    }

    private func profile(_ content: OtherProfileContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                ProfileHeader(content.header, relationship: content.relationship) {
                    Task { await viewModel.headerButtonTapped() }
                }
                if content.mutualFriendCount > 0 {
                    NavRow(verbatim: viewModel.mutualText(content.mutualFriendCount), systemImage: "person.2") {
                        viewModel.mutualFriendsTapped()
                    }
                    .padding(.horizontal, Theme.Spacing.large)
                }
                if content.relationship != .privateGate && content.relationship != .blocked {
                    posts(content.tiles)
                }
            }
        }
    }

    private func posts(_ tiles: [PostTileData]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(verbatim: viewModel.postsTitle)
            if tiles.isEmpty {
                Text(verbatim: viewModel.noPostsText).font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Theme.Spacing.medium)],
                          spacing: Theme.Spacing.medium) {
                    ForEach(tiles) { tile in tileView(tile) }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
    }

    private func tileView(_ tile: PostTileData) -> some View {
        Button { viewModel.postTapped(tile.id) } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                Group {
                    if tile.coverURL == nil && tile.routePoints.count >= 2 {
                        RouteMiniMap(points: tile.routePoints).aspectRatio(1, contentMode: .fit)
                    } else {
                        PlaceImage(url: tile.coverURL, aspectRatio: 1)
                    }
                }
                .clipShape(.rect(cornerRadius: Theme.Radius.medium))
                Text(verbatim: tile.title).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(2)
            }
            .frame(minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
