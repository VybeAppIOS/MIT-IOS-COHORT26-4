import Components
import Core
import Design
import Foundation
import Models

extension ConversationViewModel {
    // MARK: Voice notes

    func micTapped() async {
        guard canWrite else { return }
        if isRecording {
            await finishRecording()
        } else {
            do {
                try await recorder.start()
                isRecording = true
            } catch is CancellationError {
                return
            } catch {
                notice = String(localized: "chat.conversation.micFailed", bundle: #bundle)   // no permission, or busy
            }
        }
    }

    func cancelRecording() async {
        guard isRecording else { return }
        isRecording = false
        await recorder.cancel()
    }

    private func finishRecording() async {
        isRecording = false
        do {
            let note = try await recorder.stop()
            if note.hitLimit { notice = String(localized: "chat.conversation.voiceLimit", bundle: #bundle) }
            let path = "voice/\(note.url.lastPathComponent)"
            _ = try await chat.send(.voice(path: path, seconds: note.seconds), in: conversationID)
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
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
