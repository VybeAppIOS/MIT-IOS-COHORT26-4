#if DEBUG
import Core
import SwiftUI

extension WelcomeViewModel {
    /// The real ViewModel on a fresh router. Welcome loads no data, so it has one state.
    static func preview() -> WelcomeViewModel {
        WelcomeViewModel(router: Router())
    }
}

#Preview("Welcome") { NavigationStack { WelcomeView(viewModel: .preview()) } }
#Preview("Small screen", traits: .fixedLayout(width: 320, height: 568)) {
    NavigationStack { WelcomeView(viewModel: .preview()) }
}
#Preview("Large text") {
    NavigationStack { WelcomeView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#Preview("Large text, small screen", traits: .fixedLayout(width: 320, height: 568)) {
    NavigationStack { WelcomeView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
