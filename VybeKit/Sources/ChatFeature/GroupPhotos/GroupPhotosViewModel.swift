import Core
import Foundation
import Models

/// The view-ready values of the Group photos screen: every photo sent in the group, newest first.
struct GroupPhotosContent: Equatable, Sendable {
    let photos: [ViewerPhoto]
}

/// Group photos (CH8): the pictures people sent in one group, as a grid. Messages that were deleted and messages from
/// people I blocked are left out. Tapping a picture opens the shared full-screen viewer on it.
@MainActor @Observable
final class GroupPhotosViewModel {
    private(set) var state: LoadState<GroupPhotosContent> = .loading
    /// The full-screen photo viewer, when a photo is open.
    var viewer: PhotoViewerItem?

    private let conversationID: ConversationID
    private let chat: any ChatRepository
    private let photoStore: any PhotoStore
    private let session: SessionStore

    /// Cheap: no loading here (ADR 005). Takes only what the screen needs, never `AppDependencies`.
    init(conversationID: ConversationID, chat: any ChatRepository, photos: any PhotoStore, session: SessionStore) {
        self.conversationID = conversationID
        self.chat = chat
        self.photoStore = photos
        self.session = session
    }

    var title: String { String(localized: "chat.groupPhotos.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "chat.groupPhotos.empty", bundle: #bundle) }

    /// Called by `.task`. Reads the messages and then listens for new ones until the screen goes away: cancelling the
    /// task (leaving the screen) ends the loop, and that is not an error (ADR 005).
    func run() async {
        do {
            for try await batch in chat.messages(in: conversationID) {
                publish(batch)
            }
        } catch is CancellationError {
            return
        } catch {
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a broken stream keeps the photos on screen
            } else {
                state = .failed(AppError(error))   // only a first load can fail
            }
        }
    }

    /// The Retry button.
    func retry() async {
        state = .loading
        await run()
    }

    /// Opens the full-screen viewer on one picture, with all of them to swipe between.
    func photoTapped(_ id: String) {
        guard case .loaded(let content, _) = state,
              let index = content.photos.firstIndex(where: { $0.id == id }) else { return }
        viewer = PhotoViewerItem(
            ids: content.photos.map(\.id), urls: content.photos.map(\.url), startIndex: index)
    }

    /// Newest message first; the pictures of one message keep their order.
    private func publish(_ messages: [Message]) {
        let newestFirst = messages.sorted { $0.createdAt > $1.createdAt }
        var ids: [String] = []
        var urls: [URL?] = []
        for message in newestFirst where message.deletedAt == nil && !session.isBlocked(message.senderID) {
            guard case .photos(let pictures) = message.payload else { continue }
            for (index, picture) in pictures.enumerated() {
                ids.append("\(message.id.rawValue)-\(index)")
                urls.append(photoStore.url(for: picture))
            }
        }
        guard !ids.isEmpty else {
            state = .empty
            return
        }
        // The viewer item words each picture's label ("Photo 2 of 5"); the grid reuses them.
        let labelled = PhotoViewerItem(ids: ids, urls: urls, startIndex: 0).photos
        var stale = false
        if case .loaded(_, let wasStale) = state { stale = wasStale }
        state = .loaded(GroupPhotosContent(photos: labelled), isStale: stale)
    }
}
