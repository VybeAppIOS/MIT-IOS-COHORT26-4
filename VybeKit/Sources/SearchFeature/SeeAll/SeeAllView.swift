import Design
import SwiftUI

/// Layout only: every value comes from `SeeAllViewModel`, every tap goes to it.
struct SeeAllView: View {
    @State private var viewModel: SeeAllViewModel

    init(viewModel: SeeAllViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in list(content) },
            placeholder: { SeeAllSkeleton() },
            empty: { EmptyStateView(systemImage: "magnifyingglass", message: viewModel.emptyMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }

    private func list(_ content: SeeAllContent) -> some View {
        List(content.rows) { row in
            SearchRowView(row: row) { viewModel.rowTapped(row) }
                .onAppear { viewModel.loadMoreIfNeeded(after: row) }
        }
        .listStyle(.insetGrouped)
    }
}

private struct SeeAllSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.6)
            SkeletonLine(widthFraction: 0.8)
            SkeletonLine(widthFraction: 0.5)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
