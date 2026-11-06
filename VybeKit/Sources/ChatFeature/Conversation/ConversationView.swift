import Components
import Design
import SwiftUI
import UIKit

/// Layout only: every value comes from `ConversationViewModel`, every tap goes to it. It should feel like Messages.
struct ConversationView: View {
    @State private var viewModel: ConversationViewModel
    @FocusState private var composerFocused: Bool

    init(viewModel: ConversationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.retry() } },
            content: { content in thread(content) },
            placeholder: { ConversationSkeleton() },
            empty: { EmptyStateView(systemImage: "bubble.left", message: viewModel.emptyMessage) })
        .navigationTitle(Text(verbatim: title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.headerTapped() } label: { Image(systemName: "info.circle") }
                    .accessibilityLabel(Text(verbatim: viewModel.infoLabel))
            }
        }
        .background(Theme.Color.surface)
        .safeAreaInset(edge: .bottom) { composer }
        .task { await viewModel.run() }
        .sheet(isPresented: $viewModel.isShowingPoll, content: { PollView(viewModel: viewModel.makePollViewModel()) })
        .sheet(isPresented: $viewModel.isShowingSaved, content: { savedSheet })
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
        .hidesTabBar()
    }

    private var title: String {
        if case .loaded(let content, _) = viewModel.state { content.title } else { "" }
    }

    // MARK: Thread

    private func thread(_ content: ConversationContent) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                    ForEach(content.rows) { row in
                        VStack(alignment: row.isMine ? .trailing : .leading, spacing: Theme.Spacing.tiny) {
                            MessageBubble(row, actions: actions(for: row))
                                .padding(.top, row.startsGroup ? Theme.Spacing.small : 0)
                                .contextMenu { menu(for: row) }
                            if case .link = row.content {
                                Text(verbatim: viewModel.linkNote).font(Theme.Font.caption2)
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: row.isMine ? .trailing : .leading)
                        .id(row.id)
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.vertical, Theme.Spacing.small)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: content.rows.last?.id) { _, last in
                guard let last else { return }
                withVybeAnimation(Theme.Motion.standard) { proxy.scrollTo(last, anchor: .bottom) }
            }
        }
    }

    private func actions(for row: MessageRowData) -> MessageBubbleActions {
        MessageBubbleActions(
            openHangout: { viewModel.openHangout($0) },
            openLink: { UIApplication.shared.open($0) },
            togglePlayback: { viewModel.togglePlayback(row.id) },
            vote: { choice in Task { await viewModel.vote(choice, on: row.id) } })
    }

    @ViewBuilder private func menu(for row: MessageRowData) -> some View {
        if let text = viewModel.copyText(row.id) {
            Button { UIPasteboard.general.string = text } label: {
                Label { Text(verbatim: viewModel.copyLabel) } icon: { Image(systemName: "doc.on.doc") }
            }
        }
        if viewModel.canEdit(row.id) {
            Button { viewModel.editTapped(row.id); composerFocused = true } label: {
                Label { Text(verbatim: viewModel.editMenuLabel) } icon: { Image(systemName: "pencil") }
            }
        }
        if viewModel.canDelete(row.id) {
            Button(role: .destructive) { viewModel.deleteTapped(row.id) } label: {
                Label { Text(verbatim: viewModel.deleteLabel) } icon: { Image(systemName: "trash") }
            }
        }
        if !row.isMine {
            Button(role: .destructive) { viewModel.reportTapped(row.id) } label: {
                Label { Text(verbatim: viewModel.reportLabel) } icon: { Image(systemName: "flag") }
            }
        }
    }

    // MARK: Composer

    /// Pinned above the keyboard, on the system bar material. Disabled offline, muted, or in a group of fewer than 3.
    private var composer: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            if viewModel.isOffline {
                note("wifi.slash", viewModel.offlineNote)
            } else if case .loaded(let content, _) = viewModel.state, content.isReadOnly {
                note("lock", viewModel.readOnlyNote)
            } else if case .loaded(let content, _) = viewModel.state, content.isMuted {
                note("speaker.slash", viewModel.mutedNote)
            }
            if viewModel.editingID != nil {
                HStack {
                    Text(verbatim: viewModel.editingText).font(Theme.Font.footnote)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Spacer(minLength: 0)
                    IconButton(systemImage: "xmark.circle.fill", verbatimLabel: viewModel.cancelEditLabel) {
                        viewModel.cancelEdit()
                    }
                }
            }
            HStack(alignment: .bottom, spacing: Theme.Spacing.small) {
                plusMenu
                if viewModel.isRecording { recordingBar } else { field }
                trailingButton
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.small)
        .background(.bar)
    }

    private func note(_ symbol: String, _ text: String) -> some View {
        Label { Text(verbatim: text) } icon: { Image(systemName: symbol) }
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.Color.textSecondary)
    }

    private var plusMenu: some View {
        Menu {
            Button { Task { await viewModel.hangoutTapped() } } label: {
                Label { Text(verbatim: viewModel.hangoutLabel) } icon: { Image(systemName: "map") }
            }
            if viewModel.canStartPoll {
                Button { viewModel.pollTapped() } label: {
                    Label { Text(verbatim: viewModel.pollLabel) } icon: { Image(systemName: "chart.bar") }
                }
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(Theme.Font.title2)
                .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
        }
        .disabled(!viewModel.canWrite || viewModel.isRecording)
        .accessibilityLabel(Text(verbatim: viewModel.plusLabel))
    }

    private var field: some View {
        TextField(text: $viewModel.draft, axis: .vertical) { Text(verbatim: viewModel.placeholder) }
            .font(Theme.Font.body)
            .lineLimit(1...5)
            .focused($composerFocused)
            .disabled(!viewModel.canWrite)
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.large))
    }

    private var recordingBar: some View {
        HStack {
            Image(systemName: "waveform").foregroundStyle(Theme.Color.critical).accessibilityHidden(true)
            Text(verbatim: viewModel.recordingText).font(Theme.Font.body)
            Spacer(minLength: 0)
            IconButton(systemImage: "trash", verbatimLabel: viewModel.cancelRecordingLabel) {
                Task { await viewModel.cancelRecording() }
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .frame(minHeight: Theme.Size.minTapTarget)
        .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.large))
    }

    /// Send when there are words; otherwise the microphone (tap to start, tap again to send).
    @ViewBuilder private var trailingButton: some View {
        if viewModel.isRecording {
            IconButton(systemImage: "arrow.up.circle.fill", verbatimLabel: viewModel.finishLabel) {
                Task { await viewModel.micTapped() }
            }
        } else if viewModel.canSendDraft {
            IconButton(
                systemImage: "arrow.up.circle.fill",
                verbatimLabel: viewModel.editingID == nil ? viewModel.sendLabel : viewModel.saveEditLabel
            ) { Task { await viewModel.sendTapped() } }
        } else {
            IconButton(systemImage: "mic.fill", verbatimLabel: viewModel.micLabel) {
                Task { await viewModel.micTapped() }
            }
            .disabled(!viewModel.canWrite)
        }
    }

    private var savedSheet: some View {
        NavigationStack {
            List {
                if viewModel.saved.isEmpty {
                    Text(verbatim: viewModel.savedEmpty).foregroundStyle(Theme.Color.textSecondary)
                }
                ForEach(viewModel.saved) { choice in
                    Button { Task { await viewModel.sendHangout(choice.id) } } label: {
                        Text(verbatim: choice.title).foregroundStyle(Theme.Color.textPrimary)
                            .frame(minHeight: Theme.Size.minTapTarget)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text(verbatim: viewModel.savedTitle))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct ConversationSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.6)
            SkeletonLine(widthFraction: 0.4)
            SkeletonLine(widthFraction: 0.7)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
