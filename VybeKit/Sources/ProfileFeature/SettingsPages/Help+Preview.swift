#if DEBUG
import Core
import SwiftUI

extension HelpViewModel {
    static func preview() -> HelpViewModel { HelpViewModel(router: AppDependencies.preview().router) }
}

#Preview("Help") { NavigationStack { HelpView(viewModel: .preview()) } }
#Preview("Large text") {
    NavigationStack { HelpView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
