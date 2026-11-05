import Design
import SwiftUI

/// Layout only: every value comes from `LocationViewModel`, every tap goes to it. It also tells the ViewModel when the
/// app goes inactive and active again, which is how the system permission prompt's answer is noticed.
struct LocationView: View {
    @State private var viewModel: LocationViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: LocationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.step {
            case .explain, .waitingForAnswer: explain
            case .pickArea(let couldNotAsk): pickArea(couldNotAsk: couldNotAsk)
            }
        }
        .background(Theme.Color.surface)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadAreas() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .inactive: viewModel.appBecameInactive()
            case .active: viewModel.appBecameActive()
            default: break
            }
        }
    }

    // MARK: Step 1: explain, then ask

    private var explain: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                Image(systemName: "location.circle.fill")
                    .font(Theme.Font.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(Theme.Color.accent)
                    .accessibilityHidden(true)
                Text(verbatim: LocationText.title)
                    .font(Theme.Font.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: LocationText.why)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.large)
            .padding(.top, Theme.Spacing.huge)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.Spacing.small) {
                PrimaryButton(verbatim: LocationText.allow, isLoading: viewModel.step == .waitingForAnswer) {
                    Task { await viewModel.allowTapped() }
                }
                .accessibilityIdentifier("onboarding.location.allow")
                Button(LocationText.notNow) { viewModel.notNowTapped() }
                    .font(Theme.Font.body)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .accessibilityIdentifier("onboarding.location.notNow")
            }
            .padding(Theme.Spacing.large)
        }
    }

    // MARK: Step 2: pick an area

    private func pickArea(couldNotAsk: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(verbatim: LocationText.pickTitle)
                        .font(Theme.Font.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: couldNotAsk ? LocationText.couldNotAsk : LocationText.pickWhy)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                    ForEach(viewModel.areas) { area in
                        FilterChip(verbatim: area.name, isSelected: viewModel.selectedAreaID == area.id) {
                            viewModel.selectArea(area.id)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(verbatim: LocationText.done) { viewModel.doneTapped() }
                .padding(Theme.Spacing.large)
                .accessibilityIdentifier("onboarding.location.done")
        }
    }
}
