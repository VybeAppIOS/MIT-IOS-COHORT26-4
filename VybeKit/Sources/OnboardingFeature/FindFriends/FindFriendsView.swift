import Components
import Design
import Models
import SwiftUI

/// Layout only: every value comes from `FindFriendsViewModel`, every tap goes to it.
struct FindFriendsView: View {
    @State private var viewModel: FindFriendsViewModel

    init(viewModel: FindFriendsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { rows in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    header
                    ForEach(rows) { row in
                        SuggestionRow(
                            row: row, isRequested: viewModel.requested.contains(row.id),
                            isSending: viewModel.sending.contains(row.id), error: viewModel.addErrors[row.id]
                        ) { Task { await viewModel.addTapped(row.id) } }
                    }
                }
                .padding(Theme.Spacing.large)
            }
        } placeholder: {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                header
                ForEach(0..<3, id: \.self) { _ in
                    Text(verbatim: "Person name placeholder").font(Theme.Font.headline)
                }
                Spacer()
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        } empty: {
            EmptyStateView(systemImage: "person.2", message: FindFriendsText.empty)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(verbatim: viewModel.hasAddedSomeone ? FindFriendsText.done : FindFriendsText.skip) {
                viewModel.finishTapped()
            }
            .padding(Theme.Spacing.large)
            .background(.bar)
            .accessibilityIdentifier("onboarding.findFriends.finish")
        }
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: FindFriendsText.title)
                .font(Theme.Font.title)
                .fontWeight(.bold)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: FindFriendsText.subtitle)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    /// The Retry button on the error state.
    private func retry() { Task { await viewModel.reload() } }
}

/// One suggestion: avatar, name, the mutual-friends reason, and Add friend (or Requested).
private struct SuggestionRow: View {
    let row: FriendSuggestionRow
    let isRequested: Bool
    let isSending: Bool
    let error: String?
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
            HStack(spacing: Theme.Spacing.medium) {
                Avatar(url: row.photoURL, name: row.name, size: .medium)
                VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                    Text(verbatim: row.name)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    if let reason = row.reason {
                        Text(verbatim: reason)
                            .font(Theme.Font.subheadline)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: Theme.Spacing.small)
                Button(action: onAdd) {
                    Text(verbatim: isRequested ? ComponentStrings.requested : ComponentStrings.addFriend)
                        .font(Theme.Font.subheadline)
                        .frame(minHeight: Theme.Size.minTapTarget)
                }
                .buttonStyle(.bordered)
                .tint(Theme.Color.accent)
                .disabled(isRequested || isSending)
            }
            if let error {
                Text(verbatim: error)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.critical)
            }
        }
    }
}
