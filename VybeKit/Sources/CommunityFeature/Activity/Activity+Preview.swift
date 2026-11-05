#if DEBUG
import Core
import SwiftUI

extension ActivityViewModel {
    /// The real ViewModel on the stub repositories, in one state.
    static func preview(_ mode: StubMode) -> ActivityViewModel {
        let deps = AppDependencies.preview(mode)
        return ActivityViewModel(
            feed: deps.feed, friends: deps.friends, profiles: deps.profiles, badges: deps.badges,
            router: deps.router, now: deps.now)
    }
}

#Preview("Loaded") { NavigationStack { ActivityView(viewModel: .preview(.loaded)) } }
#Preview("Empty") { NavigationStack { ActivityView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { ActivityView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { ActivityView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { ActivityView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
