#if DEBUG
import Core
import Design
import Models
import SwiftUI

/// The bar under a plain tab view, with or without a live run of the EXAMPLE Evening Hangout.
private struct MiniBarPreview: View {
    let live: Bool
    @State private var viewModel: MiniBarViewModel?

    var body: some View {
        Group {
            if let viewModel {
                TabView {
                    Tab("Discover", systemImage: "map") { Theme.Color.surface }
                    Tab("Profile", systemImage: "person.crop.circle") { Theme.Color.surface }
                }
                .modifier(MiniBarAccessory(viewModel: viewModel))
            } else {
                ProgressView()
            }
        }
        .task {
            let deps = AppDependencies.preview()
            if live { _ = try? await deps.liveStore.startOrResume(hangoutID: SampleData.evening.id) }
            viewModel = MiniBarViewModel(hangouts: deps.hangouts, places: deps.places, liveStore: deps.liveStore,
                                         router: deps.router)
        }
    }
}

#Preview("With a live run") { MiniBarPreview(live: true) }
#Preview("Without a live run") { MiniBarPreview(live: false) }
#Preview("Large text") { MiniBarPreview(live: true).dynamicTypeSize(.accessibility3) }
#endif
