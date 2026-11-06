import Design
import SwiftUI

/// Layout only: every value comes from `HubViewModel`, every tap goes to it.
struct HubView: View {
    @State private var viewModel: HubViewModel

    init(viewModel: HubViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in list(content) },
            placeholder: { PersonListSkeleton() },
            empty: {
                EmptyStateView(
                    systemImage: "person.2", message: viewModel.emptyMessage, actionTitle: viewModel.emptyAction,
                    action: { viewModel.findPeopleTapped() })
            })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .sheet(isPresented: $viewModel.showsOtherRequests) { OtherRequestsSheet(viewModel: viewModel) }
        .confirmationDialog(
            Text(verbatim: viewModel.removeTitle),
            isPresented: Binding(get: { viewModel.removingID != nil }, set: { if !$0 { viewModel.cancelRemove() } }),
            titleVisibility: .visible
        ) {
            Button(role: .destructive) { Task { await viewModel.confirmRemove() } } label: {
                Text(verbatim: viewModel.removeLabel)
            }
            Button(role: .cancel) { viewModel.cancelRemove() } label: { Text(verbatim: viewModel.cancelLabel) }
        }
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
        .hidesTabBar()
    }

    // MARK: Sections

    private func list(_ content: HubContent) -> some View {
        List {
            if viewModel.isSearching {
                searchResults(content)
            } else {
                sections(content)
            }
        }
        .listStyle(.insetGrouped)
        .searchable(
            text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(verbatim: viewModel.searchPrompt))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }

    /// While searching: only the friends that match, and nothing else.
    @ViewBuilder
    private func searchResults(_ content: HubContent) -> some View {
        let matches = viewModel.matchingFriends(in: content)
        if matches.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
                .listRowBackground(Color.clear)
        } else {
            Section { ForEach(matches) { friendRow($0) } } header: { header(viewModel.friendsTitle) }
        }
    }

    @ViewBuilder
    private func sections(_ content: HubContent) -> some View {
        if let limit = content.limit {
            Section {
                Label { Text(verbatim: viewModel.limitText(limit)) } icon: { Image(systemName: "info.circle") }
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        if !content.requests.isEmpty {
            Section { ForEach(content.requests) { answerRow($0) } } header: { header(viewModel.requestsTitle) }
        }
        if !content.otherRequests.isEmpty {
            Section {
                Button { viewModel.otherRequestsTapped() } label: {
                    HStack {
                        Text(verbatim: viewModel.otherRequestsText(content.otherRequests.count))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").foregroundStyle(Theme.Color.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: Theme.Size.minTapTarget)
                }
            }
        }
        if !content.sent.isEmpty {
            Section { ForEach(content.sent) { sentRow($0) } } header: { header(viewModel.sentTitle) }
        }
        if !content.suggestions.isEmpty {
            Section {
                ForEach(content.suggestions) { suggestionRow($0, canAdd: content.limit == nil) }
            } header: { header(viewModel.suggestionsTitle) }
        }
        if !content.friends.isEmpty {
            Section { ForEach(content.friends) { friendRow($0) } } header: { header(viewModel.friendsTitle) }
        }
    }

    private func header(_ text: String) -> some View {
        Text(verbatim: text).accessibilityAddTraits(.isHeader)
    }

    // MARK: Rows

    /// A request you can answer: the person, then Accept and Ignore.
    func answerRow(_ person: PersonRowData) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            PersonRow(person: person, open: { viewModel.personTapped(person.id) }, trailing: { EmptyView() })
            AnswerButtons(
                acceptLabel: viewModel.acceptLabel, ignoreLabel: viewModel.ignoreLabel,
                accept: { Task { await viewModel.acceptTapped(person.id) } },
                ignore: { viewModel.ignoreTapped(person.id) })
        }
    }

    private func sentRow(_ person: PersonRowData) -> some View {
        PersonRow(person: person, open: { viewModel.personTapped(person.id) }, trailing: {
            PillButton(verbatim: viewModel.cancelRequestLabel) {
                Task { await viewModel.cancelRequestTapped(person.id) }
            }
        })
    }

    private func suggestionRow(_ person: PersonRowData, canAdd: Bool) -> some View {
        PersonRow(person: person, open: { viewModel.personTapped(person.id) }, trailing: {
            PillButton(verbatim: viewModel.addLabel, style: .prominent) {
                Task { await viewModel.addTapped(person.id) }
            }
            .disabled(!canAdd)
        })
    }

    private func friendRow(_ person: PersonRowData) -> some View {
        PersonRow(person: person, open: { viewModel.personTapped(person.id) }, trailing: {
            Menu {
                Button { viewModel.messageTapped(person.id) } label: {
                    Label { Text(verbatim: viewModel.messageLabel) } icon: { Image(systemName: "bubble.left") }
                }
                Button(role: .destructive) { viewModel.removeTapped(person.id) } label: {
                    Label { Text(verbatim: viewModel.removeLabel) } icon: { Image(systemName: "person.badge.minus") }
                }
                Button(role: .destructive) { viewModel.blockTapped(person.id) } label: {
                    Label { Text(verbatim: viewModel.blockLabel) } icon: { Image(systemName: "hand.raised") }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Theme.Color.textSecondary)
                    .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            }
            .accessibilityLabel(Text(verbatim: viewModel.moreLabel))
        })
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { viewModel.removeTapped(person.id) } label: {
                Text(verbatim: viewModel.removeLabel)
            }
        }
    }
}

/// Accept and Ignore under a request, side by side.
private struct AnswerButtons: View {
    let acceptLabel: String
    let ignoreLabel: String
    let accept: () -> Void
    let ignore: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            PillButton(verbatim: acceptLabel, style: .prominent, fillsWidth: true, action: accept)
            PillButton(verbatim: ignoreLabel, fillsWidth: true, action: ignore)
        }
    }
}

/// The "Other requests" list: requests from people with no mutual friends. A local sheet.
private struct OtherRequestsSheet: View {
    let viewModel: HubViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if case .loaded(let content, _) = viewModel.state {
                    ForEach(content.otherRequests) { person in
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            PersonRow(
                                person: person, open: { viewModel.personTapped(person.id) },
                                trailing: { EmptyView() })
                            AnswerButtons(
                acceptLabel: viewModel.acceptLabel, ignoreLabel: viewModel.ignoreLabel,
                accept: { Task { await viewModel.acceptTapped(person.id) } },
                ignore: { viewModel.ignoreTapped(person.id) })
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text(verbatim: viewModel.otherTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text(verbatim: viewModel.doneLabel) }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
