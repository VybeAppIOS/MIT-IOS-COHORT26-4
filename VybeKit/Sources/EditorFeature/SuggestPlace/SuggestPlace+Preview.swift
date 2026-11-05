#if DEBUG
import Core
import Models
import SwiftUI

extension SuggestPlaceViewModel {
    /// The real ViewModel on the stubs; `failing` makes the send fail.
    static func preview(failing: Bool = false) -> SuggestPlaceViewModel {
        let deps = AppDependencies.preview()
        return SuggestPlaceViewModel(
            presentation: .sheet, session: deps.session, router: deps.router,
            submit: { _ in if failing { throw AppError.offline } }, now: { SampleData.day }, makeID: { "preview" })
    }
}

#Preview("Form") { NavigationStack { SuggestPlaceView(viewModel: .preview()) } }
#Preview("Large text") {
    NavigationStack { SuggestPlaceView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
