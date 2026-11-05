import Components
import Core
import Foundation
import Models
import Synchronization
@testable import ChatFeature

/// A recorder the test controls. Its state sits behind a lock, so it is safe to share.
final class FakeRecorder: VoiceRecording {
    private struct State {
        var failToStart = false
        var note = VoiceNote(
            url: URL.temporaryDirectory.appending(path: "voice/test-note.m4a"), seconds: 7, hitLimit: false)
        var started = 0
        var cancelled = 0
    }

    private let state = Mutex(State())
    var started: Int { state.withLock { $0.started } }
    var cancelled: Int { state.withLock { $0.cancelled } }
    var note: VoiceNote {
        get { state.withLock { $0.note } }
        set { state.withLock { $0.note = newValue } }
    }
    var failToStart: Bool {
        get { state.withLock { $0.failToStart } }
        set { state.withLock { $0.failToStart = newValue } }
    }

    func start() async throws {
        if failToStart { throw AudioRecorderError.permissionDenied }
        state.withLock { $0.started += 1 }
    }
    func stop() async throws -> VoiceNote { note }
    func cancel() async { state.withLock { $0.cancelled += 1 } }
}

/// Helpers shared by the Conversation tests.
@MainActor
struct ConversationKit {
    let crew = SampleSocialData.crew.id
    let direct = SampleSocialData.friendChat.id

    func makeViewModel(
        _ id: ConversationID? = nil, chat: (any ChatRepository)? = nil, deps: AppDependencies = .preview(.loaded),
        recorder: FakeRecorder = FakeRecorder(), offline: Bool = false, session: SessionStore? = nil,
        photos: (any PhotoStore)? = nil,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) -> ConversationViewModel {
        ConversationViewModel(
            conversationID: id ?? crew, chat: chat ?? deps.chat, profiles: deps.profiles, hangouts: deps.hangouts,
            photos: photos ?? deps.photos,
            libraryStore: deps.libraryStore, session: session ?? deps.session, badges: deps.badges,
            network: NetworkMonitor(isOffline: offline), router: deps.router, now: { SampleData.day },
            recorder: recorder, player: AudioPlayer(),
            makePoll: { chatID, onClose in
                PollViewModel(conversationID: chatID, chat: deps.chat, network: deps.network, onClose: onClose)
            }, sleep: sleep)
    }

    func rows(_ viewModel: ConversationViewModel) -> [MessageRowData] {
        if case .loaded(let content, _) = viewModel.state { content.rows } else { [] }
    }

    /// Loads the chat and waits until the first batch of messages has arrived.
    func open(_ viewModel: ConversationViewModel) async -> Task<Void, Never> {
        let task = Task { await viewModel.run() }
        for _ in 0..<200 where rows(viewModel).isEmpty { try? await Task.sleep(for: .milliseconds(10)) }
        return task
    }

    func message(
        _ number: Int, from sender: UserID, at seconds: TimeInterval, _ payload: MessagePayload = .text("hi")
    ) -> Message {
        Message(
            id: MessageID("m-\(number)"), conversationID: SampleSocialData.crew.id, senderID: sender,
            createdAt: SampleData.day.addingTimeInterval(seconds), payload: payload)
    }

    var myID: UserID { SampleData.signedInUser.id }
    var ishaID: UserID { SampleSocialData.isha.id }
}

/// A stand-in for the 2 minute wait: it stays asleep until the test opens the gate, and remembers how long it was
/// asked to wait. Cancelling the wait ends it (like the real sleep).
final class CapGate: Sendable {
    private let state = Mutex((isOpen: false, asked: Duration?.none))
    var asked: Duration? { state.withLock { $0.asked } }
    func open() { state.withLock { $0.isOpen = true } }
    var sleep: @Sendable (Duration) async throws -> Void {
        { [self] duration in
            state.withLock { $0.asked = duration }
            while !state.withLock({ $0.isOpen }) { try await Task.sleep(for: .milliseconds(5)) }
        }
    }
}
