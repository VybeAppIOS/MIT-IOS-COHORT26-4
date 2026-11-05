#if DEBUG
import Core
import Models
import SwiftUI

/// Builds a real ended run of the EXAMPLE Evening Hangout (with `visited` Spots and `photoCount` photos), then the
/// screen for it. The run is made through the live store, exactly as the app does.
private struct SummaryPreview: View {
    let visited: Int
    let photoCount: Int
    @State private var viewModel: SummaryViewModel?

    var body: some View {
        NavigationStack {
            if let viewModel { SummaryView(viewModel: viewModel) } else { ProgressView() }
        }
        .task {
            let deps = AppDependencies.preview()
            guard let run = try? await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id) else { return }
            for spot in SampleData.evening.spots.prefix(visited) { deps.liveStore.markVisited(spotID: spot.id) }
            for index in 0..<photoCount {
                deps.liveStore.addPhoto(Photo(id: PhotoID("photo-example-\(index)"), path: "EXAMPLE-\(index).jpg",
                                              width: 400, height: 400))
            }
            deps.liveStore.end()
            viewModel = SummaryViewModel(runID: run.id, library: deps.libraryStore, places: deps.places,
                                         photos: deps.photos, router: deps.router)
        }
    }
}

#Preview("No photos") { SummaryPreview(visited: 2, photoCount: 0) }
#Preview("8 photos") { SummaryPreview(visited: 2, photoCount: 8) }
#Preview("1 visited: Post disabled") { SummaryPreview(visited: 1, photoCount: 1) }
#Preview("Large text") { SummaryPreview(visited: 2, photoCount: 3).dynamicTypeSize(.accessibility3) }
#endif
