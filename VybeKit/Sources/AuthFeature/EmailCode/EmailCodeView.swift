import Design
import SwiftUI

/// Layout only: every value comes from `EmailCodeViewModel`, every tap goes to it.
struct EmailCodeView: View {
    @State private var viewModel: EmailCodeViewModel
    @FocusState private var codeFocused: Bool

    init(viewModel: EmailCodeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                switch viewModel.step {
                case .email: emailStep
                case .code: codeStep
                }
                if let error = viewModel.errorMessage {
                    Text(verbatim: error)
                        .font(Theme.Font.subheadline)
                        .foregroundStyle(Theme.Color.critical)
                        .accessibilityIdentifier("auth.emailCode.error")
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.code) {
            if viewModel.isCodeComplete { Task { await viewModel.verifyCode() } }   // checks on the 6th digit
        }
    }

    // MARK: Step 1: email

    private var emailStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            title(EmailCodeText.emailTitle)
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                TextField(EmailCodeText.emailPlaceholder, text: $viewModel.email)
                    .font(Theme.Font.body)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .onSubmit { Task { await viewModel.sendCodeTapped() } }
                    .padding(Theme.Spacing.medium)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
                    .accessibilityIdentifier("auth.emailCode.email")
                if let error = viewModel.emailError {
                    Text(verbatim: error)
                        .font(Theme.Font.footnote)
                        .foregroundStyle(Theme.Color.critical)
                }
            }
            PrimaryButton(verbatim: EmailCodeText.sendCode, isLoading: viewModel.isSending) {
                Task { await viewModel.sendCodeTapped() }
            }
            .disabled(!viewModel.canSendCode)
            .accessibilityIdentifier("auth.emailCode.send")
        }
    }

    // MARK: Step 2: code

    private var codeStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                title(EmailCodeText.codeTitle)
                Text(verbatim: EmailCodeText.codeSentTo(viewModel.trimmedEmail))
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                Button(EmailCodeText.changeEmail) { viewModel.changeEmailTapped() }
                    .font(Theme.Font.subheadline)
                    .frame(minHeight: Theme.Size.minTapTarget)
            }
            codeBoxes
            TimelineView(.periodic(from: .now, by: 1)) { _ in          // refreshes the countdown once a second
                Button(viewModel.resendText) { Task { await viewModel.resendTapped() } }
                    .font(Theme.Font.subheadline)
                    .disabled(!viewModel.canResend)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .accessibilityIdentifier("auth.emailCode.resend")
            }
        }
    }

    /// Six boxes drawn over one hidden field: typing moves along by itself, and a pasted or autofilled code fills
    /// all six at once (`oneTimeCode`).
    private var codeBoxes: some View {
        ZStack {
            TextField("", text: Binding(get: { viewModel.code }, set: { viewModel.codeChanged($0) }))
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($codeFocused)
                .opacity(0.02)
                .accessibilityLabel(Text(verbatim: EmailCodeText.codeLabel))
                .accessibilityIdentifier("auth.emailCode.code")
            HStack(spacing: Theme.Spacing.small) {
                ForEach(0..<EmailCodeViewModel.codeLength, id: \.self) { index in
                    digitBox(index)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture { codeFocused = true }
        .onAppear { codeFocused = true }
        .overlay {
            if viewModel.isVerifying { ProgressView() }
        }
    }

    private func digitBox(_ index: Int) -> some View {
        let digits = Array(viewModel.code)
        let isCurrent = index == digits.count && codeFocused
        return Text(verbatim: index < digits.count ? String(digits[index]) : "")
            .font(Theme.Font.title2)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget + Theme.Spacing.medium)
            .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(isCurrent ? Theme.Color.accent : Theme.Color.separator, lineWidth: isCurrent ? 2 : 1))
    }

    private func title(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Theme.Font.title)
            .fontWeight(.bold)
            .foregroundStyle(Theme.Color.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}
