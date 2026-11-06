import Components
import Design
import SwiftUI

/// Layout only: a username search; the person found, the reports against them, Ban and Unban (each confirmed).
struct AdminUsersView: View {
    @State private var viewModel: AdminUsersViewModel

    init(viewModel: AdminUsersViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.searchSubmitted() } }

    var body: some View {
        Group {
            if viewModel.isAllowed {
                content
            } else {
                EmptyStateView(systemImage: "lock", message: viewModel.teamOnlyMessage)
            }
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .confirmationDialog(viewModel.confirmTitle, isPresented: $viewModel.isConfirming, titleVisibility: .visible) {
            Button(viewModel.pendingAction == .unban ? viewModel.unbanTitle : viewModel.banTitle,
                   role: viewModel.pendingAction == .unban ? nil : .destructive) {
                Task { await viewModel.actionConfirmed() }
            }
            Button(SharedStrings.cancel, role: .cancel) {}
        }
    }

    private var content: some View {
        LoadStateView(viewModel.state, onRetry: retry) { card in
            List {
                Section {
                    InfoRow(verbatim: card.name, value: card.username)
                    Text(verbatim: card.reportsText).font(Theme.Font.body)
                    ForEach(card.reportLines, id: \.self) { line in
                        Text(verbatim: line).font(Theme.Font.footnote).foregroundStyle(Theme.Color.textSecondary)
                    }
                }
                Section {
                    Button(viewModel.banTitle, role: .destructive) { viewModel.banTapped() }
                        .frame(minHeight: Theme.Size.minTapTarget)
                    Button(viewModel.unbanTitle) { viewModel.unbanTapped() }
                        .frame(minHeight: Theme.Size.minTapTarget)
                    if let result = viewModel.resultText { SafetyNote(result, style: .info) }
                    if viewModel.actionFailed { SafetyNote(viewModel.actionError, style: .warning) }
                }
            }
            .listStyle(.insetGrouped)
            .vybeListBackground()
        } placeholder: {
            List { Text(verbatim: viewModel.title) }.redacted(reason: .placeholder)
        } empty: {
            EmptyStateView(systemImage: "person.crop.circle.badge.questionmark", message: viewModel.emptyMessage)
        }
        .searchable(text: $viewModel.query, prompt: Text(verbatim: viewModel.searchPrompt))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit(of: .search) { Task { await viewModel.searchSubmitted() } }
    }
}
