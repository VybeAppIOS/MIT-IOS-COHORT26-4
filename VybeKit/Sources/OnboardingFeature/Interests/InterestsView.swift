import Design
import SwiftUI

/// Layout only: every value comes from `InterestsViewModel`, every tap goes to it.
struct InterestsView: View {
    @State private var viewModel: InterestsViewModel

    init(viewModel: InterestsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(verbatim: InterestsText.title)
                        .font(Theme.Font.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: InterestsText.subtitle)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                    ForEach(InterestOption.allCases, id: \.self) { interest in
                        FilterChip(verbatim: interest.title, isSelected: viewModel.isSelected(interest)) {
                            viewModel.toggle(interest)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Spacing.small) {
                if let progress = viewModel.progressText {
                    Text(verbatim: progress)
                        .font(Theme.Font.footnote)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                PrimaryButton(verbatim: InterestsText.continueButton) { viewModel.continueTapped() }
                    .disabled(!viewModel.canContinue)
                    .accessibilityIdentifier("onboarding.interests.continue")
            }
            .padding(Theme.Spacing.large)
            .background(.bar)
        }
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
    }
}
