#if DEBUG
import Core
import Models
import SwiftUI

extension ReadyToPostViewModel {
    /// The real ViewModel on the stubs. With `runs`, the library first gets one finished run with both EXAMPLE Spots
    /// visited and one with a single Spot (so Post is off), built through the real live store.
    static func preview(_ mode: StubMode = .loaded, runs: Bool = true) -> ReadyToPostViewModel {
        let deps = AppDependencies.preview(mode)
        if runs {
            Task {
                _ = try? await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id)
                deps.liveStore.markVisited(spotID: "s1")
                deps.liveStore.markVisited(spotID: "s2")
                deps.liveStore.end()
                _ = try? await deps.liveStore.startOrResume(hangoutID: SampleData.morning.id)
                deps.liveStore.markVisited(spotID: "s1")
                deps.liveStore.end()
            }
        }
        return ReadyToPostViewModel(libraryStore: deps.libraryStore, router: deps.router)
    }
}

#Preview("Loaded") { NavigationStack { ReadyToPostView(viewModel: .preview()) } }
#Preview("Empty") { NavigationStack { ReadyToPostView(viewModel: .preview(runs: false)) } }
#Preview("Error") { NavigationStack { ReadyToPostView(viewModel: .preview(.failing, runs: false)) } }
#Preview("Loading") { NavigationStack { ReadyToPostView(viewModel: .preview(.neverReturns, runs: false)) } }
#Preview("Large text") {
    NavigationStack { ReadyToPostView(viewModel: .preview()) }
        .dynamicTypeSize(.accessibility3)
}
#endif
