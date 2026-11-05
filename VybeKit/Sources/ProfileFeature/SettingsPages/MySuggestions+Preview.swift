#if DEBUG
import Core
import Models
import SwiftUI

extension MySuggestionsViewModel {
    /// The real ViewModel on the stubs. `asSubmitter` signs in as a sample person who has suggestions, so the list
    /// is not empty (the sample "me" has suggested nothing yet).
    static func preview(_ mode: StubMode = .loaded, asSubmitter: Bool = true) -> MySuggestionsViewModel {
        let deps = AppDependencies.preview(mode)
        if asSubmitter { deps.session.setCurrentUser(SampleData.friend) }
        return MySuggestionsViewModel(admin: deps.admin, session: deps.session)
    }
}

#Preview("Loaded") { NavigationStack { MySuggestionsView(viewModel: .preview()) } }
#Preview("Empty") { NavigationStack { MySuggestionsView(viewModel: .preview(asSubmitter: false)) } }
#Preview("Error") { NavigationStack { MySuggestionsView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { MySuggestionsView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { MySuggestionsView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
