import Components
import Design
import SwiftUI

/// Layout only: the blocked people, each with Unblock.
struct BlockedView: View {
    @State private var viewModel: BlockedViewModel

    init(viewModel: BlockedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.reload() } }) { rows in
            List {
                Section {
                    ForEach(rows) { row in
                        HStack(spacing: Theme.Spacing.medium) {
                            Avatar(url: row.photoURL, name: row.name)
                            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                                Text(verbatim: row.name).font(Theme.Font.body)
                                Text(verbatim: row.username)
                                    .font(Theme.Font.footnote)
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                            Spacer(minLength: Theme.Spacing.small)
                            Button(viewModel.unblockTitle) { Task { await viewModel.unblockTapped(row.id) } }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .frame(minHeight: Theme.Size.minTapTarget)
                                .disabled(!viewModel.canUnblock)
                        }
                    }
                } footer: {
                    Text(verbatim: viewModel.footer)
                }
                if viewModel.isOffline {
                    Section { SafetyNote(viewModel.offlineText, style: .info) }
                }
                if viewModel.unblockFailed {
                    Section { SafetyNote(viewModel.errorText, style: .warning) }
                }
            }
            .listStyle(.insetGrouped)
        } placeholder: {
            List { Text(verbatim: viewModel.title) }.redacted(reason: .placeholder)
        } empty: {
            EmptyStateView(systemImage: "hand.raised", message: viewModel.emptyMessage)
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }
}
