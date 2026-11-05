import Components
import Core
import Design
import Foundation
import Models

extension ConversationViewModel {
    // MARK: Voice notes (hold to record, slide left to cancel, 2 minute cap)

    /// How far to slide to the left (in points) before letting go cancels the recording.
    static let slideToCancelDistance = 80.0
    /// A recording shorter than this is thrown away: it was a tap, not a voice note.
    static let shortestVoiceSeconds = 1

    /// True while the slide is far enough that letting go cancels.
    var willCancel: Bool { slideOffset <= -Self.slideToCancelDistance }

    /// A finger went down on the microphone: start recording. Does nothing when the composer is off.
    func micPressed() {
        guard canWrite, !isHolding else { return }
        isHolding = true
        slideOffset = 0
        guard !isRecording else { return }   // VoiceOver already started it: the finger takes over
        startTask = Task { await beginRecording() }
    }

    /// The finger moved. `translation` is how far it moved sideways since it went down.
    func micDragged(_ translation: Double) {
        guard isHolding else { return }
        slideOffset = min(0, translation)
    }

    /// The finger lifted: send the voice note, or throw it away if it slid far enough to the left.
    func micReleased() async {
        guard isHolding else { return }
        await startTask?.value
        startTask = nil
        let cancelled = willCancel
        isHolding = false
        slideOffset = 0
        guard isRecording else { return }   // it never started, or the 2 minute cap already sent it
        if cancelled { await cancelRecording() } else { await finishRecording() }
    }

    /// The VoiceOver action (and the fallback for anyone who cannot hold): one activation starts, the next sends.
    func micTapped() async {
        guard canWrite, !isHolding else { return }
        if isRecording { await finishRecording() } else { await beginRecording() }
    }

    /// Throws the recording away (slide to cancel, or the Discard button).
    func cancelRecording() async {
        guard isRecording else { return }
        stopCap()
        resetHold()
        isRecording = false
        await recorder.cancel()
    }

    /// The screen is going away: an unfinished recording is discarded, never left running.
    func screenDisappeared() async { await cancelRecording() }

    private func beginRecording() async {
        do {
            try await recorder.start()
            isRecording = true
            startCap()
        } catch is CancellationError {
            resetHold()
        } catch {
            resetHold()
            notice = String(localized: "chat.conversation.micFailed", bundle: #bundle)   // no permission, or busy
        }
    }

    private func finishRecording(capped: Bool = false) async {
        guard isRecording else { return }
        // The cap clock calls this itself: cancelling it here would cancel the very task that is sending the note.
        if capped { capTask = nil } else { stopCap() }
        resetHold()
        isRecording = false
        do {
            let note = try await recorder.stop()
            guard note.seconds >= Self.shortestVoiceSeconds else {
                await recorder.cancel()   // a tap, not a voice note: delete the file and explain
                notice = String(localized: "chat.conversation.holdToRecord", bundle: #bundle)
                return
            }
            if capped || note.hitLimit { notice = String(localized: "chat.conversation.voiceLimit", bundle: #bundle) }
            let path = "voice/\(note.url.lastPathComponent)"
            _ = try await chat.send(.voice(path: path, seconds: note.seconds), in: conversationID)
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    private func resetHold() {
        isHolding = false
        slideOffset = 0
    }

    /// Stops the recording by itself after the cap and sends what was recorded.
    private func startCap() {
        capTask?.cancel()
        let (limit, wait) = (AudioRecorder.maximumDuration, sleep)
        capTask = Task { [weak self] in
            guard (try? await wait(limit)) != nil else { return }
            await self?.finishRecording(capped: true)
        }
    }

    private func stopCap() {
        capTask?.cancel()
        capTask = nil
    }

    /// Plays or pauses a voice note. A note that cannot be found says so.
    func togglePlayback(_ rowID: String) {
        guard let message = message(rowID), case .voice(let path, _) = message.payload else { return }
        if playingID == message.id, player.isLoaded {
            player.toggle()
        } else {
            do {
                try player.load(url: URL.temporaryDirectory.appending(path: path))
                playingID = message.id
                player.play()
            } catch {
                notice = String(localized: "chat.conversation.playFailed", bundle: #bundle)
            }
        }
        publish()
    }
}
