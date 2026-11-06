import Design
import SwiftUI

/// Layout only: every value comes from `MutualFriendsViewModel`, every tap goes to it.
struct MutualFriendsView: View {
    @State private var viewModel: MutualFriendsViewModel

    init(viewModel: MutualFriendsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in list(content) },
            placeholder: { PersonListSkeleton() },
            empty: { EmptyStateView(systemImage: "person.2", message: viewModel.emptyMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .hidesTabBar()
    }

    private func list(_ content: MutualFriendsContent) -> some View {
        List(content.people) { person in
            PersonRow(person: person, open: { viewModel.personTapped(person.id) }, trailing: { EmptyView() })
        }
        .listStyle(.insetGrouped)
    }
}
