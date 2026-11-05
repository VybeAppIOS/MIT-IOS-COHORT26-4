import Components
import Design
import SwiftUI

/// Layout only: saved Hangouts as cards; swipe to unsave; an Undo bar after removing one.
struct SavedView: View {
    @State private var viewModel: SavedViewModel

    init(viewModel: SavedViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.reload() } }) { items in
            List(items) { item in
                row(item)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.remove(item.id) }
                        } label: {
                            Label(viewModel.removeTitle, systemImage: "bookmark.slash")
                        }
                    }
            }
            .listStyle(.plain)
        } placeholder: {
            List(0..<2, id: \.self) { _ in
                HangoutCard(HangoutCardData(id: "placeholder", title: viewModel.title, spotCount: 3,
                                            budgetText: viewModel.title, durationText: viewModel.title)) {}
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        } empty: {
            EmptyStateView(systemImage: "bookmark", message: viewModel.emptyMessage)
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .safeAreaInset(edge: .bottom) { undoBar }
        .vybeAnimation(Theme.Motion.standard, value: viewModel.lastRemoved)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }

    @ViewBuilder private func row(_ item: SavedItem) -> some View {
        switch item {
        case .available(let card):
            HangoutCard(card) { viewModel.open(card.id) }
                .vybeZoomSource(id: card.id)
        case .unavailable:
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                Label(viewModel.unavailableTitle, systemImage: "exclamationmark.triangle")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(verbatim: viewModel.unavailableBody)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget, alignment: .leading)
            .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.large))
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder private var undoBar: some View {
        if viewModel.lastRemoved != nil {
            HStack(spacing: Theme.Spacing.medium) {
                Text(verbatim: viewModel.removedMessage)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Spacer(minLength: Theme.Spacing.small)
                Button(viewModel.undoTitle) { Task { await viewModel.undo() } }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .accessibilityIdentifier("profile.saved.undo")
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.small)
            .background(.bar)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
