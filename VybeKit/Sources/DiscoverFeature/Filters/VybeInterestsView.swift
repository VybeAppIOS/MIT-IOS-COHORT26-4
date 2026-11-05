import Design
import SwiftUI

/// "Find your Vybe": every interest, grouped under section headers, as chips that wrap (no sideways scrolling).
/// Pushed inside the filters sheet. It edits the same draft as the main sheet, so going back keeps the choices and
/// only Apply changes the map. The interests and their order come from `VybeSection` (data, not this view).
struct VybeInterestsView: View {
    let viewModel: DiscoverMapViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                ForEach(VybeSection.allCases, id: \.self) { section in
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text(verbatim: section.title)
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                            ForEach(section.interests, id: \.self) { interest in
                                FilterChip(verbatim: interest.title,
                                           isSelected: viewModel.isInterestSelected(interest)) {
                                    viewModel.toggleInterest(interest)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(Text(verbatim: FiltersText.findYourVybe))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { ApplyBar(viewModel: viewModel) }
    }
}
