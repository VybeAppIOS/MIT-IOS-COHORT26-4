import Components
import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct ConversationVoiceAndRulesTests {
    private let kit = ConversationKit()
    private var crew: ConversationID { kit.crew }
    private var direct: ConversationID { kit.direct }
    private func makeViewModel(
        _ id: ConversationID? = nil, chat: (any ChatRepository)? = nil, deps: AppDependencies = .preview(.loaded),
        recorder: FakeRecorder = FakeRecorder(), offline: Bool = false, session: SessionStore? = nil
    ) -> ConversationViewModel {
        kit.makeViewModel(id, chat: chat, deps: deps, recorder: recorder, offline: offline, session: session)
    }
    private func rows(_ viewModel: ConversationViewModel) -> [MessageRowData] { kit.rows(viewModel) }
    private func open(_ viewModel: ConversationViewModel) async -> Task<Void, Never> { await kit.open(viewModel) }
    private func message(
        _ number: Int, from sender: UserID, at seconds: TimeInterval, _ payload: MessagePayload = .text("hi")
    ) -> Message { kit.message(number, from: sender, at: seconds, payload) }

    // MARK: Polls

    @Test func aPollCanBeStartedInAGroupButNotInADirectMessage() async {
        let group = makeViewModel(crew)
        let groupTask = await open(group)
        #expect(group.canStartPoll)
        group.pollTapped()
        #expect(group.isShowingPoll)
        groupTask.cancel()

        let privateChat = makeViewModel(direct)
        let privateTask = await open(privateChat)
        #expect(!privateChat.canStartPoll)
        privateChat.pollTapped()
        #expect(!privateChat.isShowingPoll)
        privateTask.cancel()
    }

    @Test func votingChangesTheCounts() async {
        let viewModel = makeViewModel(crew)
        let task = await open(viewModel)
        guard let poll = rows(viewModel).first(where: { if case .poll = $0.content { true } else { false } }) else {
            Issue.record("no poll in the sample chat"); task.cancel(); return
        }
        await viewModel.vote(.imIn, on: poll.id)
        let updated = rows(viewModel).first(where: { $0.id == poll.id })
        guard let updated, case .poll(let data) = updated.content else {
            Issue.record("poll vanished"); task.cancel(); return
        }
        #expect(data.myVote == .imIn && data.imInCount >= 1)
        task.cancel()
    }

    @Test func aHangoutCardOpensTheHangout() {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        viewModel.openHangout(SampleData.evening.id)
        #expect(deps.router.path(for: deps.router.currentStack).last == .hangout(SampleData.evening.id))
    }

    // MARK: Voice notes

    @Test func aVoiceNoteIsRecordedThenSentWithItsLength() async {
        let recorder = FakeRecorder()
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let viewModel = makeViewModel(chat: controlled, recorder: recorder)
        let task = await open(viewModel)
        await viewModel.micTapped()
        #expect(viewModel.isRecording && recorder.started == 1)
        await viewModel.micTapped()
        #expect(!viewModel.isRecording)
        #expect(controlled.sent.withLock { $0.last?.1 } == .voice(path: "voice/test-note.m4a", seconds: 7))
        task.cancel()
    }

    @Test func theTwoMinuteLimitIsMentioned() async {
        let recorder = FakeRecorder()
        recorder.note = VoiceNote(url: recorder.note.url, seconds: 120, hitLimit: true)
        let viewModel = makeViewModel(recorder: recorder)
        let task = await open(viewModel)
        await viewModel.micTapped()
        await viewModel.micTapped()
        #expect(viewModel.notice != nil)
        task.cancel()
    }

    @Test func noMicrophoneAccessSaysSoAndDoesNotRecord() async {
        let recorder = FakeRecorder()
        recorder.failToStart = true
        let viewModel = makeViewModel(recorder: recorder)
        await viewModel.micTapped()
        #expect(!viewModel.isRecording && viewModel.notice != nil)
    }

    @Test func discardingARecordingSendsNothing() async {
        let recorder = FakeRecorder()
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let viewModel = makeViewModel(chat: controlled, recorder: recorder)
        await viewModel.micTapped()
        await viewModel.cancelRecording()
        #expect(!viewModel.isRecording && recorder.cancelled == 1 && controlled.sent.withLock { $0.isEmpty })
    }

    // MARK: Rules for writing, header

    @Test func offlineStopsWritingAndAGroupBelowThreeIsReadOnly() async throws {
        let offline = makeViewModel(offline: true)
        let offlineTask = await open(offline)
        offline.draft = "Hello"
        #expect(!offline.canWrite && !offline.canSendDraft)
        offlineTask.cancel()

        let deps = AppDependencies.preview(.loaded)
        let others = SampleSocialData.crew.memberIDs.filter { $0 != SampleData.signedInUser.id }
        for id in others.dropFirst() { try await deps.chat.remove(id, from: crew) }
        let small = makeViewModel(deps: deps)
        let smallTask = await open(small)
        #expect(!small.canWrite)
        smallTask.cancel()
    }

    @Test func aMutedPersonCanReadButTheComposerIsOff() async {
        let muted = ControlledChat(base: StubChatRepository(store: SocialStubStore(mutedIn: [crew])))
        let viewModel = makeViewModel(chat: muted)
        let task = await open(viewModel)
        #expect(!rows(viewModel).isEmpty)   // reading still works
        if case .loaded(let content, _) = viewModel.state { #expect(content.isMuted) }
        viewModel.draft = "Hello"
        #expect(!viewModel.canWrite && !viewModel.canSendDraft)
        viewModel.pollTapped()
        #expect(!viewModel.isShowingPoll)
        await viewModel.sendTapped()
        #expect(muted.sent.withLock { $0.isEmpty })
        #expect(!viewModel.mutedNote.isEmpty)
        task.cancel()
    }

    @Test func aMemberWhoIsNotMutedCanWriteAndADirectMessageIsNeverMuted() async {
        let group = makeViewModel()
        let groupTask = await open(group)
        if case .loaded(let content, _) = group.state { #expect(!content.isMuted) }
        #expect(group.canWrite)
        groupTask.cancel()

        let privateChat = makeViewModel(direct)
        let privateTask = await open(privateChat)
        #expect(!privateChat.isMuted && privateChat.canWrite)
        privateTask.cancel()
    }

    @Test func theHeaderOpensGroupInfoForAGroupAndTheProfileForADirectMessage() async {
        let deps = AppDependencies.preview(.loaded)
        let group = makeViewModel(crew, deps: deps)
        let groupTask = await open(group)
        group.headerTapped()
        #expect(deps.router.path(for: deps.router.currentStack).last == .groupInfo(crew))
        groupTask.cancel()

        let privateChat = makeViewModel(direct, deps: deps)
        let privateTask = await open(privateChat)
        privateChat.headerTapped()
        #expect(deps.router.path(for: deps.router.currentStack).last == .profile(SampleSocialData.friend.id))
        privateTask.cancel()
    }
}
