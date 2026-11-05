import Components
import Design
import SwiftUI

/// Layout only: a small sheet that says what blocking does, with Block and Cancel.
struct BlockConfirmView: View {
    @State private var viewModel: BlockConfirmViewModel
    @ScaledMetric private var iconSize: CGFloat = 64

    init(viewModel: BlockConfirmViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                Image(systemName: "hand.raised.slash.fill")
                    .font(Theme.Font.title2)
                    .foregroundStyle(Theme.Color.critical)
                    .frame(width: iconSize, height: iconSize)
                    .background(Theme.Color.critical.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
                VStack(spacing: Theme.Spacing.small) {
                    Text(verbatim: viewModel.title)
                        .font(Theme.Font.title2.bold())
                        .foregroundStyle(Theme.Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: viewModel.message)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .multilineTextAlignment(.center)
                if viewModel.hasFailed { SafetyNote(viewModel.errorMessage, style: .warning) }
                buttons
            }
            .padding(Theme.Spacing.large)
            .padding(.top, Theme.Spacing.small)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.Color.surface)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isBlocking)
        .task { await viewModel.load() }
    }

    private var buttons: some View {
        VStack(spacing: Theme.Spacing.small) {
            Button(role: .destructive) {
                Task { await viewModel.blockTapped() }
            } label: {
                HStack(spacing: Theme.Spacing.small) {
                    if viewModel.isBlocking { ProgressView().tint(Theme.Color.onAccent) }
                    Text(verbatim: viewModel.confirmTitle).font(Theme.Font.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: Theme.Radius.medium))
            .controlSize(.large)
            .tint(Theme.Color.critical)
            .frame(minHeight: Theme.Size.minTapTarget)
            .disabled(viewModel.isBlocking)

            SecondaryButton(verbatim: SharedStrings.cancel) { viewModel.cancelTapped() }
                .disabled(viewModel.isBlocking)
        }
    }
}
