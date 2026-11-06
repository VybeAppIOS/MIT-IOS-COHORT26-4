import AuthenticationServices
import Design
import SwiftUI

/// Layout only: every value comes from `SignInViewModel`, every tap goes to it.
struct SignInView: View {
    @State private var viewModel: SignInViewModel
    /// Matches the height of the bordered Google and email buttons.
    @ScaledMetric(relativeTo: .headline) private var appleButtonHeight = 57.0
    @Environment(\.colorScheme) private var colorScheme

    init(viewModel: SignInViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text(verbatim: SignInText.title)
                            .font(Theme.Font.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .accessibilityAddTraits(.isHeader)
                        Text(verbatim: SignInText.subtitle)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    providers
                    if let error = viewModel.errorMessage {
                        failure(error)
                    }
                }
                .padding(Theme.Spacing.large)
                // At least the screen's height, centred: the block sits in the middle, and still scrolls when large
                // text makes it taller than the screen.
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom) {
            // Plain text until the Terms and Privacy Policy pages exist (no dead links).
            Text(verbatim: SignInText.terms)
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(Theme.Spacing.large)
        }
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var providers: some View {
        VStack(spacing: Theme.Spacing.medium) {
            appleButton
            Button { Task { await viewModel.googleTapped() } } label: {
                providerLabel(SignInText.google, systemImage: "g.circle", isLoading: viewModel.loading == .google)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("auth.signIn.google")
            Button { viewModel.emailTapped() } label: {
                providerLabel(SignInText.email, systemImage: "envelope", isLoading: false)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("auth.signIn.email")
        }
        .tint(Theme.Color.accent)                       // Theme colour, not the system blue
        .disabled(viewModel.isBusy)
    }

    /// Apple's own button, drawn as Apple requires. Phase 1 is "UI only": the tap goes to our ViewModel (the
    /// `AuthRepository` stub), so the system sign-in, which needs the Sign in with Apple capability, never starts.
    private var appleButton: some View {
        Button { Task { await viewModel.appleTapped() } } label: {
            SignInWithAppleButton(.signIn, onRequest: { _ in }, onCompletion: { _ in })
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)   // Apple's own light/dark pair
                .frame(height: appleButtonHeight)
                .clipShape(Capsule())               // the same capsule shape as the Google and email buttons
                .allowsHitTesting(false)
                .overlay {
                    if viewModel.loading == .apple { ProgressView().tint(Theme.Color.onAccent) }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("auth.signIn.apple")
    }

    private func providerLabel(_ title: String, systemImage: String, isLoading: Bool) -> some View {
        HStack(spacing: Theme.Spacing.small) {
            if isLoading {
                ProgressView()
            } else {
                Image(systemName: systemImage).accessibilityHidden(true)
            }
            Text(verbatim: title)
        }
        .font(Theme.Font.headline)
        .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
    }

    private func failure(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: message)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.critical)
            Button(SignInText.retry) { Task { await viewModel.retryTapped() } }
                .font(Theme.Font.headline)
                .frame(minHeight: Theme.Size.minTapTarget)
                .accessibilityIdentifier("auth.signIn.retry")
        }
    }
}
