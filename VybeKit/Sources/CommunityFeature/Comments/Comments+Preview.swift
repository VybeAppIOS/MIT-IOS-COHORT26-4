#if DEBUG
import Core
import Foundation
import Models
import SwiftUI

extension CommentsViewModel {
    /// The real ViewModel on the stub repositories, in one state. Post 1 has a thread of three comments and a reply.
    static func preview(
        _ mode: StubMode, run: RunID = SampleSocialData.posts[0].id, offline: Bool = false
    ) -> CommentsViewModel {
        let deps = AppDependencies.preview(mode)
        return CommentsViewModel(
            runID: run, feed: deps.feed, profiles: deps.profiles, session: deps.session,
            network: NetworkMonitor(isOffline: offline), now: deps.now, makeID: { UUID().uuidString },
            onExit: { _ in })
    }

    /// For the Feed and Post detail previews and tests.
    static func previewFactory(_ deps: AppDependencies) -> CommentsFactory {
        { runID, onExit in
            CommentsViewModel(
                runID: runID, feed: deps.feed, profiles: deps.profiles, session: deps.session,
                network: deps.network, now: deps.now, makeID: { UUID().uuidString }, onExit: onExit)
        }
    }
}

#Preview("Loaded") { CommentsView(viewModel: .preview(.loaded)) }
#Preview("Empty") { CommentsView(viewModel: .preview(.loaded, run: SampleSocialData.posts[1].id)) }
#Preview("Error") { CommentsView(viewModel: .preview(.failing)) }
#Preview("Loading") { CommentsView(viewModel: .preview(.neverReturns)) }
#Preview("Offline") { CommentsView(viewModel: .preview(.loaded, offline: true)) }
#Preview("Large text") {
    CommentsView(viewModel: .preview(.loaded)).dynamicTypeSize(.accessibility3)
}
#endif
