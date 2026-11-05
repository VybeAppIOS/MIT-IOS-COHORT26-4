import Components
import Design
import SwiftUI

/// Layout only: every value comes from `ListViewModel`, every tap goes to it. It should feel like the Messages list.
struct ListView: View {
    @State private var viewModel: ListViewModel
    @ScaledMetric(relativeTo: .body) private var avatarWidth = 72.0

    init(viewModel: ListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in list(content) },
            placeholder: { ChatListSkeleton() },
            empty: {
                EmptyStateView(
                    systemImage: "bubble.left.and.bubble.right", message: viewModel.emptyMessage,
                    actionTitle: viewModel.emptyAction, action: { viewModel.newChatTapped() })
            })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.newChatTapped() } label: { Image(systemName: "square.and.pencil") }
                    .disabled(viewModel.isOffline)
                    .accessibilityLabel(Text(verbatim: viewModel.newChatLabel))
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .sheet(
            isPresented: $viewModel.isShowingNewChat,
            onDismiss: { Task { await viewModel.newChatDismissed() } },
            content: { NewChatView(viewModel: viewModel.makeNewChatViewModel()) })
    }

    private func list(_ content: ChatListContent) -> some View {
        List(content.rows) { row in
            Button { viewModel.rowTapped(row.id) } label: { rowView(row) }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(
                    top: Theme.Spacing.small, leading: Theme.Spacing.large, bottom: Theme.Spacing.small,
                    trailing: Theme.Spacing.large))
        }
        .listStyle(.plain)
    }

    private func rowView(_ row: ChatRowData) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            Group {
                if row.isGroup {
                    AvatarStack(row.memberNames.enumerated().map {
                        AvatarStackPerson(id: "\($0.offset)", name: $0.element)
                    })
                } else {
                    Avatar(url: nil, name: row.title, size: .large)
                }
            }
            .frame(width: avatarWidth, alignment: .leading)
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                HStack {
                    Text(verbatim: row.title)
                        .font(Theme.Font.headline).foregroundStyle(Theme.Color.textPrimary).lineLimit(1)
                    Spacer(minLength: Theme.Spacing.small)
                    Text(verbatim: row.timeText).font(Theme.Font.footnote)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                HStack(alignment: .top) {
                    Text(verbatim: row.preview)
                        .font(row.unreadCount > 0 ? Theme.Font.subheadline.weight(.semibold) : Theme.Font.subheadline)
                        .foregroundStyle(row.unreadCount > 0 ? Theme.Color.textPrimary : Theme.Color.textSecondary)
                        .lineLimit(2)
                    Spacer(minLength: Theme.Spacing.small)
                    if row.unreadCount > 0 { unreadBadge(row.unreadCount) }
                }
            }
        }
        .frame(minHeight: Theme.Size.minTapTarget)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: spoken(row)))
    }

    private func unreadBadge(_ count: Int) -> some View {
        Text(verbatim: count.formatted())
            .font(Theme.Font.caption.weight(.bold))
            .foregroundStyle(Theme.Color.onAccent)
            .padding(.horizontal, Theme.Spacing.small)
            .padding(.vertical, Theme.Spacing.tiny)
            .background(Theme.Color.accent, in: .capsule)
    }

    /// "Kothrud Crew, 2 unread, Sample Isha: What are we doing, 9:41 am"
    private func spoken(_ row: ChatRowData) -> String {
        [row.title, row.unreadCount > 0 ? viewModel.unreadText(row.unreadCount) : nil, row.preview, row.timeText]
            .compactMap(\.self).filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

/// The loading look: a few grey rows.
private struct ChatListSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.5)
            SkeletonLine()
            SkeletonLine(widthFraction: 0.6)
            SkeletonLine(widthFraction: 0.8)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
