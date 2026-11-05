#if DEBUG
import Core
import Models
import SwiftUI

extension EditPostViewModel {
    /// The real ViewModel on the stubs for a post that is not in the library (the error state).
    static func previewMissing() -> EditPostViewModel {
        let deps = AppDependencies.preview(.loaded)
        return EditPostViewModel(runID: RunID("run-missing"), libraryStore: deps.libraryStore, places: deps.places,
                                 photos: deps.photos, session: deps.session, router: deps.router)
    }
}

/// Finishes and schedules a run of the EXAMPLE evening Hangout, then edits it.
private struct EditPostPreviewHost: View {
    @State private var viewModel: EditPostViewModel?

    var body: some View {
        NavigationStack {
            if let viewModel { EditPostView(viewModel: viewModel) } else { ProgressView() }
        }
        .task {
            let deps = AppDependencies.preview(.loaded)
            let hangoutID = SampleData.evening.id
            guard let started = try? await deps.liveStore.startOrResume(hangoutID: hangoutID) else { return }
            for spot in SampleData.evening.spots { deps.liveStore.markVisited(spotID: spot.id) }
            deps.liveStore.end()
            guard var run = deps.libraryStore.library.runs.first(where: { $0.id == started.id }) else { return }
            run.state = .scheduled
            run.caption = "EXAMPLE caption"
            deps.libraryStore.updateRun(run, times: deps.libraryStore.library.runTimes[run.id])
            viewModel = EditPostViewModel(runID: run.id, libraryStore: deps.libraryStore, places: deps.places,
                                          photos: deps.photos, session: deps.session, router: deps.router)
        }
    }
}

#Preview("Loaded") { EditPostPreviewHost() }
#Preview("Error") { NavigationStack { EditPostView(viewModel: .previewMissing()) } }
#Preview("Large text") { EditPostPreviewHost().dynamicTypeSize(.accessibility3) }
#endif
