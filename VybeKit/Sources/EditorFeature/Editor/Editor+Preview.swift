#if DEBUG
import Core
import Models
import SwiftUI

extension EditorViewModel {
    /// The real ViewModel on the stubs.
    static func preview(_ start: EditorStart = .new, _ mode: StubMode = .loaded) -> EditorViewModel {
        let deps = AppDependencies.preview(mode)
        return EditorViewModel(start: start, hangouts: deps.hangouts, places: deps.places, profiles: deps.profiles,
                               photos: deps.photos, libraryStore: deps.libraryStore, session: deps.session,
                               router: deps.router, now: { SampleData.day }, makeID: { "preview" })
    }
}

#Preview("New Hangout") { NavigationStack { EditorView(viewModel: .preview()) } }
#Preview("Remix of the EXAMPLE evening") {
    NavigationStack { EditorView(viewModel: .preview(.remix(SampleData.evening.id))) }
}
#Preview("Draft not found") { NavigationStack { EditorView(viewModel: .preview(.draft("missing"))) } }
#Preview("Loading") {
    NavigationStack { EditorView(viewModel: .preview(.remix(SampleData.evening.id), .neverReturns)) }
}
#Preview("Large text") {
    NavigationStack { EditorView(viewModel: .preview(.remix(SampleData.evening.id))) }
        .dynamicTypeSize(.accessibility3)
}
#endif
