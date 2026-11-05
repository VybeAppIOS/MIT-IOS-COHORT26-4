import Components
import Design
import SwiftUI

/// Layout only: every value comes from `InvitationViewModel`, every tap goes to it.
/// The router's sheet host gives this screen its own stack, so it only sets a title.
struct InvitationView: View {
    @State private var viewModel: InvitationViewModel

    init(viewModel: InvitationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(
            viewModel.state,
            onRetry: { Task { await viewModel.reload() } },
            content: { content in invitation(content) },
            placeholder: { InvitationSkeleton() },
            empty: { EmptyStateView(systemImage: "envelope.open", message: viewModel.emptyMessage) })
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.Color.surface)
        .task { await viewModel.load() }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .alert(
            Text(verbatim: viewModel.notice ?? ""),
            isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
        ) {
            Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
        }
    }

    private func invitation(_ content: InvitationContent) -> some View {
        VStack(spacing: Theme.Spacing.large) {
            Spacer(minLength: 0)
            AvatarStack(
                content.memberNames.enumerated().map { AvatarStackPerson(id: "\($0.offset)", name: $0.element) },
                maxShown: 5, size: .large)
            Text(verbatim: content.headline)
                .font(Theme.Font.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: viewModel.hint).font(Theme.Font.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.large)
        .frame(maxWidth: .infinity)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Spacing.small) {
                PrimaryButton(verbatim: viewModel.joinLabel, isLoading: viewModel.isWorking) {
                    Task { await viewModel.joinTapped() }
                }
                .disabled(!viewModel.canAnswer)
                Button(role: .destructive) { Task { await viewModel.leaveAndBlockTapped() } } label: {
                    Text(verbatim: viewModel.leaveAndBlockLabel).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(minHeight: Theme.Size.minTapTarget)
                .disabled(!viewModel.canAnswer)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.small)
            .background(.bar)
        }
    }
}

private struct InvitationSkeleton: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            SkeletonLine(widthFraction: 0.5)
            SkeletonLine(widthFraction: 0.8)
        }
        .padding(Theme.Spacing.large)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
