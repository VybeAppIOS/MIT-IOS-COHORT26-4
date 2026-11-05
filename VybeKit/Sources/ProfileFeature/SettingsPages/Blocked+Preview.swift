#if DEBUG
import Core
import Models
import SwiftUI

extension BlockedViewModel {
    /// The real ViewModel on the stubs.
    static func preview(_ deps: AppDependencies) -> BlockedViewModel {
        BlockedViewModel(safety: deps.safety, session: deps.session, photos: deps.photos, network: deps.network)
    }
}

/// Blocks `blocking` through the real stub first, then shows the page.
private struct BlockedPreviewHost: View {
    var mode: StubMode = .loaded
    var blocking: [UserID] = [SampleSocialData.kabir.id]
    @State private var viewModel: BlockedViewModel?

    var body: some View {
        NavigationStack {
            if let viewModel { BlockedView(viewModel: viewModel) } else { ProgressView() }
        }
        .task {
            let deps = AppDependencies.preview(mode)
            for id in blocking { try? await deps.safety.block(id) }
            viewModel = .preview(deps)
        }
    }
}

#Preview("Loaded") { BlockedPreviewHost() }
#Preview("Empty") { BlockedPreviewHost(blocking: []) }
#Preview("Error") { BlockedPreviewHost(mode: .failing) }
#Preview("Large text") { BlockedPreviewHost().dynamicTypeSize(.accessibility3) }
#endif
