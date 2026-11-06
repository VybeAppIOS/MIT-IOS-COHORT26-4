import Design
import SwiftUI

/// Layout only: one row per suggestion, its status as an icon and a word, and the team's note under it.
struct MySuggestionsView: View {
    @State private var viewModel: MySuggestionsViewModel

    init(viewModel: MySuggestionsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { rows in
            List(rows) { row in
                SuggestionRow(row: row)
            }
            .listStyle(.insetGrouped)
        } placeholder: {
            List(0..<3, id: \.self) { _ in
                SuggestionRow(row: SuggestionRowData(id: "placeholder", name: "EXAMPLE Suggested Café",
                                                     statusText: "Pending", statusSymbol: "clock",
                                                     status: .pending, note: nil))
            }
            .listStyle(.insetGrouped)
        } empty: {
            EmptyStateView(systemImage: "mappin.and.ellipse", message: viewModel.emptyMessage)
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .hidesTabBar()
    }
}

private struct SuggestionRow: View {
    let row: SuggestionRowData

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            Text(verbatim: row.name)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Label(row.statusText, systemImage: row.statusSymbol)
                .font(Theme.Font.subheadline)
                .foregroundStyle(tint)
            if let note = row.note {
                Text(verbatim: note)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .frame(minHeight: Theme.Size.minTapTarget, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch row.status {
        case .pending: Theme.Color.textSecondary
        case .approved: Theme.Color.positive
        case .rejected: Theme.Color.critical
        }
    }
}
