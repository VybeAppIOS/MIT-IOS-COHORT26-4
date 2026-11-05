#if DEBUG
import Core
import SwiftUI

extension AboutViewModel {
    static func preview(_ mode: StubMode = .loaded) -> AboutViewModel {
        let deps = AppDependencies.preview(mode)
        return AboutViewModel(hangouts: deps.hangouts, places: deps.places, version: "1.0 (1)")
    }
}

#Preview("Loaded") { NavigationStack { AboutView(viewModel: .preview()) } }
#Preview("No credits") { NavigationStack { AboutView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { AboutView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { AboutView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { AboutView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
