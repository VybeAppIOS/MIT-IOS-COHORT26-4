import Components
import Core
import Design
import Foundation
import Models

extension ConversationViewModel {
    // MARK: Edit, delete, copy, report

    func message(_ rowID: String) -> Message? { messages.first { $0.id.rawValue == rowID } }

    /// You can edit and delete your own text messages.
    func canEdit(_ rowID: String) -> Bool {
        guard let message = message(rowID), message.deletedAt == nil, case .text = message.payload else { return false }
        return message.senderID == session.currentUser?.id && !network.isOffline
    }

    func canDelete(_ rowID: String) -> Bool {
        guard let message = message(rowID), message.deletedAt == nil else { return false }
        return message.senderID == session.currentUser?.id && !network.isOffline
    }

    func copyText(_ rowID: String) -> String? {
        guard let message = message(rowID), message.deletedAt == nil, case .text(let text) = message.payload else {
            return nil
        }
        return text
    }

    func editTapped(_ rowID: String) {
        guard canEdit(rowID), let message = message(rowID), case .text(let text) = message.payload else { return }
        editingID = message.id
        draft = text
    }

    func cancelEdit() {
        editingID = nil
        draft = ""
    }

    func deleteTapped(_ rowID: String) { if canDelete(rowID) { deletingID = message(rowID)?.id } }
    func cancelDelete() { deletingID = nil }

    func confirmDelete() async {
        guard let id = deletingID else { return }
        deletingID = nil
        do {
            try await chat.delete(id)
        } catch is CancellationError {
            return
        } catch {
            notice = AppError(error).message
        }
    }

    /// Report pushes the shared Report screen on this tab.
    func reportTapped(_ rowID: String) {
        guard let message = message(rowID), message.senderID != session.currentUser?.id else { return }
        router.open(.report(.message(message.id)))
    }
}
