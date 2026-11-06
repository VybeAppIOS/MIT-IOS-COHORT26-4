import Components
import Design
import SwiftUI

/// Layout only: every value comes from `GroupInfoViewModel`, every tap goes to it.
struct GroupInfoView: View {
    @State private var viewModel: GroupInfoViewModel

    init(viewModel: GroupInfoViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in list(content) },
            placeholder: { GroupInfoSkeleton() },
            empty: { EmptyStateView(systemImage: "person.slash", message: viewModel.nothingToAdd) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .sheet(isPresented: $viewModel.isAddingMembers) { addSheet }
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
        .confirmationDialog(
            Text(verbatim: viewModel.leaveTitle), isPresented: $viewModel.isConfirmingLeave, titleVisibility: .visible
        ) {
            Button(role: .destructive) { Task { await viewModel.confirmLeave() } } label: {
                Text(verbatim: viewModel.leaveLabel)
            }
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.cancelLabel) }
        }
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
        .hidesTabBar()
    }

    private func list(_ content: GroupInfoContent) -> some View {
        List {
            Section {
                if content.isAdmin {
                    HStack {
                        TextField(text: $viewModel.draftName) { Text(verbatim: viewModel.nameHeader) }
                            .frame(minHeight: Theme.Size.minTapTarget)
                        PillButton(verbatim: viewModel.saveLabel, style: .prominent) {
                            Task { await viewModel.saveNameTapped() }
                        }
                        .disabled(!viewModel.canSaveName)
                    }
                } else {
                    Text(verbatim: content.name).frame(minHeight: Theme.Size.minTapTarget)
                }
            } header: { Text(verbatim: viewModel.nameHeader) } footer: {
                if content.isReadOnly { Text(verbatim: viewModel.readOnlyNote) }
            }
            Section {
                Button { viewModel.photosTapped() } label: {
                    HStack {
                        Label { Text(verbatim: viewModel.photosLabel).foregroundStyle(Theme.Color.textPrimary) }
                            icon: { Image(systemName: "photo.on.rectangle") }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .contentShape(.rect)
                }
            }
            Section {
                ForEach(content.members) { member in memberRow(member) }
                Button { viewModel.addTapped() } label: {
                    Label { Text(verbatim: viewModel.addLabel) } icon: { Image(systemName: "person.badge.plus") }
                        .frame(minHeight: Theme.Size.minTapTarget)
                }
                .disabled(!viewModel.canAdd)
            } header: { Text(verbatim: viewModel.membersHeader).accessibilityAddTraits(.isHeader) }
            Section {
                Button(role: .destructive) { viewModel.isConfirmingLeave = true } label: {
                    Text(verbatim: viewModel.leaveLabel).frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
                }
            }
        }
        .listStyle(.insetGrouped)
        .vybeListBackground()
    }

    private func memberRow(_ member: MemberRowData) -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            Button { viewModel.memberTapped(member.id) } label: {
                HStack(spacing: Theme.Spacing.medium) {
                    Avatar(url: nil, name: member.name, size: .medium)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: member.name).foregroundStyle(Theme.Color.textPrimary)
                        Text(verbatim: member.username).font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer(minLength: 0)
                    if member.showsMutedLabel {
                        Text(verbatim: viewModel.mutedLabel).font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    if member.isAdmin {
                        Text(verbatim: viewModel.adminLabel).font(Theme.Font.footnote)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
                .frame(minHeight: Theme.Size.minTapTarget)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            if member.hasMenu { actionsMenu(member) }
        }
        .swipeActions(edge: .trailing) {
            if member.canRemove, viewModel.canAdminister {
                Button(role: .destructive) { viewModel.removeTapped(member.id) } label: {
                    Text(verbatim: viewModel.removeLabel)
                }
            }
        }
    }

    /// The ••• menu on every other member, for the admin. Offline it is greyed out.
    private func actionsMenu(_ member: MemberRowData) -> some View {
        Menu {
            if member.canMute {
                Button { Task { await viewModel.muteTapped(member.id) } } label: {
                    Label { Text(verbatim: member.muteLabel) } icon: {
                        Image(systemName: member.isMuted ? "speaker.wave.2" : "speaker.slash")
                    }
                }
            }
            if member.canRemove {
                Button(role: .destructive) { viewModel.removeTapped(member.id) } label: {
                    Label { Text(verbatim: viewModel.removeLabel) } icon: { Image(systemName: "person.badge.minus") }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Theme.Color.textSecondary)
                .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                .contentShape(.rect)
        }
        .disabled(!viewModel.canAdminister)
        .accessibilityLabel(Text(verbatim: member.menuLabel))
    }

    private var addSheet: some View {
        NavigationStack {
            List {
                if case .loaded(let content, _) = viewModel.state {
                    if content.addable.isEmpty {
                        Text(verbatim: viewModel.nothingToAdd).foregroundStyle(Theme.Color.textSecondary)
                    }
                    ForEach(content.addable) { person in
                        Button { viewModel.togglePick(person.id) } label: {
                            HStack {
                                Text(verbatim: person.name).foregroundStyle(Theme.Color.textPrimary)
                                Spacer(minLength: 0)
                                Image(systemName: viewModel.picked.contains(person.id)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Theme.Color.accent)
                            }
                            .frame(minHeight: Theme.Size.minTapTarget)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .vybeListBackground()
            .navigationTitle(Text(verbatim: viewModel.addTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await viewModel.confirmAdd() } } label: { Text(verbatim: viewModel.doneLabel) }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct GroupInfoSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.5)
            SkeletonLine()
            SkeletonLine(widthFraction: 0.7)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
