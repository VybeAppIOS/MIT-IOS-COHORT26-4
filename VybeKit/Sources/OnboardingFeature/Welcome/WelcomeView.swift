import Design
import SwiftUI

/// Layout only: every value comes from `WelcomeViewModel`, every tap goes to it.
/// VoiceOver reads: pitch, Get started, "Already have an account? Sign in". The hero drawing is decorative.
struct WelcomeView: View {
    @State private var viewModel: WelcomeViewModel
    @Environment(\.dynamicTypeSize) private var typeSize

    init(viewModel: WelcomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Theme.Spacing.extraLarge) {
                    WelcomeHero()
                        .frame(height: heroHeight(for: proxy.size.height))
                        .accessibilityHidden(true)

                    Text(pitch)
                        .font(Theme.Font.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("onboarding.welcome.pitch")

                    Spacer(minLength: 0)

                    VStack(spacing: Theme.Spacing.small) {
                        PrimaryButton(verbatim: WelcomeText.getStarted) { viewModel.getStarted() }
                            .accessibilityIdentifier("onboarding.welcome.getStarted")
                        Button { viewModel.signIn() } label: {
                            Text(signInLine)
                                .font(Theme.Font.callout)
                                .multilineTextAlignment(.center)
                                .frame(minHeight: Theme.Size.minTapTarget)
                        }
                        .accessibilityLabel(Text(verbatim: "\(WelcomeText.haveAccount) \(WelcomeText.signIn)"))
                        .accessibilityIdentifier("onboarding.welcome.signIn")
                    }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.vertical, Theme.Spacing.large)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Theme.Color.surface)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// About half the screen; smaller at accessibility text sizes so the pitch and button stay in view.
    private func heroHeight(for screenHeight: CGFloat) -> CGFloat {
        screenHeight * (typeSize.isAccessibilitySize ? 0.3 : 0.52)
    }

    /// "Find your Vybe." with the app's name in the accent colour.
    private var pitch: AttributedString {
        var text = AttributedString(WelcomeText.pitch)
        if let name = text.range(of: WelcomeText.wordmark) {
            text[name].foregroundColor = Theme.Color.accent
        }
        return text
    }

    /// "Already have an account? Sign in": the question in secondary text, "Sign in" in bold accent.
    private var signInLine: AttributedString {
        var question = AttributedString(WelcomeText.haveAccount + " ")
        question.foregroundColor = Theme.Color.textSecondary
        var action = AttributedString(WelcomeText.signIn)
        action.foregroundColor = Theme.Color.accent
        action.inlinePresentationIntent = .stronglyEmphasized
        return question + action
    }
}

/// The hero card: an accent gradient with two soft circles and a route through three Spots.
/// Every position is a fraction of the card's size (0...1 across, 0...1 down), so it scales with any screen.
private struct WelcomeHero: View {
    /// The three Spots, bottom-left to top-right.
    private let spots = [CGPoint(x: 0.31, y: 0.69), CGPoint(x: 0.49, y: 0.49), CGPoint(x: 0.69, y: 0.31)]
    /// Where each curve bends: between Spots 1 and 2, then between Spots 2 and 3.
    private let bends = [CGPoint(x: 0.33, y: 0.52), CGPoint(x: 0.66, y: 0.46)]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let unit = min(size.width, size.height)
            ZStack {
                Rectangle().fill(Theme.Color.accent.gradient)
                softCircle(diameter: size.width * 0.66, at: point(CGPoint(x: 0.83, y: 0.16), in: size))
                softCircle(diameter: size.width * 0.8, at: point(CGPoint(x: 0.1, y: 0.87), in: size))
                Path { path in
                    path.move(to: point(spots[0], in: size))
                    path.addQuadCurve(to: point(spots[1], in: size), control: point(bends[0], in: size))
                    path.addQuadCurve(to: point(spots[2], in: size), control: point(bends[1], in: size))
                }
                .stroke(Theme.Color.onAccent, style: StrokeStyle(lineWidth: unit * 0.018, lineCap: .round))
                ForEach(spots.indices, id: \.self) { index in
                    Circle()
                        .strokeBorder(Theme.Color.onAccent, lineWidth: unit * 0.032)
                        .background(Circle().fill(Theme.Color.accent))
                        .frame(width: unit * 0.1, height: unit * 0.1)
                        .position(point(spots[index], in: size))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }

    /// A fraction of the card as a point inside it.
    private func point(_ fraction: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * fraction.x, y: size.height * fraction.y)
    }

    private func softCircle(diameter: CGFloat, at center: CGPoint) -> some View {
        Circle()
            .fill(Theme.Color.onAccent.opacity(0.08))
            .frame(width: diameter, height: diameter)
            .position(center)
    }
}
