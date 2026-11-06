import Components
import Design
import SwiftUI

/// Layout only: every value comes from `ShareSheetViewModel`, every tap goes to it.
/// The router's sheet host gives this screen its own stack, so it only sets a title and toolbar.
struct ShareSheetView: View {
    @State private var viewModel: ShareSheetViewModel

    init(viewModel: ShareSheetViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in list(content) },
            placeholder: { ShareSkeleton() },
            empty: { EmptyStateView(systemImage: "person.2", message: viewModel.emptyMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { viewModel.cancelTapped() } label: { Text(verbatim: viewModel.cancelLabel) }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { Task { await viewModel.sendTapped() } } label: { Text(verbatim: viewModel.sendLabel) }
                    .disabled(!viewModel.canSend)
            }
        }
        .task { await viewModel.load() }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
    }

    private func list(_ content: ShareContent) -> some View {
        List {
            if !content.groups.isEmpty {
                Section { ForEach(content.groups) { row($0) } } header: {
                    Text(verbatim: viewModel.groupsHeader)
                }
            }
            if !content.friends.isEmpty {
                Section { ForEach(content.friends) { row($0) } } header: {
                    Text(verbatim: viewModel.friendsHeader)
                }
            }
            Section {
                if let text = viewModel.shareText {
                    ShareLink(item: text) {
                        Label { Text(verbatim: viewModel.moreLabel) } icon: { Image(systemName: "square.and.arrow.up") }
                            .frame(minHeight: Theme.Size.minTapTarget)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .vybeListBackground()
    }

    private func row(_ target: ShareTarget) -> some View {
        Button { viewModel.toggle(target.id) } label: {
            HStack(spacing: Theme.Spacing.medium) {
                Avatar(url: nil, name: target.name, size: .medium)
                Text(verbatim: target.name).foregroundStyle(Theme.Color.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: viewModel.isSelected(target.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(viewModel.isSelected(target.id) ? Theme.Color.accent : Theme.Color.textSecondary)
            }
            .frame(minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(viewModel.isSelected(target.id) ? .isSelected : [])
        .disabled(viewModel.isOffline)
    }
}

private struct ShareSkeleton: View {
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
