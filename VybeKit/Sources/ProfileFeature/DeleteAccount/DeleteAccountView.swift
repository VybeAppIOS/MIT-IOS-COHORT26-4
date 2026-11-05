import Components
import Design
import SwiftUI

/// Layout only: what deleting does, the username to type, and a destructive button that is never the prominent one.
struct DeleteAccountView: View {
    @State private var viewModel: DeleteAccountViewModel

    init(viewModel: DeleteAccountViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                Text(verbatim: viewModel.headline)
                    .font(Theme.Font.title2.bold())
                    .foregroundStyle(Theme.Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                consequences
                VybeTextField(verbatim: viewModel.fieldLabel, text: $viewModel.typedUsername,
                              errorText: viewModel.fieldError)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .accessibilityIdentifier("profile.delete.field")
                if viewModel.isOffline { SafetyNote(viewModel.offlineMessage, style: .info) }
                if viewModel.hasFailed { SafetyNote(viewModel.errorMessage, style: .warning) }
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.large)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { deleteBar }
    }

    private var consequences: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            ForEach(viewModel.consequences, id: \.self) { line in
                Label {
                    Text(verbatim: line)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "minus.circle.fill").foregroundStyle(Theme.Color.critical)
                }
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    private var deleteBar: some View {
        Button(role: .destructive) {
            Task { await viewModel.deleteTapped() }
        } label: {
            HStack(spacing: Theme.Spacing.small) {
                if viewModel.isDeleting { ProgressView() }
                Text(verbatim: viewModel.confirmTitle).font(Theme.Font.headline)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: Theme.Radius.medium))
        .controlSize(.large)
        .tint(Theme.Color.critical)
        .frame(minHeight: Theme.Size.minTapTarget)
        .disabled(!viewModel.canDelete)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(.bar)
        .accessibilityIdentifier("profile.delete.confirm")
    }
}
