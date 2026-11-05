import Components
import Design
import SwiftUI

/// Shown when the reason is self-harm: a warm note and the two numbers, each one tap to call.
struct SelfHarmHelpCard: View {
    let viewModel: ReportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Label {
                Text(verbatim: viewModel.helpTitle)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
            } icon: {
                Image(systemName: "heart.fill").foregroundStyle(Theme.Color.critical)
            }
            .accessibilityAddTraits(.isHeader)

            Text(verbatim: viewModel.helpBody)
                .font(Theme.Font.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: Theme.Spacing.small) {
                ForEach(viewModel.helpLines) { line in
                    if let url = line.url {
                        Link(destination: url) { HelpLineLabel(line: line) }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.roundedRectangle(radius: Theme.Radius.medium))
                            .tint(Theme.Color.accent)
                    }
                }
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.large))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.large).strokeBorder(Theme.Color.critical.opacity(0.4))
        }
        .accessibilityElement(children: .contain)
    }
}

private struct HelpLineLabel: View {
    let line: HelpLine

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: "phone.fill").accessibilityHidden(true)
            Text(verbatim: line.name).font(Theme.Font.body)
            Spacer(minLength: Theme.Spacing.small)
            Text(verbatim: line.number).font(Theme.Font.headline).monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
        .accessibilityElement(children: .combine)
    }
}

/// The thank-you page after sending.
struct ReportSentView: View {
    let viewModel: ReportViewModel
    let hidden: Bool

    @ScaledMetric private var iconSize: CGFloat = 76
    @State private var shown = false

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Spacer(minLength: Theme.Spacing.large)
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(Theme.Color.positive)
                .scaleEffect(shown ? 1 : 0.6)
                .opacity(shown ? 1 : 0)
                .vybeAnimation(Theme.Motion.playful, value: shown)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.small) {
                Text(verbatim: viewModel.thanksTitle)
                    .font(Theme.Font.title2.bold())
                    .foregroundStyle(Theme.Color.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: viewModel.thanksBody)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .multilineTextAlignment(.center)
            if hidden { SafetyNote(viewModel.hiddenNote, style: .info) }
            Spacer(minLength: Theme.Spacing.large)
            VStack(spacing: Theme.Spacing.small) {
                if viewModel.offersBlock {
                    SecondaryButton(verbatim: viewModel.blockTitle) { viewModel.blockTapped() }
                }
                PrimaryButton(verbatim: viewModel.doneTitle) { viewModel.doneTapped() }
            }
        }
        .padding(Theme.Spacing.large)
        .onAppear { shown = true }
    }
}
