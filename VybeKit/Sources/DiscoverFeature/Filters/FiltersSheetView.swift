import Design
import SwiftUI

/// D3: the filters sheet, a local sheet of the Discover map (its flag lives in `DiscoverMapViewModel`).
/// Everything here edits the ViewModel's draft; only Apply changes the map. "Find your Vybe" pushes the full interests
/// page inside this sheet's own stack (local navigation, not the Router).
struct FiltersSheetView: View {
    let viewModel: DiscoverMapViewModel
    @State private var showsVybePage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.extraLarge) {
                    budgetSection
                    timeSection
                    chipSection(FiltersText.categories) {
                        ForEach(DiscoverMapViewModel.Chip.allCases, id: \.self) { chip in
                            FilterChip(verbatim: chip.title, isSelected: viewModel.isDraftChipSelected(chip)) {
                                viewModel.toggleDraftChip(chip)
                            }
                        }
                    }
                    chipSection(FiltersText.vibes) {
                        ForEach(MainSheetVibes.interests, id: \.self) { interest in
                            FilterChip(verbatim: interest.title, isSelected: viewModel.isInterestSelected(interest)) {
                                viewModel.toggleInterest(interest)
                            }
                        }
                    }
                    Toggle(FiltersText.goodForGroups, isOn: Binding(
                        get: { viewModel.draft.goodForGroups }, set: { viewModel.setDraftGoodForGroups($0) }))
                        .font(Theme.Font.body)
                        .tint(Theme.Color.accent)
                    findYourVybeButton
                }
                .padding(Theme.Spacing.large)
            }
            .navigationTitle(Text(verbatim: FiltersText.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(FiltersText.reset) { viewModel.resetDraft() }
                }
            }
            .safeAreaInset(edge: .bottom) { ApplyBar(viewModel: viewModel) }
            .navigationDestination(isPresented: $showsVybePage) { VybeInterestsView(viewModel: viewModel) }
        }
        .task(id: viewModel.draftID) { await viewModel.countDraftResults() }   // "Apply (n results)" follows the draft
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                header(FiltersText.budget)
                Spacer()
                Text(verbatim: viewModel.draftBudgetText)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            budgetSlider(FiltersText.budgetMinimum, value: viewModel.draftBudgetLower) {
                viewModel.setDraftBudget(lower: $0, upper: viewModel.draftBudgetUpper)
            }
            budgetSlider(FiltersText.budgetMaximum, value: viewModel.draftBudgetUpper) {
                viewModel.setDraftBudget(lower: viewModel.draftBudgetLower, upper: $0)
            }
        }
    }

    private func budgetSlider(_ label: String, value: Int, onChange: @escaping (Int) -> Void) -> some View {
        Slider(value: Binding(get: { Double(value) }, set: { onChange(Int($0)) }),
               in: Double(BudgetRange.lowest)...Double(BudgetRange.highest), step: Double(BudgetRange.step))
            .tint(Theme.Color.accent)
            .accessibilityLabel(Text(verbatim: label))
            .accessibilityValue(Text(verbatim: viewModel.draftBudgetText))
    }

    private var timeSection: some View {
        chipSection(FiltersText.time) {
            ForEach(TimeChoice.allCases, id: \.self) { time in
                FilterChip(verbatim: time.title, isSelected: viewModel.draftTime == time) {
                    viewModel.setDraftTime(time)
                }
            }
        }
    }

    private var findYourVybeButton: some View {
        Button { showsVybePage = true } label: {
            HStack {
                Label(FiltersText.findYourVybe, systemImage: "sparkles")
                    .font(Theme.Font.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Theme.Size.minTapTarget)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("discover.filters.findYourVybe")
    }

    private func chipSection(_ title: String, @ViewBuilder chips: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            header(title)
            FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) { chips() }
        }
    }

    private func header(_ title: String) -> some View {
        Text(verbatim: title)
            .font(Theme.Font.headline)
            .foregroundStyle(Theme.Color.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// "Apply (12 results)" pinned to the bottom of the sheet; shared by both pages.
struct ApplyBar: View {
    let viewModel: DiscoverMapViewModel

    var body: some View {
        PrimaryButton(verbatim: title) { Task { await viewModel.applyFilters() } }
            .padding(Theme.Spacing.large)
            .background(.bar)
            .accessibilityIdentifier("discover.filters.apply")
    }

    private var title: String {
        viewModel.draftResultCount.map(FiltersText.apply) ?? FiltersText.applyCounting
    }
}
