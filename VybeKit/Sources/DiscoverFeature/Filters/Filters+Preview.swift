#if DEBUG
import Core
import SwiftUI

/// The Discover ViewModel on the stubs with the filters sheet open (its draft copied), optionally with some choices.
@MainActor
private func openSheet(choosing interests: [VybeInterest] = []) -> DiscoverMapViewModel {
    let viewModel = DiscoverMapViewModel.preview()
    viewModel.moreFiltersTapped()
    interests.forEach(viewModel.toggleInterest)
    return viewModel
}

#Preview("Filters") { FiltersSheetView(viewModel: openSheet()) }

#Preview("Filters, with choices") {
    FiltersSheetView(viewModel: openSheet(choosing: [.cafe, .parks, .rooftop]))
}

#Preview("Find your Vybe") {
    NavigationStack { VybeInterestsView(viewModel: openSheet(choosing: [.chai, .trek, .gigs, .thrifting])) }
}

#Preview("Find your Vybe, large text") {
    NavigationStack { VybeInterestsView(viewModel: openSheet()) }
        .dynamicTypeSize(.accessibility3)
}

#Preview("Filters, large text") {
    FiltersSheetView(viewModel: openSheet()).dynamicTypeSize(.accessibility3)
}
#endif
