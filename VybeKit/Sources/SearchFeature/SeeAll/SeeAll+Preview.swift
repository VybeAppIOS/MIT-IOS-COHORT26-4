#if DEBUG
import Core
import Models
import SwiftUI

extension SeeAllViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode, kind: SearchKind = .hangouts) -> SeeAllViewModel {
        let deps = AppDependencies.preview(mode)
        return SeeAllViewModel(
            kind: kind, hangouts: deps.hangouts, places: deps.places, friends: deps.friends, session: deps.session,
            router: deps.router)
    }
}

#Preview("Hangouts") { NavigationStack { SeeAllView(viewModel: .preview(.loaded)) } }
#Preview("Places") { NavigationStack { SeeAllView(viewModel: .preview(.loaded, kind: .places)) } }
#Preview("People") { NavigationStack { SeeAllView(viewModel: .preview(.loaded, kind: .people)) } }
#Preview("Empty") { NavigationStack { SeeAllView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { SeeAllView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { SeeAllView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { SeeAllView(viewModel: .preview(.loaded, kind: .people)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
