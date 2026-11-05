#if DEBUG
import Core
import SwiftUI

extension InterestsViewModel {
    /// The real ViewModel on a throwaway session, with these interests already chosen.
    static func preview(choosing interests: [InterestOption] = []) -> InterestsViewModel {
        let deps = AppDependencies.preview()
        deps.session.onboardingDraft.interests = interests.map(\.rawValue)
        return InterestsViewModel(session: deps.session, router: deps.router)
    }
}

private func screen(_ viewModel: InterestsViewModel) -> some View {
    NavigationStack { InterestsView(viewModel: viewModel) }
}

#Preview("None chosen") { screen(.preview()) }
#Preview("Two chosen") { screen(.preview(choosing: [.cafes, .treks])) }
#Preview("Enough chosen") { screen(.preview(choosing: [.cafes, .treks, .sunsets, .budgetEats])) }
#Preview("Large text") { screen(.preview(choosing: [.cafes])).dynamicTypeSize(.accessibility3) }
#endif
