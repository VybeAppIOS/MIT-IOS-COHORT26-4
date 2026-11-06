import Components
import Design
import SwiftUI

/// Layout only: every value comes from `NewChatViewModel`, every tap goes to it. A local sheet with its own stack.
struct NewChatView: View {
    @State private var viewModel: NewChatViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: NewChatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            LoadStateView(
                viewModel.state,
                onRetry: { Task { await viewModel.reload() } },
                content: { content in list(content) },
                placeholder: { NewChatSkeleton() },
                empty: { EmptyStateView(systemImage: "person.2", message: viewModel.emptyMessage) })
            .navigationTitle(Text(verbatim: viewModel.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(verbatim: viewModel.cancelLabel) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await viewModel.createTapped() } } label: {
                        Text(verbatim: viewModel.createLabel)
                    }
                    .disabled(!viewModel.canCreate)
                }
            }
            .task { await viewModel.load() }
            .alert(
                Text(verbatim: viewModel.notice ?? ""),
                isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
            ) {
                Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func list(_ content: NewChatContent) -> some View {
        List {
            if viewModel.isGroup {
                Section {
                    TextField(text: $viewModel.groupName) { Text(verbatim: viewModel.namePlaceholder) }
                        .frame(minHeight: Theme.Size.minTapTarget)
                }
            }
            Section {
                let people = viewModel.visibleFriends(in: content)
                if people.isEmpty && viewModel.isSearching {
                    ContentUnavailableView.search(text: viewModel.searchText)
                        .listRowBackground(Color.clear)
                }
                ForEach(people) { person in
                    Button { viewModel.toggle(person.id) } label: {
                        HStack(spacing: Theme.Spacing.medium) {
                            Avatar(url: nil, name: person.name, size: .medium)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(verbatim: person.name).foregroundStyle(Theme.Color.textPrimary)
                                Text(verbatim: person.username).font(Theme.Font.footnote)
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: viewModel.isSelected(person.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(
                                    viewModel.isSelected(person.id) ? Theme.Color.accent : Theme.Color.textSecondary)
                        }
                        .frame(minHeight: Theme.Size.minTapTarget)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(viewModel.isSelected(person.id) ? .isSelected : [])
                }
            } footer: {
                if let hint = viewModel.hint { Text(verbatim: hint) }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(verbatim: viewModel.searchPrompt))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }
}

private struct NewChatSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.6)
            SkeletonLine(widthFraction: 0.8)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
