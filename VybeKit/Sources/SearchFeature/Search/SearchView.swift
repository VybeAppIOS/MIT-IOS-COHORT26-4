import Design
import SwiftUI

/// Layout only: every value comes from `SearchViewModel`, every tap goes to it. The search field belongs to this
/// view, which sits in the search tab's own navigation stack (not on the tab bar).
struct SearchView: View {
    @State private var viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.retry() } },
            content: { content in list(content) },
            placeholder: { SearchSkeleton() },
            empty: {
                EmptyStateView(
                    systemImage: "magnifyingglass", message: viewModel.noResultsText,
                    actionTitle: viewModel.suggestPlaceLabel, action: { viewModel.suggestPlaceTapped() })
            })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.query, prompt: Text(verbatim: viewModel.prompt))
        .task { await viewModel.load() }
        .task(id: viewModel.query) { await viewModel.queryChanged() }
    }

    @ViewBuilder
    private func list(_ content: SearchContent) -> some View {
        List {
            switch content {
            case .idle(let suggestions, let recents): idle(suggestions, recents)
            case .results(let groups): ForEach(groups) { group in section(group) }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Before anything is typed

    @ViewBuilder
    private func idle(_ suggestions: [SearchRowData], _ recents: [String]) -> some View {
        if !recents.isEmpty {
            Section {
                ForEach(recents, id: \.self) { text in
                    Button { viewModel.recentTapped(text) } label: {
                        Label { Text(verbatim: text).foregroundStyle(Theme.Color.textPrimary) } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .frame(minHeight: Theme.Size.minTapTarget)
                    }
                }
            } header: { Text(verbatim: viewModel.recentsTitle).accessibilityAddTraits(.isHeader) }
        }
        if !suggestions.isEmpty {
            Section {
                ForEach(suggestions) { row in
                    rowView(row) { viewModel.suggestionTapped(row) }
                }
            } header: { Text(verbatim: viewModel.suggestionsTitle).accessibilityAddTraits(.isHeader) }
        }
    }

    // MARK: Results

    private func section(_ group: SearchGroup) -> some View {
        Section {
            ForEach(group.rows) { row in
                rowView(row) { viewModel.rowTapped(row, in: group.kind) }
            }
            if group.hasMore {
                Button { viewModel.seeAllTapped(group.kind) } label: {
                    Text(verbatim: viewModel.seeAllLabel).frame(minHeight: Theme.Size.minTapTarget)
                }
            }
        } header: { Text(verbatim: group.title).accessibilityAddTraits(.isHeader) }
    }

    private func rowView(_ row: SearchRowData, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                Text(verbatim: row.title).foregroundStyle(Theme.Color.textPrimary)
                Text(verbatim: row.subtitle).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct SearchSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.4)
            SkeletonLine()
            SkeletonLine(widthFraction: 0.7)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
