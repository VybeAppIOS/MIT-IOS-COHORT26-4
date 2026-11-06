import Components
import Core
import Design
import Foundation
import Models

extension ConversationViewModel {
    // MARK: Words

    var placeholder: String { String(localized: "chat.conversation.placeholder", bundle: #bundle) }
    var sendLabel: String { String(localized: "chat.conversation.send", bundle: #bundle) }
    var saveEditLabel: String { String(localized: "chat.conversation.saveEdit", bundle: #bundle) }
    var editingText: String { String(localized: "chat.conversation.editing", bundle: #bundle) }
    var cancelEditLabel: String { String(localized: "chat.conversation.cancelEdit", bundle: #bundle) }
    var plusLabel: String { String(localized: "chat.conversation.plus", bundle: #bundle) }
    var hangoutLabel: String { String(localized: "chat.conversation.hangout", bundle: #bundle) }
    var pollLabel: String { String(localized: "chat.conversation.poll", bundle: #bundle) }
    var micLabel: String { String(localized: "chat.conversation.mic", bundle: #bundle) }
    var finishLabel: String { String(localized: "chat.conversation.finishRecording", bundle: #bundle) }
    var cancelRecordingLabel: String { String(localized: "chat.conversation.cancelRecording", bundle: #bundle) }
    var recordingText: String { String(localized: "chat.conversation.recording", bundle: #bundle) }
    var editMenuLabel: String { String(localized: "chat.conversation.edit", bundle: #bundle) }
    var deleteLabel: String { String(localized: "chat.conversation.delete", bundle: #bundle) }
    var deleteTitle: String { String(localized: "chat.conversation.deleteTitle", bundle: #bundle) }
    var copyLabel: String { String(localized: "chat.conversation.copy", bundle: #bundle) }
    var reportLabel: String { String(localized: "chat.conversation.report", bundle: #bundle) }
    var linkNote: String { String(localized: "chat.conversation.linkNote", bundle: #bundle) }
    var readOnlyNote: String { String(localized: "chat.conversation.readOnly", bundle: #bundle) }
    var mutedNote: String { String(localized: "chat.conversation.muted", bundle: #bundle) }
    var offlineNote: String { String(localized: "chat.conversation.offline", bundle: #bundle) }
    var savedTitle: String { String(localized: "chat.conversation.savedTitle", bundle: #bundle) }
    var savedEmpty: String { String(localized: "chat.conversation.savedEmpty", bundle: #bundle) }
    var cancelLabel: String { String(localized: "chat.conversation.cancel", bundle: #bundle) }
    var emptyMessage: String { String(localized: "chat.conversation.empty", bundle: #bundle) }
    var infoLabel: String { String(localized: "chat.conversation.info", bundle: #bundle) }
    var okLabel: String { String(localized: "chat.conversation.ok", bundle: #bundle) }

    var isOffline: Bool { network.isOffline }

    /// Whether the composer works: not offline, not a group that has shrunk below 3 people, and not muted.
    var canWrite: Bool {
        guard !network.isOffline else { return false }
        if case .loaded(let content, _) = state { return !content.isReadOnly && !content.isMuted }
        return true
    }

    var canSendDraft: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && canWrite && !isSending && !isRecording
    }

    /// A poll can only be started in a group chat.
    var canStartPoll: Bool {
        if case .loaded(let content, _) = state { return content.isGroup }
        return false
    }
}
