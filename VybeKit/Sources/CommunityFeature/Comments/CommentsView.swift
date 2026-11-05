import Components
import Design
import SwiftUI

/// The Comments sheet. Layout only: every value comes from `CommentsViewModel`, every tap goes to it.
/// It has its own `NavigationStack` (a local sheet, ADR 003) and is opened by the Feed and Post detail.
struct CommentsView: View {
    @State private var viewModel: CommentsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var composerFocused: Bool

    init(viewModel: CommentsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            LoadStateView(
                viewModel.state,
                onRetry: { Task { await viewModel.reload() } },
                content: { content in thread(content) },
                placeholder: { CommentsSkeleton() },
                empty: { EmptyStateView(systemImage: "bubble.left", message: viewModel.emptyMessage) })
            .navigationTitle(Text(verbatim: viewModel.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text(verbatim: viewModel.doneLabel) }
                }
            }
            .background(Theme.Color.surface)
            .safeAreaInset(edge: .bottom) { composer }
            .task { await viewModel.load() }
            .refreshable { await viewModel.reload() }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .vybeHaptic(.like, trigger: viewModel.likeCount)
        .confirmationDialog(
            Text(verbatim: viewModel.deleteTitle),
            isPresented: Binding(get: { viewModel.deletingID != nil }, set: { if !$0 { viewModel.cancelDelete() } }),
            titleVisibility: .visible
        ) {
            Button(role: .destructive) { Task { await viewModel.confirmDelete() } } label: {
                Text(verbatim: viewModel.deleteLabel)
            }
            Button(role: .cancel) { viewModel.cancelDelete() } label: { Text(verbatim: viewModel.cancelLabel) }
        }
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
    }

    // MARK: Thread

    private func thread(_ content: CommentsContent) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.small) {
                ForEach(content.rows) { row in
                    CommentRow(row, actions: actions(for: row))
                        .task { await viewModel.loadMoreIfNeeded(after: row) }
                }
                ForEach(viewModel.pending) { item in pendingRow(item) }
                if viewModel.isLoadingMore { ProgressView().frame(maxWidth: .infinity) }
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.small)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func actions(for row: CommentRowData) -> CommentRowActions {
        CommentRowActions(
            like: { Task { await viewModel.likeTapped(row.id) } },
            reply: {
                viewModel.replyTapped(row.id)
                composerFocused = true
            },
            report: { viewModel.reportTapped(row.id) },
            delete: { viewModel.deleteTapped(row.id) },
            openAuthor: { viewModel.authorTapped(row.id) })
    }

    /// Your own comment before the server confirms it: dimmed while sending, with Retry and Remove if it failed.
    private func pendingRow(_ item: PendingComment) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            Text(verbatim: item.text).font(Theme.Font.body).foregroundStyle(Theme.Color.textPrimary)
            if item.phase == .sending {
                Text(verbatim: viewModel.sendingText).font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            } else {
                Label { Text(verbatim: viewModel.failedText) } icon: { Image(systemName: "exclamationmark.circle") }
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.critical)
                HStack(spacing: Theme.Spacing.medium) {
                    PillButton(verbatim: viewModel.retryLabel, style: .prominent) {
                        Task { await viewModel.retryTapped(item.id) }
                    }
                    PillButton(verbatim: viewModel.removeLabel, role: .destructive) {
                        viewModel.removePending(item.id)
                    }
                }
            }
        }
        .opacity(item.phase == .sending ? 0.6 : 1)
        .accessibilityElement(children: .combine)
    }

    // MARK: Composer

    /// Pinned above the keyboard. "Replying to …" and the character count appear only when they matter.
    private var composer: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            if let replying = viewModel.replyingToText {
                HStack {
                    Text(verbatim: replying).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
                    Spacer(minLength: 0)
                    IconButton(systemImage: "xmark.circle.fill", verbatimLabel: viewModel.cancelReplyLabel) {
                        viewModel.cancelReply()
                    }
                }
            }
            if viewModel.isOffline {
                Label { Text(verbatim: viewModel.offlineText) } icon: { Image(systemName: "wifi.slash") }
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            HStack(alignment: .bottom, spacing: Theme.Spacing.small) {
                TextField(text: $viewModel.draft, axis: .vertical) { Text(verbatim: viewModel.placeholder) }
                    .font(Theme.Font.body)
                    .lineLimit(1...4)
                    .focused($composerFocused)
                    .submitLabel(.send)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.small)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.large))
                    .onSubmit { Task { await viewModel.sendTapped() } }
                IconButton(systemImage: "arrow.up.circle.fill", verbatimLabel: viewModel.sendLabel) {
                    Task { await viewModel.sendTapped() }
                }
                .disabled(!viewModel.canSend)
            }
            if let remaining = viewModel.remainingText {
                Text(verbatim: remaining).font(Theme.Font.caption).foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.small)
        .background(.bar)
    }
}

/// The loading look: a few grey comment rows.
private struct CommentsSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.4)
            SkeletonLine()
            SkeletonLine(widthFraction: 0.4)
            SkeletonLine(widthFraction: 0.8)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
