import Design
import SwiftUI

/// Layout only: every value comes from `AccountBasicsViewModel`, every tap goes to it.
struct AccountBasicsView: View {
    @State private var viewModel: AccountBasicsViewModel

    init(viewModel: AccountBasicsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isBlocked {
                BlockedView()
            } else {
                form
            }
        }
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isBlocked)   // no way back to change the date
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                Text(verbatim: AccountBasicsText.title)
                    .font(Theme.Font.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                usernameSection
                DatePicker(AccountBasicsText.birthDate, selection: $viewModel.birthDate,
                           in: ...viewModel.today, displayedComponents: .date)
                    .font(Theme.Font.body)
                    .tint(Theme.Color.accent)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .accessibilityIdentifier("auth.accountBasics.birthDate")
                if let error = viewModel.errorMessage {
                    Text(verbatim: error)
                        .font(Theme.Font.subheadline)
                        .foregroundStyle(Theme.Color.critical)
                }
            }
            .padding(Theme.Spacing.large)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(verbatim: AccountBasicsText.continueButton, isLoading: viewModel.isSubmitting) {
                Task { await viewModel.continueTapped() }
            }
            .disabled(!viewModel.canContinue)
            .padding(Theme.Spacing.large)
            .accessibilityIdentifier("auth.accountBasics.continue")
        }
    }

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: AccountBasicsText.usernameLabel)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            HStack(spacing: Theme.Spacing.tiny) {
                Text(verbatim: "@")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .accessibilityHidden(true)
                TextField(AccountBasicsText.usernamePlaceholder, text: $viewModel.username)
                    .font(Theme.Font.body)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("auth.accountBasics.username")
            }
            .padding(Theme.Spacing.medium)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            status
        }
    }

    @ViewBuilder
    private var status: some View {
        if let text = viewModel.statusText {
            HStack(spacing: Theme.Spacing.small) {
                Text(verbatim: text)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(statusColor)
                if viewModel.availability == .failed {
                    Button(AccountBasicsText.retry) { viewModel.retryCheck() }
                        .font(Theme.Font.footnote)
                        .frame(minHeight: Theme.Size.minTapTarget)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var statusColor: Color {
        switch viewModel.availability {
        case .available: Theme.Color.positive
        case .checking, .idle: Theme.Color.textSecondary
        case .invalid, .taken, .failed: Theme.Color.critical
        }
    }
}

/// The calm blocking screen for someone under 18. No form, no way back.
private struct BlockedView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: "hand.raised.circle")
                .font(Theme.Font.largeTitle)
                .imageScale(.large)
                .foregroundStyle(Theme.Color.accent)
                .accessibilityHidden(true)
            Text(verbatim: AccountBasicsText.blockedTitle)
                .font(Theme.Font.title2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: AccountBasicsText.blockedMessage)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("auth.accountBasics.blocked")
    }
}
