#if DEBUG
import Core
import Models
import SwiftUI

extension ComposerViewModel {
    /// The real ViewModel on the stubs for a run that is not in the library (the error state).
    static func previewMissing() -> ComposerViewModel {
        let deps = AppDependencies.preview(.loaded)
        return ComposerViewModel(runID: RunID("run-missing"), libraryStore: deps.libraryStore, session: deps.session,
                                 photos: deps.photos, router: deps.router, now: { SampleData.day })
    }
}

/// Finishes a run with `visited` Spots, then shows the composer for it.
private struct ComposerPreviewHost: View {
    let visited: Int
    @State private var viewModel: ComposerViewModel?

    var body: some View {
        NavigationStack {
            if let viewModel { ComposerView(viewModel: viewModel) } else { ProgressView() }
        }
        .task {
            let deps = AppDependencies.preview(.loaded)
            guard let run = try? await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id) else { return }
            for spot in SampleData.evening.spots.prefix(visited) { deps.liveStore.markVisited(spotID: spot.id) }
            deps.liveStore.end()
            viewModel = ComposerViewModel(runID: run.id, libraryStore: deps.libraryStore, session: deps.session,
                                          photos: deps.photos, router: deps.router, now: { SampleData.day })
        }
    }
}

#Preview("Ready") { ComposerPreviewHost(visited: 2) }
#Preview("Below 2 Spots") { ComposerPreviewHost(visited: 1) }
#Preview("Error") {
    NavigationStack { ComposerView(viewModel: .previewMissing()) }
}
#Preview("Large text") {
    ComposerPreviewHost(visited: 2).dynamicTypeSize(.accessibility3)
}
#endif
