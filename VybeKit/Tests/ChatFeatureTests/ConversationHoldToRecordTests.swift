import Components
import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

/// Voice notes: hold to record, let go to send, slide left to cancel, 2 minute cap, and the VoiceOver path.
/// Always the fake recorder: nothing here touches the microphone.
@MainActor
struct ConversationHoldToRecordTests {
    private let kit = ConversationKit()

    private struct Rig {
        let viewModel: ConversationViewModel
        let recorder: FakeRecorder
        let chat: ControlledChat
        let gate: CapGate
        var sentVoice: Int {
            chat.sent.withLock { $0.filter { if case .voice = $0.1 { true } else { false } }.count }
        }
    }

    private func makeRig(offline: Bool = false, failToStart: Bool = false, seconds: Int = 7) -> Rig {
        let recorder = FakeRecorder()
        recorder.failToStart = failToStart
        recorder.note = VoiceNote(url: recorder.note.url, seconds: seconds, hitLimit: false)
        let chat = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        let gate = CapGate()
        let viewModel = kit.makeViewModel(chat: chat, recorder: recorder, offline: offline, sleep: gate.sleep)
        return Rig(viewModel: viewModel, recorder: recorder, chat: chat, gate: gate)
    }

    /// Finger down, and wait until the recorder has started.
    private func press(_ rig: Rig) async {
        rig.viewModel.micPressed()
        await rig.viewModel.startTask?.value
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() { try? await Task.sleep(for: .milliseconds(10)) }
    }

    // MARK: Hold, release, slide

    @Test func holdingStartsRecordingAndLettingGoSendsTheVoiceNote() async {
        let rig = makeRig()
        await press(rig)
        #expect(rig.viewModel.isHolding && rig.viewModel.isRecording && rig.recorder.started == 1)
        #expect(rig.sentVoice == 0)
        await rig.viewModel.micReleased()
        #expect(!rig.viewModel.isRecording && !rig.viewModel.isHolding)
        #expect(rig.chat.sent.withLock { $0.last?.1 } == .voice(path: "voice/test-note.m4a", seconds: 7))
    }

    @Test func lettingGoRightAwaySendsOnceTheRecorderHasStarted() async {
        let rig = makeRig()
        rig.viewModel.micPressed()
        await rig.viewModel.micReleased()   // released before the start finished
        #expect(rig.recorder.started == 1 && rig.sentVoice == 1 && !rig.viewModel.isRecording)
    }

    @Test func aSecondPressWhileHoldingDoesNotStartAgain() async {
        let rig = makeRig()
        await press(rig)
        rig.viewModel.micPressed()
        await rig.viewModel.startTask?.value
        #expect(rig.recorder.started == 1)
        await rig.viewModel.micReleased()
        #expect(rig.sentVoice == 1)
    }

    @Test func slidingFarEnoughLeftAndLettingGoCancels() async {
        let rig = makeRig()
        await press(rig)
        rig.viewModel.micDragged(-(ConversationViewModel.slideToCancelDistance + 1))
        #expect(rig.viewModel.willCancel)
        await rig.viewModel.micReleased()
        #expect(!rig.viewModel.isRecording && !rig.viewModel.isHolding && rig.viewModel.slideOffset == 0)
        #expect(rig.recorder.cancelled == 1 && rig.sentVoice == 0)
    }

    @Test func aShortSlideStillSendsAndSlidingBackUndoesTheCancel() async {
        let rig = makeRig()
        await press(rig)
        rig.viewModel.micDragged(-(ConversationViewModel.slideToCancelDistance - 1))
        #expect(!rig.viewModel.willCancel)
        rig.viewModel.micDragged(-500)
        #expect(rig.viewModel.willCancel)
        rig.viewModel.micDragged(-10)   // the finger came back
        #expect(!rig.viewModel.willCancel)
        await rig.viewModel.micReleased()
        #expect(rig.sentVoice == 1 && rig.recorder.cancelled == 0)
    }

    @Test func slidingToTheRightIsIgnored() async {
        let rig = makeRig()
        await press(rig)
        rig.viewModel.micDragged(300)
        #expect(rig.viewModel.slideOffset == 0 && !rig.viewModel.willCancel)
        await rig.viewModel.micReleased()
    }

    @Test func theWordsChangeOnceLettingGoWouldCancel() async {
        let rig = makeRig()
        await press(rig)
        let before = rig.viewModel.slideHint
        rig.viewModel.micDragged(-(ConversationViewModel.slideToCancelDistance + 1))
        #expect(rig.viewModel.slideHint != before && !rig.viewModel.slideHint.isEmpty)
        await rig.viewModel.micReleased()
    }

