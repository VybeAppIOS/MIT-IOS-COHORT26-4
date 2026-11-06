import Components
import Design
import SwiftUI

/// Layout only: who you are, Sign out (confirmed), and Delete account at the bottom, never the default action.
struct AccountSettingsView: View {
    @State private var viewModel: AccountSettingsViewModel

    init(viewModel: AccountSettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                InfoRow(verbatim: viewModel.nameLabel, value: viewModel.name)
                InfoRow(verbatim: viewModel.usernameLabel, value: viewModel.username)
                InfoRow(verbatim: viewModel.signInLabel, value: viewModel.signInValue)
            }
            Section {
                Button(role: .destructive) {
                    viewModel.signOutTapped()
                } label: {
                    HStack(spacing: Theme.Spacing.small) {
                        Label(viewModel.signOutTitle, systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer(minLength: 0)
                        if viewModel.isSigningOut { ProgressView() }
                    }
                    .font(Theme.Font.body)
                    .frame(minHeight: Theme.Size.minTapTarget)
                }
                .foregroundStyle(Theme.Color.critical)
                .disabled(!viewModel.canSignOut)
                .accessibilityIdentifier("profile.account.signOut")
            } footer: {
                if viewModel.isOffline {
                    Text(verbatim: viewModel.offlineMessage)
                } else if viewModel.hasFailed {
                    Text(verbatim: viewModel.errorMessage).foregroundStyle(Theme.Color.critical)
                }
            }
            Section {
                NavRow(verbatim: viewModel.deleteTitle, subtitle: viewModel.deleteSubtitle, systemImage: "trash") {
                    viewModel.deleteAccountTapped()
                }
                .accessibilityIdentifier("profile.account.delete")
            }
        }
        .listStyle(.insetGrouped)
        .vybeListBackground()
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(viewModel.signOutConfirmTitle, isPresented: $viewModel.isConfirmingSignOut,
                            titleVisibility: .visible) {
            Button(viewModel.signOutTitle, role: .destructive) { Task { await viewModel.signOutConfirmed() } }
            Button(SharedStrings.cancel, role: .cancel) {}
        } message: {
            Text(verbatim: viewModel.signOutMessage)
        }
        .hidesTabBar()
    }
}
