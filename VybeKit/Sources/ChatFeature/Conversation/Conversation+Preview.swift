#if DEBUG
import Core
import Models
import SwiftUI

/// A recorder that does nothing, for previews.
private struct PreviewRecorder: VoiceRecording {
    func start() async throws {}
    func stop() async throws -> VoiceNote { VoiceNote(url: URL.temporaryDirectory, seconds: 3, hitLimit: false) }
    func cancel() async {}
}

extension ConversationViewModel {
    /// The real ViewModel on the stub repositories, in one state, for one of the sample chats.
    static func preview(
        _ mode: StubMode, chat id: ConversationID = SampleSocialData.crew.id, offline: Bool = false
    ) -> ConversationViewModel {
        let deps = AppDependencies.preview(mode)
        return ConversationViewModel(
            conversationID: id, chat: deps.chat, profiles: deps.profiles, hangouts: deps.hangouts,
            photos: deps.photos, libraryStore: deps.libraryStore, session: deps.session, badges: deps.badges,
            network: NetworkMonitor(isOffline: offline), router: deps.router, now: deps.now,
            recorder: PreviewRecorder(), player: AudioPlayer(),
            makePoll: { id, onClose in
                PollViewModel(conversationID: id, chat: deps.chat, network: deps.network, onClose: onClose)
            })
    }
}

#Preview("A group chat") { NavigationStack { ConversationView(viewModel: .preview(.loaded)) } }
#Preview("A direct message") {
    NavigationStack { ConversationView(viewModel: .preview(.loaded, chat: SampleSocialData.friendChat.id)) }
}
#Preview("Offline") { NavigationStack { ConversationView(viewModel: .preview(.loaded, offline: true)) } }
#Preview("Empty") { NavigationStack { ConversationView(viewModel: .preview(.empty)) } }
#Preview("Error") { NavigationStack { ConversationView(viewModel: .preview(.failing)) } }
#Preview("Loading") { NavigationStack { ConversationView(viewModel: .preview(.neverReturns)) } }
#Preview("Large text") {
    NavigationStack { ConversationView(viewModel: .preview(.loaded)) }
        .dynamicTypeSize(.accessibility3)
}
#endif