    @Test func aTapIsNotAVoiceNote() async {
        let rig = makeRig(seconds: 0)
        await press(rig)
        await rig.viewModel.micReleased()
        #expect(rig.sentVoice == 0 && rig.recorder.cancelled == 1)   // the file is deleted
        #expect(rig.viewModel.notice != nil && !rig.viewModel.isRecording)
    }

    // MARK: Cannot record

    @Test func noMicrophoneAccessSaysSoAndNothingIsHeld() async {
        let rig = makeRig(failToStart: true)
        await press(rig)
        #expect(!rig.viewModel.isRecording && !rig.viewModel.isHolding && rig.viewModel.notice != nil)
        await rig.viewModel.micReleased()
        #expect(rig.sentVoice == 0)
    }

    @Test func offlineOrMutedPeopleCannotHold() async {
        let offline = makeRig(offline: true)
        offline.viewModel.micPressed()
        #expect(!offline.viewModel.isHolding && offline.recorder.started == 0)

        let muted = ControlledChat(base: StubChatRepository(store: SocialStubStore(mutedIn: [kit.crew])))
        let recorder = FakeRecorder()
        let viewModel = kit.makeViewModel(chat: muted, recorder: recorder)
        let task = await kit.open(viewModel)
        viewModel.micPressed()
        #expect(!viewModel.isHolding && recorder.started == 0)
        task.cancel()
    }

    // MARK: The 2 minute cap

    @Test func theRecordingStopsAndSendsByItselfAtTwoMinutes() async {
        let rig = makeRig(seconds: 120)
        await press(rig)
        await waitUntil { rig.gate.asked != nil }
        #expect(rig.gate.asked == .seconds(120))
        #expect(rig.sentVoice == 0 && rig.viewModel.isRecording)
        rig.gate.open()
        await waitUntil { !rig.viewModel.isRecording }
        await waitUntil { rig.sentVoice == 1 }
        #expect(rig.sentVoice == 1 && !rig.viewModel.isHolding)
        #expect(rig.chat.sent.withLock { $0.last?.1 } == .voice(path: "voice/test-note.m4a", seconds: 120))
        #expect(rig.viewModel.notice != nil)   // says voice notes can be up to 2 minutes
        await rig.viewModel.micReleased()      // the finger lets go later: nothing more happens
        #expect(rig.sentVoice == 1 && rig.recorder.started == 1)
    }

    @Test func finishingBeforeTheCapStopsTheCapClock() async {
        let rig = makeRig()
        await press(rig)
        await waitUntil { rig.gate.asked != nil }
        await rig.viewModel.micReleased()
        rig.gate.open()
        try? await Task.sleep(for: .milliseconds(100))
        #expect(rig.sentVoice == 1 && rig.viewModel.notice == nil)
    }

    // MARK: VoiceOver and leaving

    @Test func voiceOverStartsWithOneActivationAndSendsWithTheNext() async {
        let rig = makeRig()
        await rig.viewModel.micTapped()
        #expect(rig.viewModel.isRecording && !rig.viewModel.isHolding && rig.recorder.started == 1)
        #expect(rig.viewModel.micControlLabel == rig.viewModel.finishLabel)
        await rig.viewModel.micTapped()
        #expect(!rig.viewModel.isRecording && rig.sentVoice == 1)
        #expect(rig.viewModel.micControlLabel == rig.viewModel.micLabel)
    }

    @Test func voiceOverCanDiscardARecordingItStarted() async {
        let rig = makeRig()
        await rig.viewModel.micTapped()
        await rig.viewModel.cancelRecording()
        #expect(!rig.viewModel.isRecording && rig.recorder.cancelled == 1 && rig.sentVoice == 0)
    }

    @Test func aFingerCanTakeOverARecordingVoiceOverStarted() async {
        let rig = makeRig()
        await rig.viewModel.micTapped()
        rig.viewModel.micPressed()
        #expect(rig.viewModel.isHolding && rig.recorder.started == 1)
        await rig.viewModel.micReleased()
        #expect(rig.sentVoice == 1 && !rig.viewModel.isRecording)
    }

    @Test func leavingTheScreenDiscardsAnUnfinishedRecording() async {
        let rig = makeRig()
        await press(rig)
        await rig.viewModel.screenDisappeared()
        #expect(!rig.viewModel.isRecording && !rig.viewModel.isHolding)
        #expect(rig.recorder.cancelled == 1 && rig.sentVoice == 0)
    }
}
