import Components
import Core
import Foundation
import Models

extension ConversationViewModel {
    // MARK: Photos

    /// Two photos in one message at most.
    static let photoLimit = 2

    var photosLabel: String { String(localized: "chat.conversation.photos", bundle: #bundle) }
    var photoFailedNotice: String { String(localized: "chat.conversation.photoFailed", bundle: #bundle) }

    /// The Photos item in the + menu. Off offline, while muted or read-only, while recording, and while one is sending.
    var canAddPhotos: Bool { canWrite && !isRecording && !isSendingPhotos }

    /// The pictures the person picked, as bytes. Each one goes through `PhotoProcessor` first (resized, and the
    /// location and every other detail removed: docs/RISKS.md 3), is saved, and then all of them are sent as one
    /// message.
    /// If any step fails a message says so and nothing is sent.
    func photosPicked(_ pictures: [Data]) async {
        guard canAddPhotos, !pictures.isEmpty else { return }
        isSendingPhotos = true
        defer { isSendingPhotos = false }
        var saved: [Photo] = []
        do {
            for data in pictures.prefix(Self.photoLimit) {
                let safe = try await processor.process(data)
                saved.append(try await photoStore.save(safe))
            }
        } catch is CancellationError {
            return
        } catch {
            notice = photoFailedNotice
            return
        }
        do {
            _ = try await chat.send(.photos(saved), in: conversationID)
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    /// The picker could not hand over a picture.
    func photoLoadFailed() { notice = photoFailedNotice }

    /// Opens the full-screen viewer on one picture of a message.
    func photoTapped(_ rowID: String, at index: Int) {
        guard let message = message(rowID), case .photos(let photos) = message.payload,
              photos.indices.contains(index) else { return }
        viewer = PhotoViewerItem(
            ids: photos.map { $0.id.rawValue }, urls: photos.map { photoStore.url(for: $0) }, startIndex: index)
    }
}
