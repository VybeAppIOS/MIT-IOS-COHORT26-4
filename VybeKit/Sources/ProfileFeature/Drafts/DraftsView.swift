import Components
import Design
import SwiftUI

/// Layout only: Drafts as cards with the Draft badge, swipe to delete (confirmed), New Hangout in the toolbar.
struct DraftsView: View {
    @State private var viewModel: DraftsViewModel

    init(viewModel: DraftsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { cards in
            List(cards) { card in
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    StatusBadge(.draft)
                    HangoutCard(card) { viewModel.open(card.id) }
                }
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteTapped(card.id)
                    } label: {
                        Label(viewModel.deleteTitle, systemImage: "trash")
                    }
                }
            }
            .listStyle(.plain)
        } placeholder: {
            List(0..<2, id: \.self) { _ in
                HangoutCard(HangoutCardData(id: "placeholder", title: viewModel.title, spotCount: 2,
                                            budgetText: viewModel.title, durationText: viewModel.title)) {}
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        } empty: {
            EmptyStateView(systemImage: "pencil", message: viewModel.emptyMessage, actionTitle: viewModel.newTitle) {
                viewModel.newTapped()
            }
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .toolbar {
            // With no Drafts the empty state already offers New Hangout; showing the "+" too would be a twin button.
            if viewModel.hasDrafts {
                ToolbarItem(placement: .primaryAction) {
                    IconButton(systemImage: "plus", verbatimLabel: viewModel.newTitle) { viewModel.newTapped() }
                        .accessibilityIdentifier("profile.drafts.new")
                }
            }
        }
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
}
