import Components
import Design
import SwiftUI

/// Layout only: "Finished, not posted" with Post and Delete, then "Scheduled" with Cancel.
struct ReadyToPostView: View {
    @State private var viewModel: ReadyToPostViewModel

    init(viewModel: ReadyToPostViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { content in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    section(viewModel.finishedHeader, rows: content.finished, none: viewModel.noFinished) { row in
                        finishedActions(row)
                    }
                    section(viewModel.scheduledHeader, rows: content.scheduled, none: viewModel.noScheduled) { row in
                        Button(viewModel.cancelTitle) { Task { await viewModel.cancelSchedule(row.id) } }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .frame(minHeight: Theme.Size.minTapTarget)
                    }
                }
                .padding(Theme.Spacing.large)
            }
        } placeholder: {
            ScrollView {
                ReadyCard(row: ReadyRow(id: "placeholder", title: viewModel.title, whenText: viewModel.title,
                                        spotsText: viewModel.title, photosText: viewModel.title, canPost: true,
                                        postBlockedReason: nil)) { EmptyView() }
                    .padding(Theme.Spacing.large)
            }
        } empty: {
            EmptyStateView(systemImage: "paperplane", message: viewModel.emptyMessage)
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .confirmationDialog(viewModel.deleteConfirmTitle, isPresented: $viewModel.isConfirmingDelete,
                            titleVisibility: .visible) {
            Button(viewModel.deleteTitle, role: .destructive) { Task { await viewModel.deleteConfirmed() } }
            Button(SharedStrings.cancel, role: .cancel) {}
        } message: {
            Text(verbatim: viewModel.deleteConfirmMessage)
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .hidesTabBar()
    }

    private func section<Actions: View>(
        _ header: String, rows: [ReadyRow], none: String, @ViewBuilder actions: @escaping (ReadyRow) -> Actions
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            SectionHeader(verbatim: header)
            if rows.isEmpty {
                Text(verbatim: none).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
            }
            ForEach(rows) { row in
                ReadyCard(row: row) { actions(row) }
            }
        }
    }

    private func finishedActions(_ row: ReadyRow) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            HStack(spacing: Theme.Spacing.small) {
                Button(viewModel.postTitle) { viewModel.postTapped(row.id) }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Color.accent)
                    .controlSize(.large)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .disabled(!row.canPost)
                Button(viewModel.deleteTitle, role: .destructive) { viewModel.deleteTapped(row.id) }
                    .buttonStyle(.bordered)
                    .tint(Theme.Color.critical)
                    .controlSize(.large)
                    .frame(minHeight: Theme.Size.minTapTarget)
            }
            if let reason = row.postBlockedReason {
                Label(reason, systemImage: "info.circle")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }
}

/// One run: title, when, "3 of 5 Spots · 2 photos", then its buttons.
private struct ReadyCard<Actions: View>: View {
    let row: ReadyRow
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: row.title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text(verbatim: details)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            actions()
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private var details: String {
        [row.whenText, row.spotsText, row.photosText].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
